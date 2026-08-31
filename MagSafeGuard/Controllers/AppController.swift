//
//  AppController.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Central coordinator for the MagSafe Guard application that manages
//  state, coordinates services, and handles the grace period timer.
//

import AppKit
import Combine
import Foundation
import MagSafeGuardCore

/// Application states representing the security system's current mode.
///
/// The state machine flows: disarmed → armed → gracePeriod → triggered
/// with the ability to return to disarmed from any state via authentication.
public enum AppState: String {
  /// System is not monitoring power disconnection
  case disarmed = "disarmed"
  /// System is actively monitoring for power disconnection
  case armed = "armed"
  /// Grace period is active, user can cancel security actions
  case gracePeriod = "grace_period"
  /// Security actions have been executed
  case triggered = "triggered"
}

/// Events that can occur throughout the application lifecycle.
///
/// These events are logged for audit trails and can trigger state changes
/// or notifications based on the current configuration.
public enum AppEvent: String {
  /// System was armed successfully
  case armed
  /// System was disarmed successfully
  case disarmed
  /// Power adapter was disconnected while armed
  case powerDisconnected
  /// Power adapter was reconnected
  case powerConnected
  /// Grace period countdown began
  case gracePeriodStarted
  /// Grace period was cancelled by user authentication
  case gracePeriodCancelled
  /// Security action was executed (lock, shutdown, etc.)
  case securityActionExecuted
  /// User authentication failed during arm/disarm/cancel
  case authenticationFailed
  /// User authentication succeeded
  case authenticationSucceeded
  /// Application is terminating
  case applicationTerminating
  /// Auto-arm was triggered based on location or network
  case autoArmTriggered
  /// A network action completed successfully
  case networkActionExecuted
  /// A network action failed
  case networkActionFailed
}

/// Event log entry containing timestamped application events.
///
/// Used for audit trails, debugging, and user activity monitoring.
/// Events are automatically logged by the AppController during state changes.
public struct EventLogEntry {
  /// When the event occurred
  public let timestamp: Date
  /// Type of event that occurred
  public let event: AppEvent
  /// Optional additional details about the event
  public let details: String?
  /// Application state when event occurred
  public let state: AppState
}

/// Main application controller that coordinates all services and manages application state.
///
/// The AppController serves as the central coordinator for MagSafe Guard, managing:
/// - Application state transitions (disarmed ↔ armed ↔ grace period ↔ triggered)
/// - Power monitoring integration
/// - Authentication workflows
/// - Grace period timer management
/// - Event logging and audit trails
/// - Settings integration and real-time configuration updates
///
/// ## Usage
///
/// ```swift
/// let controller = AppController()
/// controller.arm { result in
///     switch result {
///     case .success:
///         Log.info("System armed successfully", category: .authentication)
///     case .failure(let error):
///         Log.error("Failed to arm", error, category: .authentication)
///     }
/// }
/// ```
///
/// ## State Management
///
/// The controller maintains a strict state machine:
/// - **Disarmed**: Default state, no monitoring active
/// - **Armed**: Power monitoring active, will trigger on disconnection
/// - **Grace Period**: Countdown active, user can authenticate to cancel
/// - **Triggered**: Security actions executed, requires manual reset
///
/// ## Thread Safety
///
/// All public methods are thread-safe and coordinate through the main queue
/// for UI updates and state changes.
public class AppController: ObservableObject {

  // MARK: - Published Properties

  /// Current application state.
  ///
  /// Published property that automatically notifies observers when the security
  /// system transitions between states. UI components can observe this property
  /// to update their appearance and behavior.
  @Published public private(set) var currentState: AppState = .disarmed

  /// Whether the grace period is currently active.
  ///
  /// Published property indicating if users can authenticate to cancel pending
  /// security actions. Used by UI to show grace period controls and countdown.
  @Published public private(set) var isInGracePeriod: Bool = false

  /// Remaining time in the grace period countdown.
  ///
  /// Updated approximately every 100ms during grace period to provide smooth
  /// countdown displays. Value is 0 when grace period is not active.
  @Published public private(set) var gracePeriodRemaining: TimeInterval = 0

  /// Last known power adapter connection state.
  ///
  /// Tracks the most recent power state for debugging and state management.
  /// Updated whenever power monitoring detects a state change.
  public private(set) var lastPowerState: PowerMonitorService.PowerState = .disconnected

  // MARK: - Services

  private let powerMonitor: PowerMonitorService
  private let authService: AuthenticationService
  private let securityActions: SecurityActionsService
  private let notificationService: NotificationService
  private var autoArmManager: AutoArmManager?

  // MARK: - Configuration

  private let settingsManager = UserDefaultsManager.shared

  /// Duration of grace period before security actions execute.
  ///
  /// Convenience property that provides direct access to the grace period
  /// setting with automatic persistence. Changes take effect immediately
  /// for new security events.
  public var gracePeriodDuration: TimeInterval {
    get { settingsManager.settings.gracePeriodDuration }
    set { settingsManager.updateSetting(\.gracePeriodDuration, value: newValue) }
  }

  /// Whether users can cancel security actions during grace period.
  ///
  /// Convenience property for accessing the grace period cancellation setting.
  /// When false, security actions execute automatically without user intervention.
  public var allowGracePeriodCancellation: Bool {
    get { settingsManager.settings.allowGracePeriodCancellation }
    set { settingsManager.updateSetting(\.allowGracePeriodCancellation, value: newValue) }
  }

  // MARK: - Private Properties

  private var gracePeriodTimer: Timer?
  private var gracePeriodStartTime: Date?
  private var cancellables = Set<AnyCancellable>()
  private var eventLog: [EventLogEntry] = []
  private let eventLogQueue = DispatchQueue(label: "com.magsafeguard.eventlog")
  #if DEBUG
  private var testGracePeriodDuration: TimeInterval?
  #endif

  /// Flag to disable auto-arm in test environments
  static var isTestEnvironment = false

  // MARK: - Constants

  private static var userCancelledMessage: String { L10n.tr("logDetail.userCancelled") }

  // MARK: - Callbacks

  /// Callback invoked when application state changes.
  ///
  /// Optional closure called whenever the application transitions between states.
  /// Receives the old state and new state for comparison and logging.
  public var onStateChange: ((AppState, AppState) -> Void)?

  /// Callback for notification requests.
  ///
  /// Optional closure called when the controller wants to display a notification.
  /// Receives title and message strings for the notification content.
  public var onNotification: ((String, String) -> Void)?

  // MARK: - Initialization

  /// Initialize the application controller with specified services.
  ///
  /// Creates a new controller instance with dependency injection support
  /// for testing. In production, use the default shared instances.
  ///
  /// - Parameters:
  ///   - powerMonitor: Service for monitoring power adapter state
  ///   - authService: Service for user authentication
  ///   - securityActions: Service for executing security actions
  ///   - notificationService: Service for displaying notifications
  public init(
    powerMonitor: PowerMonitorService = .shared,
    authService: AuthenticationService = .shared,
    securityActions: SecurityActionsService = .shared,
    notificationService: NotificationService = .shared
  ) {
    self.powerMonitor = powerMonitor
    self.authService = authService
    self.securityActions = securityActions
    self.notificationService = notificationService

    setupPowerMonitoring()
    loadConfiguration()
    setupNotificationHandling()
    setupAutoArm()
  }

  // MARK: - Public Methods

  /// Arms the system without authentication (auto-arm and trusted remote flows only).
  public func armAutomatically(details: String, completion: @escaping (Result<Void, Error>) -> Void) {
    guard currentState == .disarmed else {
      completion(
        .failure(AppControllerError.invalidState("Cannot arm from state: \(currentState)")))
      return
    }

    logEventInternal(.authenticationSucceeded, details: details)
    transitionToState(.armed)
    onNotification?(
      L10n.tr("notification.armed.title"), L10n.tr("notification.armed.message"))
    AccessibilityAnnouncement.announceStateChange(component: "MagSafe Guard", newState: "armed")
    completion(.success(()))
  }

  /// Arms the system with authentication
  public func arm(completion: @escaping (Result<Void, Error>) -> Void) {
    guard currentState == .disarmed else {
      completion(
        .failure(AppControllerError.invalidState("Cannot arm from state: \(currentState)")))
      return
    }

    // Require authentication
    authService.authenticate(reason: L10n.tr("auth.reason.arm")) { [weak self] result in
      guard let self = self else { return }

      switch result {
      case .success:
        self.logEventInternal(.authenticationSucceeded, details: L10n.tr("logDetail.armingSystem"))
        self.transitionToState(.armed)
        self.onNotification?(
          L10n.tr("notification.armed.title"), L10n.tr("notification.armed.message"))

        // Accessibility announcement
        AccessibilityAnnouncement.announceStateChange(component: "MagSafe Guard", newState: "armed")

        completion(.success(()))

      case .failure(let error):
        self.logEventInternal(.authenticationFailed, details: error.localizedDescription)

        // Accessibility announcement for errors
        AccessibilityAnnouncement.announceAlert(
          "Failed to arm system: \(error.localizedDescription)")

        completion(.failure(error))

      case .cancelled:
        self.logEventInternal(.authenticationFailed, details: AppController.userCancelledMessage)
        completion(.failure(AppControllerError.authenticationRequired))
      }
    }
  }

  /// Disarms the system with authentication
  public func disarm(completion: @escaping (Result<Void, Error>) -> Void) {
    guard currentState == .armed || currentState == .gracePeriod else {
      completion(
        .failure(AppControllerError.invalidState("Cannot disarm from state: \(currentState)")))
      return
    }

    // Cancel grace period if active
    if isInGracePeriod {
      cancelGracePeriod()
    }

    // Require authentication
    authService.authenticate(reason: L10n.tr("auth.reason.disarm")) { [weak self] result in
      guard let self = self else { return }

      switch result {
      case .success:
        self.logEventInternal(.authenticationSucceeded, details: L10n.tr("logDetail.disarmingSystem"))
        self.transitionToState(.disarmed)
        self.onNotification?(
          L10n.tr("notification.disarmed.title"), L10n.tr("notification.disarmed.message"))

        // Accessibility announcement
        AccessibilityAnnouncement.announceStateChange(
          component: "MagSafe Guard", newState: "disarmed")

        completion(.success(()))

      case .failure(let error):
        self.logEventInternal(.authenticationFailed, details: error.localizedDescription)
        completion(.failure(error))

      case .cancelled:
        self.logEventInternal(.authenticationFailed, details: AppController.userCancelledMessage)
        completion(.failure(AppControllerError.authenticationRequired))
      }
    }
  }

  /// Cancels grace period with authentication
  public func cancelGracePeriodWithAuth(completion: @escaping (Result<Void, Error>) -> Void) {
    guard isInGracePeriod && allowGracePeriodCancellation else {
      completion(.failure(AppControllerError.gracePeriodNotCancellable))
      return
    }

    authService.authenticate(reason: L10n.tr("auth.reason.cancelGrace")) { [weak self] result in
      guard let self = self else { return }

      switch result {
      case .success:
        self.logEventInternal(
          .authenticationSucceeded, details: L10n.tr("logDetail.cancellingGracePeriod"))
        self.cancelGracePeriod()
        self.transitionToState(.armed)
        self.onNotification?(
          L10n.tr("notification.graceCancelled.title"),
          L10n.tr("notification.graceCancelled.message"))
        completion(.success(()))

      case .failure(let error):
        self.logEventInternal(.authenticationFailed, details: error.localizedDescription)
        completion(.failure(error))

      case .cancelled:
        self.logEventInternal(.authenticationFailed, details: AppController.userCancelledMessage)
        completion(.failure(AppControllerError.authenticationRequired))
      }
    }
  }

  /// Gets recent event log entries
  public func getEventLog(limit: Int = 100) -> [EventLogEntry] {
    eventLogQueue.sync {
      Array(eventLog.suffix(limit))
    }
  }

  /// Clears the event log
  public func clearEventLog() {
    eventLogQueue.sync { [weak self] in
      self?.eventLog.removeAll()
    }
  }

  /// Logs an event (public for AppDelegate lifecycle)
  public func logEvent(_ event: AppEvent, details: String? = nil) {
    logEventInternal(event, details: details)
  }

  /// Runs security and network actions immediately (remote URL trigger).
  public func triggerRemoteSecurityResponse() {
    guard currentState == .armed || currentState == .gracePeriod else { return }
    logEventInternal(.securityActionExecuted, details: L10n.tr("logDetail.remoteTrigger"))
    executeSecurityActions(allowFromArmedState: currentState == .armed)
  }

  // MARK: - Auto-Arm Management

  /// Gets the auto-arm manager instance
  /// - Returns: The auto-arm manager if available
  public func getAutoArmManager() -> AutoArmManager? {
    return autoArmManager
  }

  /// Temporarily disables auto-arm for the specified duration
  /// - Parameter duration: How long to disable auto-arm (default: 1 hour)
  public func temporarilyDisableAutoArm(for duration: TimeInterval = 3600) {
    autoArmManager?.temporarilyDisable(for: duration)
  }

  /// Re-enables auto-arm if it was temporarily disabled
  public func cancelAutoArmDisable() {
    autoArmManager?.cancelTemporaryDisable()
  }

  /// Updates auto-arm settings and restarts monitoring if needed
  public func updateAutoArmSettings() {
    autoArmManager?.updateSettings()
  }

  // MARK: - Private Methods

  private func setupPowerMonitoring() {
    powerMonitor.startMonitoring { [weak self] powerInfo in
      guard let self = self else { return }

      self.lastPowerState = powerInfo.state

      // Only react to disconnection when armed
      if powerInfo.state == .disconnected && self.currentState == .armed {
        self.handlePowerDisconnected()
      } else if powerInfo.state == .connected {
        self.handlePowerConnected()
      }
    }
  }

  private func handlePowerConnected() {
    if currentState == .gracePeriod || isInGracePeriod {
      logEventInternal(.powerConnected, details: L10n.tr("logDetail.powerConnectedDuringGrace"))
      cancelGracePeriod()
      transitionToState(.armed)
    } else {
      logEventInternal(.powerConnected, details: L10n.tr("logDetail.powerConnected"))
    }
  }

  private var effectiveGracePeriodDuration: TimeInterval {
    #if DEBUG
    if Self.isTestEnvironment, let testGracePeriodDuration {
      return testGracePeriodDuration
    }
    #endif
    return gracePeriodDuration
  }

  private func handlePowerDisconnected() {
    logEventInternal(.powerDisconnected, details: L10n.tr("logDetail.powerDisconnected"))

    if effectiveGracePeriodDuration > 0 {
      startGracePeriod()
    } else {
      executeSecurityActions(allowFromArmedState: true)
    }
  }

  private func startGracePeriod() {
    transitionToState(.gracePeriod)
    isInGracePeriod = true
    gracePeriodStartTime = Date()
    gracePeriodRemaining = effectiveGracePeriodDuration

    logEventInternal(
      .gracePeriodStarted,
      details: L10n.tr("logDetail.gracePeriodStarted", Int(effectiveGracePeriodDuration)))
    notificationService.showCriticalAlert(
      title: L10n.tr("notification.graceAlert.title"),
      message: L10n.tr("notification.graceAlert.message", Int(effectiveGracePeriodDuration))
    )

    // Start countdown timer
    gracePeriodTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      guard let self = self else { return }

      let elapsed = Date().timeIntervalSince(self.gracePeriodStartTime ?? Date())
      self.gracePeriodRemaining = max(0, self.effectiveGracePeriodDuration - elapsed)

      if self.gracePeriodRemaining <= 0 {
        self.gracePeriodTimer?.invalidate()
        self.gracePeriodTimer = nil
        guard self.isInGracePeriod, self.currentState == .gracePeriod else { return }
        self.executeSecurityActions()
      }
    }
  }

  private func cancelGracePeriod() {
    gracePeriodTimer?.invalidate()
    gracePeriodTimer = nil
    isInGracePeriod = false
    gracePeriodRemaining = 0
    gracePeriodStartTime = nil

    logEventInternal(.gracePeriodCancelled, details: L10n.tr("logDetail.gracePeriodCancelled"))
  }

  private func executeSecurityActions(allowFromArmedState: Bool = false) {
    switch currentState {
    case .gracePeriod:
      guard isInGracePeriod else { return }
    case .armed:
      guard allowFromArmedState else { return }
    default:
      return
    }

    transitionToState(.triggered)
    cancelGracePeriod()

    logNetworkActionResults(
      NetworkActionsService.shared.executeActions(event: "security_trigger"))

    securityActions.executeActions { [weak self] result in
      guard let self = self else { return }

      if result.allSucceeded {
        self.logEventInternal(
          .securityActionExecuted, details: L10n.tr("logDetail.actionsAllSucceeded"))
        self.onNotification?(
          L10n.tr("notification.actionsExecuted.title"),
          L10n.tr("notification.actionsExecuted.message"))
      } else {
        let failedCount = result.failedActions.count
        self.logEventInternal(
          .securityActionExecuted, details: L10n.tr("logDetail.actionsFailed", failedCount))
        self.onNotification?(
          L10n.tr("notification.actionsPartial.title"),
          L10n.tr("notification.actionsPartial.message", failedCount))
      }

      // Return to armed state after execution
      self.transitionToState(.armed)
    }
  }

  private func transitionToState(_ newState: AppState) {
    let oldState = currentState
    currentState = newState

    // Log state changes
    switch newState {
    case .armed:
      logEventInternal(.armed, details: L10n.tr("logDetail.systemArmed"))
    case .disarmed:
      logEventInternal(.disarmed, details: L10n.tr("logDetail.systemDisarmed"))
    default:
      break
    }

    DispatchQueue.main.async { [weak self] in
      self?.onStateChange?(oldState, newState)
    }
  }

  private func logNetworkActionResults(_ result: NetworkActionResult) {
    for action in result.executed {
      logEventInternal(
        .networkActionExecuted,
        details: L10n.tr("logDetail.networkActionSucceeded", action.localizedLogName))
    }
    for (action, error) in result.failed {
      logEventInternal(
        .networkActionFailed,
        details: L10n.tr(
          "logDetail.networkActionFailed",
          action.localizedLogName,
          error.localizedDescription))
    }
  }

  private func logEventInternal(_ event: AppEvent, details: String? = nil) {
    eventLogQueue.async { [weak self] in
      guard let self = self else { return }

      let entry = EventLogEntry(
        timestamp: Date(),
        event: event,
        details: details,
        state: self.currentState
      )

      self.eventLog.append(entry)

      // Keep log size reasonable
      if self.eventLog.count > 1000 {
        self.eventLog.removeFirst(self.eventLog.count - 1000)
      }

      // Debug logging
      Log.debug(
        "Event: \(event.rawValue) | State: \(self.currentState.rawValue) | Details: \(details ?? "none")"
      )
    }
  }

  private func loadConfiguration() {
    // Configuration is now loaded from UserDefaultsManager
    // Subscribe to settings changes
    settingsManager.$settings
      .dropFirst()  // Skip the initial value to prevent immediate callback
      .sink { [weak self] _ in
        // Update auto-arm settings when configuration changes
        self?.autoArmManager?.updateSettings()
      }
      .store(in: &cancellables)
  }

  private func setupAutoArm() {
    // Skip auto-arm setup in test environment to avoid location permission issues
    guard !AppController.isTestEnvironment else { return }

    // Initialize auto-arm manager
    autoArmManager = AutoArmManager(appController: self)

    // Start monitoring if enabled in settings
    if settingsManager.settings.autoArmEnabled {
      autoArmManager?.startMonitoring()
    }
  }

  private func setupNotificationHandling() {
    // Replace the callback with direct notification service usage
    onNotification = { [weak self] title, message in
      self?.notificationService.showNotification(title: title, message: message)
    }

    // Listen for grace period cancellation from alert windows
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleGracePeriodCancellationRequest),
      name: Notification.Name("MagSafeGuard.CancelGracePeriod"),
      object: nil
    )
  }

  @objc private func handleGracePeriodCancellationRequest() {
    if isInGracePeriod {
      cancelGracePeriodWithAuth { _ in
        // Empty completion - errors are already logged internally by cancelGracePeriodWithAuth
        // and user notifications are shown. This is a fire-and-forget operation triggered
        // by the notification center, so no additional error handling is needed here.
      }
    }
  }
}

// MARK: - Errors

/// Errors that can occur during AppController operations.
///
/// Provides specific error types for different failure conditions
/// with localized error messages for user display.
public enum AppControllerError: LocalizedError {
  /// Operation cannot be performed in the current state
  case invalidState(String)
  /// Grace period cancellation is not allowed by configuration
  case gracePeriodNotCancellable
  /// User authentication is required for this operation
  case authenticationRequired

  /// Localized error description for user display.
  public var errorDescription: String? {
    switch self {
    case .invalidState(let message):
      return message
    case .gracePeriodNotCancellable:
      return L10n.tr("error.gracePeriodNotCancellable")
    case .authenticationRequired:
      return L10n.tr("error.authenticationRequired")
    }
  }
}

// MARK: - AppController Extension for Menu

extension AppController {
  /// Returns the appropriate menu title for arm/disarm action
  public var armDisarmMenuTitle: String {
    switch currentState {
    case .disarmed:
      return L10n.tr("menu.arm")
    case .armed, .gracePeriod, .triggered:
      return L10n.tr("menu.disarm")
    }
  }

  /// Returns the appropriate SF Symbol name for current state (fallback when assets are missing).
  public var statusIconName: String {
    switch currentState {
    case .disarmed:
      return "shield"
    case .armed:
      return "shield.fill"
    case .gracePeriod:
      return "exclamationmark.shield.fill"
    case .triggered:
      return "xmark.shield.fill"
    }
  }

  /// Asset catalog name for the menu bar icon matching the current state.
  public var statusMenuBarImageName: String {
    Self.menuBarImageName(for: currentState)
  }

  /// Maps application state to menu bar asset name.
  public static func menuBarImageName(for state: AppState) -> String {
    switch state {
    case .disarmed:
      return "MenuBarIconDisarmed"
    case .armed:
      return "MenuBarIconArmed"
    case .gracePeriod:
      return "MenuBarIconGracePeriod"
    case .triggered:
      return "MenuBarIconTriggered"
    }
  }

  /// Returns a human-readable status description
  public var statusDescription: String {
    switch currentState {
    case .disarmed:
      return L10n.tr("status.disarmed")
    case .armed:
      return L10n.tr("status.armed")
    case .gracePeriod:
      return L10n.tr("status.gracePeriod", Int(gracePeriodRemaining))
    case .triggered:
      return L10n.tr("status.triggered")
    }
  }
}

// MARK: - Testing Support

#if DEBUG
extension AppController {
  /// Enters grace period from armed state when running unit tests.
  func enterGracePeriodForTesting() {
    guard Self.isTestEnvironment else { return }
    guard currentState == .armed else { return }
    startGracePeriod()
  }

  /// Simulates power adapter disconnect while armed (unit tests only).
  func simulatePowerDisconnectForTesting() {
    guard Self.isTestEnvironment else { return }
    guard currentState == .armed else { return }
    lastPowerState = .disconnected
    handlePowerDisconnected()
  }

  /// Simulates power adapter reconnect (unit tests only).
  func simulatePowerConnectForTesting() {
    guard Self.isTestEnvironment else { return }
    lastPowerState = .connected
    handlePowerConnected()
  }

  /// Ends the grace period immediately and runs security actions (unit tests only).
  func expireGracePeriodForTesting() {
    guard Self.isTestEnvironment else { return }
    guard isInGracePeriod else { return }
    gracePeriodTimer?.invalidate()
    gracePeriodTimer = nil
    executeSecurityActions()
  }

  /// Simulates grace timer expiry after reconnect cancelled grace (unit tests only).
  func attemptGraceExpiryAfterCancelForTesting() {
    guard Self.isTestEnvironment else { return }
    gracePeriodRemaining = 0
    executeSecurityActions()
  }

  /// Overrides grace period duration without settings validation (unit tests only).
  func setGracePeriodDurationForTesting(_ duration: TimeInterval) {
    guard Self.isTestEnvironment else { return }
    testGracePeriodDuration = duration
  }
}
#endif
