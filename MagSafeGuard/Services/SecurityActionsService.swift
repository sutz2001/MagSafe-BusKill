//
//  SecurityActionsService.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  This service manages and executes security actions when power is disconnected
//  while the system is armed. It provides a configurable set of actions to protect
//  the device from unauthorized access.
//

import Foundation
import MagSafeGuardCore
import MagSafeGuardDomain

/// Service responsible for executing security actions when theft is detected.
///
/// SecurityActionsService orchestrates the execution of protective measures when
/// power disconnection indicates a potential theft attempt. It provides configurable
/// actions ranging from screen locking to system shutdown, with support for both
/// sequential and parallel execution modes.
///
/// ## Security Actions
///
/// - **Screen Lock**: Immediately lock the screen requiring authentication
/// - **Sound Alarm**: Play loud alarm to deter theft and alert nearby people
/// - **Force Logout**: Log out all users and lock the system
/// - **System Shutdown**: Shut down the computer after a configurable delay
/// - **Custom Script**: Execute user-defined shell scripts for custom actions
///
/// ## Configuration
///
/// Actions are fully configurable with support for:
/// - Individual action enable/disable
/// - Execution delays and timeouts
/// - Parallel vs sequential execution
/// - Custom script paths and parameters
///
/// ## Usage
///
/// ```swift
/// SecurityActionsService.shared.executeActions { result in
///     if result.allSucceeded {
///         Log.info("All security actions completed successfully")
///     } else {
///         Log.error("\(result.failedActions.count) actions failed")
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// All operations are thread-safe with atomic execution state tracking.
/// Completion handlers are called on the main queue for UI safety.
public class SecurityActionsService {

  // MARK: - Types

  /// Domain security action type (single source of truth).
  public typealias SecurityAction = SecurityActionType

  /// Configuration for security actions execution.
  ///
  /// Defines which actions are enabled and how they should be executed,
  /// including timing, volume, and execution order preferences.
  public struct Configuration: Codable {
    /// Set of enabled security actions to execute
    var enabledActions: Set<SecurityAction>
    /// User-defined execution order (Settings → Security drag order)
    var actionOrder: [SecurityAction]
    /// Delay in seconds before executing any actions
    var actionDelay: TimeInterval
    /// Alarm volume level (0.0 to 1.0)
    var alarmVolume: Float
    /// Raise macOS output volume to `alarmVolume` while the alarm plays
    var boostSystemVolumeForAlarm: Bool
    /// Alarm playback limit in seconds (3–30). `0` = until stopped manually.
    var alarmDurationSeconds: TimeInterval
    /// Delay in seconds before system shutdown
    var shutdownDelay: TimeInterval
    /// Path to custom script file (legacy single path)
    var customScriptPath: String?
    /// All custom script paths from Advanced settings
    var customScriptPaths: [String]
    /// Whether to execute actions in parallel or sequentially
    var executeInParallel: Bool

    static let defaultConfiguration = Configuration(
      enabledActions: [.lockScreen],
      actionOrder: [.lockScreen],
      actionDelay: 0,
      alarmVolume: 1.0,
      boostSystemVolumeForAlarm: true,
      alarmDurationSeconds: 15,
      shutdownDelay: 30,
      customScriptPath: nil,
      customScriptPaths: [],
      executeInParallel: false
    )

    enum CodingKeys: String, CodingKey {
      case enabledActions
      case actionOrder
      case actionDelay
      case alarmVolume
      case boostSystemVolumeForAlarm
      case alarmDurationSeconds
      case shutdownDelay
      case customScriptPath
      case customScriptPaths
      case executeInParallel
    }

    public init(
      enabledActions: Set<SecurityAction>,
      actionOrder: [SecurityAction],
      actionDelay: TimeInterval,
      alarmVolume: Float,
      boostSystemVolumeForAlarm: Bool,
      alarmDurationSeconds: TimeInterval,
      shutdownDelay: TimeInterval,
      customScriptPath: String?,
      customScriptPaths: [String],
      executeInParallel: Bool
    ) {
      self.enabledActions = enabledActions
      self.actionOrder = actionOrder
      self.actionDelay = actionDelay
      self.alarmVolume = alarmVolume
      self.boostSystemVolumeForAlarm = boostSystemVolumeForAlarm
      self.alarmDurationSeconds = alarmDurationSeconds
      self.shutdownDelay = shutdownDelay
      self.customScriptPath = customScriptPath
      self.customScriptPaths = customScriptPaths
      self.executeInParallel = executeInParallel
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      enabledActions = Self.decodeActionSet(from: container, key: .enabledActions)
      actionOrder = Self.decodeActionList(from: container, key: .actionOrder)
      actionDelay = try container.decode(TimeInterval.self, forKey: .actionDelay)
      alarmVolume = try container.decode(Float.self, forKey: .alarmVolume)
      boostSystemVolumeForAlarm =
        try container.decodeIfPresent(Bool.self, forKey: .boostSystemVolumeForAlarm) ?? true
      alarmDurationSeconds =
        try container.decodeIfPresent(TimeInterval.self, forKey: .alarmDurationSeconds) ?? 15
      shutdownDelay = try container.decode(TimeInterval.self, forKey: .shutdownDelay)
      customScriptPath = try container.decodeIfPresent(String.self, forKey: .customScriptPath)
      customScriptPaths =
        try container.decodeIfPresent([String].self, forKey: .customScriptPaths) ?? []
      executeInParallel = try container.decode(Bool.self, forKey: .executeInParallel)
    }

    private static func decodeActionSet(
      from container: KeyedDecodingContainer<CodingKeys>,
      key: CodingKeys
    ) -> Set<SecurityActionType> {
      if let rawValues = try? container.decode([String].self, forKey: key) {
        return Set(rawValues.compactMap(SecurityActionType.init(persistedRawValue:)))
      }
      if let actions = try? container.decode(Set<SecurityActionType>.self, forKey: key) {
        return actions
      }
      return []
    }

    private static func decodeActionList(
      from container: KeyedDecodingContainer<CodingKeys>,
      key: CodingKeys
    ) -> [SecurityActionType] {
      if let rawValues = try? container.decode([String].self, forKey: key) {
        return rawValues.compactMap(SecurityActionType.init(persistedRawValue:))
      }
      return (try? container.decode([SecurityActionType].self, forKey: key)) ?? []
    }
  }

  /// Result of executing security actions.
  ///
  /// Contains detailed information about which actions succeeded or failed,
  /// enabling proper error handling and user feedback.
  public struct ExecutionResult {
    /// Actions that executed successfully
    let executedActions: [SecurityAction]
    /// Actions that failed with their specific errors
    let failedActions: [(action: SecurityAction, error: Error)]
    /// When the execution started
    let timestamp: Date

    /// Whether all configured actions executed successfully.
    ///
    /// Returns true only if no actions failed. Use this for simple
    /// success/failure determination.
    var allSucceeded: Bool {
      return failedActions.isEmpty
    }
  }

  // MARK: - Properties

  /// Shared instance for singleton pattern.
  ///
  /// The shared instance provides global access to security actions functionality.
  /// All components should use this instance for consistent configuration.
  public static let shared = SecurityActionsService()

  /// Current security actions configuration.
  ///
  /// Contains the active settings for which actions are enabled and how
  /// they should be executed. Configuration is persisted automatically.
  private(set) public var configuration: Configuration

  /// System actions implementation
  private let systemActions: SystemActionsProtocol

  /// Flag to track if actions are currently executing
  private var isCurrentlyExecuting = false
  private var activeExecutionContext: SecurityActionExecutionContext = .standard
  private let executingLock = NSLock()

  /// Whether security actions are currently being executed.
  ///
  /// Thread-safe property that indicates if an execution is in progress.
  /// Used to prevent concurrent executions and provide status information.
  public var isExecuting: Bool {
    executingLock.lock()
    defer { executingLock.unlock() }
    return isCurrentlyExecuting
  }

  /// Serial queue for thread safety
  private let queue = DispatchQueue(label: "com.magsafeguard.securityactions", qos: .userInitiated)

  // MARK: - Rate Limiting

  /// Last execution timestamp for rate limiting
  private var lastExecutionTime: Date?

  /// Minimum time interval between executions (in seconds)
  private let minimumExecutionInterval: TimeInterval = 5.0

  /// Maximum number of executions within the time window
  private let maxExecutionsPerWindow = 10

  /// Time window for rate limiting (in seconds)
  private let rateLimitWindow: TimeInterval = 60.0

  /// Execution history for rate limiting
  private var executionHistory: [Date] = []

  /// Lock for thread-safe access to rate limiting properties
  private let rateLimitLock = NSLock()

  // MARK: - Circuit Breaker

  /// Circuit breaker state
  private enum CircuitBreakerState {
    case closed
    case open(until: Date)
    case halfOpen
  }

  /// Current circuit breaker state
  private var circuitBreakerState: CircuitBreakerState = .closed

  /// Number of consecutive failures
  private var consecutiveFailures = 0

  /// Maximum consecutive failures before opening circuit
  private let maxConsecutiveFailures = 3

  /// Time to keep circuit open (in seconds)
  private let circuitOpenDuration: TimeInterval = 60.0

  /// Lock for circuit breaker state
  private let circuitBreakerLock = NSLock()

  #if DEBUG
  private var testMinimumExecutionInterval: TimeInterval?
  private var testMaxExecutionsPerWindow: Int?
  private var testRateLimitWindow: TimeInterval?
  private var testMaxConsecutiveFailures: Int?
  private var testCircuitOpenDuration: TimeInterval?
  #endif

  // MARK: - Initialization

  private init() {
    self.configuration = Configuration.defaultConfiguration
    self.systemActions = MacSystemActions()
    loadConfiguration()
  }

  /// Initialize with custom system actions (for testing)
  internal init(systemActions: SystemActionsProtocol) {
    self.configuration = Configuration.defaultConfiguration
    self.systemActions = systemActions
    loadConfiguration()
  }

  /// Reset configuration to default (for testing)
  internal func resetToDefault() {
    queue.sync {
      self.configuration = Configuration.defaultConfiguration
      UserDefaults.standard.removeObject(forKey: "SecurityActionsConfiguration")
    }
  }

  // MARK: - Public Methods

  /// Execute all enabled security actions.
  ///
  /// Initiates execution of all configured security actions according to
  /// the current configuration. Actions are executed either sequentially
  /// or in parallel based on configuration settings.
  ///
  /// The execution includes:
  /// - Pre-execution delay if configured
  /// - Action prioritization (screen lock first)
  /// - Error handling and result collection
  /// - Thread-safe execution state management
  ///
  /// - Parameter completion: Result handler called on main queue
  ///
  /// - Note: Only one execution can be active at a time. Subsequent
  ///   calls while executing are ignored to prevent conflicts.
  public func executeActions(
    context: SecurityActionExecutionContext = .standard,
    completion: @escaping (ExecutionResult) -> Void
  ) {
    if context == .standard {
      if let circuitError = checkCircuitBreaker() {
        Log.warning("Circuit breaker open: \(circuitError)", category: .security)
        DispatchQueue.main.async {
          completion(ExecutionResult(
            executedActions: [],
            failedActions: [(SecurityActionType.lockScreen, circuitError)],
            timestamp: Date()
          ))
        }
        return
      }

      if !checkRateLimit() {
        Log.warning("Rate limit exceeded for security actions", category: .security)
        DispatchQueue.main.async {
          completion(ExecutionResult(
            executedActions: [],
            failedActions: [(SecurityActionType.lockScreen, SecurityActionError.rateLimitExceeded)],
            timestamp: Date()
          ))
        }
        return
      }
    }

    guard trySetExecuting() else {
      Log.warning("Actions already executing, ignoring request", category: .security)
      return
    }

    queue.async { [weak self] in
      guard let self = self else { return }
      self.activeExecutionContext = context
      self.performExecution(completion: completion)
    }
  }

  // MARK: - Rate Limiting Methods

  /// Check if execution is allowed based on rate limiting rules
  private func checkRateLimit() -> Bool {
    rateLimitLock.lock()
    defer { rateLimitLock.unlock() }

    let now = Date()

    // Check minimum interval between executions
    if let lastExecution = lastExecutionTime {
      let timeSinceLastExecution = now.timeIntervalSince(lastExecution)
      if timeSinceLastExecution < effectiveMinimumExecutionInterval {
        Log.warning("Execution denied: minimum interval not met (\(timeSinceLastExecution)s < \(effectiveMinimumExecutionInterval)s)", category: .security)
        return false
      }
    }

    // Clean up old execution history
    executionHistory = executionHistory.filter { execution in
      now.timeIntervalSince(execution) <= effectiveRateLimitWindow
    }

    // Check if we've exceeded the rate limit
    if executionHistory.count >= effectiveMaxExecutionsPerWindow {
      Log.warning("Execution denied: rate limit exceeded (\(executionHistory.count) executions in \(effectiveRateLimitWindow)s)", category: .security)
      return false
    }

    // Record this execution
    lastExecutionTime = now
    executionHistory.append(now)

    return true
  }

  // MARK: - Circuit Breaker Methods

  /// Check if circuit breaker allows execution
  private func checkCircuitBreaker() -> SecurityActionError? {
    circuitBreakerLock.lock()
    defer { circuitBreakerLock.unlock() }

    switch circuitBreakerState {
    case .closed:
      return nil

    case .open(let until):
      if Date() >= until {
        // Try to move to half-open state
        circuitBreakerState = .halfOpen
        Log.info("Circuit breaker moved to half-open state", category: .security)
        return nil
      } else {
        return .systemError(description: "Circuit breaker is open. Too many consecutive failures.")
      }

    case .halfOpen:
      // Allow one attempt in half-open state
      return nil
    }
  }

  /// Record execution success
  private func recordSuccess() {
    circuitBreakerLock.lock()
    defer { circuitBreakerLock.unlock() }

    consecutiveFailures = 0

    // If in half-open state, close the circuit
    if case .halfOpen = circuitBreakerState {
      circuitBreakerState = .closed
      Log.info("Circuit breaker closed after successful execution", category: .security)
    }
  }

  /// Record execution failure
  private func recordFailure() {
    circuitBreakerLock.lock()
    defer { circuitBreakerLock.unlock() }

    consecutiveFailures += 1

    // Check if we should open the circuit
    if consecutiveFailures >= effectiveMaxConsecutiveFailures {
      let reopenTime = Date().addingTimeInterval(effectiveCircuitOpenDuration)
      circuitBreakerState = .open(until: reopenTime)
      Log.error("Circuit breaker opened due to \(consecutiveFailures) consecutive failures", category: .security)
    }

    // If in half-open state, reopen the circuit
    if case .halfOpen = circuitBreakerState {
      let reopenTime = Date().addingTimeInterval(effectiveCircuitOpenDuration)
      circuitBreakerState = .open(until: reopenTime)
      Log.error("Circuit breaker reopened after failure in half-open state", category: .security)
    }
  }

  // MARK: - Execution Helper Methods

  /// Try to set the executing flag atomically
  /// - Returns: true if successfully set, false if already executing
  private func trySetExecuting() -> Bool {
    executingLock.lock()
    defer { executingLock.unlock() }

    if isCurrentlyExecuting {
      return false
    }
    isCurrentlyExecuting = true
    return true
  }

  /// Clear the executing flag
  private func clearExecuting() {
    executingLock.lock()
    defer { executingLock.unlock() }
    isCurrentlyExecuting = false
  }

  /// Perform the actual execution of actions
  private func performExecution(completion: @escaping (ExecutionResult) -> Void) {
    let startTime = Date()
    let context = activeExecutionContext

    if context == .standard {
      applyActionDelay()
    }

    let (executedActions, failedActions): ([SecurityAction], [(SecurityAction, Error)])
    switch context {
    case .standard:
      (executedActions, failedActions) = executeEnabledActions()
    case .theftTrigger, .panic:
      (executedActions, failedActions) = executeProtectionFirstActions(context: context)
    }

    clearExecuting()
    activeExecutionContext = .standard

    let result = ExecutionResult(
      executedActions: executedActions,
      failedActions: failedActions,
      timestamp: startTime
    )

    // Update circuit breaker based on result
    if result.allSucceeded {
      recordSuccess()
    } else {
      recordFailure()
    }

    DispatchQueue.main.async {
      completion(result)
    }
  }

  /// Protection-first ordering for theft and panic triggers: lock, logout, immediate shutdown.
  private func executeProtectionFirstActions(
    context: SecurityActionExecutionContext
  ) -> ([SecurityAction], [(SecurityAction, Error)]) {
    let enabled = getSortedActions()
    var executed: [SecurityAction] = []
    var failed: [(SecurityAction, Error)] = []

    runProtectionAction(.lockScreen, enabled: enabled, executed: &executed, failed: &failed) {
      try self.executeAction(.lockScreen)
    }

    if enabled.contains(.soundAlarm) {
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        try? self?.executeAction(.soundAlarm)
      }
      executed.append(.soundAlarm)
    }

    runProtectionAction(.forceLogout, enabled: enabled, executed: &executed, failed: &failed) {
      try self.executeAction(.forceLogout)
    }

    if context == .panic || enabled.contains(.shutdown) {
      do {
        try systemActions.executeImmediateShutdown()
        executed.append(.shutdown)
      } catch {
        failed.append((.shutdown, error))
        Log.error("Failed to execute shutdown", error: error, category: .security)
      }
    }

    return (executed, failed)
  }

  /// Phase B: run custom scripts within a time budget before logout/shutdown.
  @discardableResult
  public func executeScriptsPhase(timeBudget: TimeInterval) -> ExecutionResult {
    guard timeBudget > 0 else {
      return ExecutionResult(executedActions: [], failedActions: [], timestamp: Date())
    }

    guard configuration.enabledActions.contains(.customScript) else {
      return ExecutionResult(executedActions: [], failedActions: [], timestamp: Date())
    }

    let paths =
      configuration.customScriptPaths.isEmpty
      ? (configuration.customScriptPath.map { [$0] } ?? [])
      : configuration.customScriptPaths

    guard !paths.isEmpty else {
      return ExecutionResult(executedActions: [], failedActions: [], timestamp: Date())
    }

    let deadline = Date().addingTimeInterval(timeBudget)
    var executed: [SecurityAction] = []
    var failed: [(SecurityAction, Error)] = []

    for path in paths {
      let remaining = deadline.timeIntervalSinceNow
      guard remaining > 0 else {
        failed.append((.customScript, SystemActionError.scriptExecutionTimeout))
        Log.warning("Script phase budget exhausted — skipping remaining scripts", category: .security)
        break
      }

      do {
        try systemActions.executeScript(at: path, timeLimit: remaining)
        executed.append(.customScript)
      } catch {
        failed.append((.customScript, error))
        Log.error("Failed to execute custom script", error: error, category: .security)
      }
    }

    return ExecutionResult(executedActions: executed, failedActions: failed, timestamp: Date())
  }

  private func runProtectionAction(
    _ action: SecurityAction,
    enabled: [SecurityAction],
    executed: inout [SecurityAction],
    failed: inout [(SecurityAction, Error)],
    perform: () throws -> Void
  ) {
    guard enabled.contains(action) else { return }
    do {
      try perform()
      executed.append(action)
    } catch {
      failed.append((action, error))
      Log.error("Failed to execute \(action)", error: error, category: .security)
    }
  }

  /// Apply configured delay before executing actions
  private func applyActionDelay() {
    if configuration.actionDelay > 0 {
      Log.info(
        "Waiting \(configuration.actionDelay)s before executing actions", category: .security)
      Thread.sleep(forTimeInterval: configuration.actionDelay)
    }
  }

  /// Execute all enabled actions and return results
  /// - Returns: Tuple of (executed actions, failed actions with errors)
  private func executeEnabledActions() -> ([SecurityAction], [(SecurityAction, Error)]) {
    let sortedActions = getSortedActions()

    if configuration.executeInParallel {
      return executeActionsInParallel(sortedActions)
    } else {
      return executeActionsSequentially(sortedActions)
    }
  }

  /// Get enabled actions in configured order
  private func getSortedActions() -> [SecurityAction] {
    if !configuration.actionOrder.isEmpty {
      return configuration.actionOrder.filter { configuration.enabledActions.contains($0) }
    }
    return configuration.enabledActions.sorted { $0.rawValue < $1.rawValue }
  }

  /// Execute actions in parallel
  private func executeActionsInParallel(
    _ actions: [SecurityAction]
  ) -> ([SecurityAction], [(SecurityAction, Error)]) {
    var executedActions: [SecurityAction] = []
    var failedActions: [(SecurityAction, Error)] = []
    let group = DispatchGroup()
    let resultsQueue = DispatchQueue(label: "com.magsafeguard.results")

    for action in actions {
      group.enter()
      queue.async {
        self.executeActionWithResult(
          action,
          resultsQueue: resultsQueue,
          executedActions: &executedActions,
          failedActions: &failedActions
        )
        group.leave()
      }
    }

    group.wait()
    return (executedActions, failedActions)
  }

  /// Execute actions sequentially
  private func executeActionsSequentially(
    _ actions: [SecurityAction]
  ) -> ([SecurityAction], [(SecurityAction, Error)]) {
    var executedActions: [SecurityAction] = []
    var failedActions: [(SecurityAction, Error)] = []

    for action in actions {
      do {
        try executeAction(action)
        executedActions.append(action)
      } catch {
        failedActions.append((action, error))
        Log.error("Failed to execute \(action)", error: error, category: .security)
      }
    }

    return (executedActions, failedActions)
  }

  /// Execute a single action and update result arrays
  private func executeActionWithResult(
    _ action: SecurityAction,
    resultsQueue: DispatchQueue,
    executedActions: inout [SecurityAction],
    failedActions: inout [(SecurityAction, Error)]
  ) {
    do {
      try executeAction(action)
      resultsQueue.sync {
        executedActions.append(action)
      }
    } catch {
      resultsQueue.sync {
        failedActions.append((action, error))
      }
    }
  }

  /// Update the security actions configuration.
  ///
  /// Applies new configuration settings and persists them for future use.
  /// Changes take effect immediately for subsequent action executions.
  ///
  /// - Parameter newConfig: New configuration to apply
  public func updateConfiguration(_ newConfig: Configuration) {
    applyConfiguration(newConfig)
  }

  /// Applies configuration synchronously (settings sync path).
  func applyConfiguration(_ newConfig: Configuration) {
    queue.sync { [weak self] in
      guard let self else { return }
      self.configuration = newConfig
      self.saveConfiguration()
    }
  }

  /// Stop any ongoing actions that may continue after execution.
  ///
  /// Terminates persistent actions like alarm sounds that may continue
  /// playing after the initial execution. Cancels a pending shutdown timer.
  /// Does not affect completed actions like screen locking.
  public func stopOngoingActions() {
    queue.async { [weak self] in
      self?.systemActions.stopAlarm()
      self?.systemActions.cancelScheduledShutdown()
    }
  }

  // MARK: - Private Methods

  private func executeAction(_ action: SecurityAction) throws {
    Log.info("Executing action: \(action.displayName)", category: .security)

    switch action {
    case .lockScreen:
      try executeScreenLock()
    case .soundAlarm:
      try executeSoundAlarm()
    case .forceLogout:
      try executeForceLogout()
    case .shutdown:
      try executeShutdown()
    case .customScript:
      try executeCustomScript()
    }
  }

  private func executeScreenLock() throws {
    try systemActions.lockScreen()
  }

  private func executeSoundAlarm() throws {
    try systemActions.playAlarm(
      volume: configuration.alarmVolume,
      boostSystemVolume: configuration.boostSystemVolumeForAlarm,
      durationSeconds: configuration.alarmDurationSeconds
    )
  }

  private func executeForceLogout() throws {
    try systemActions.forceLogout()
  }

  private func executeShutdown() throws {
    try systemActions.scheduleShutdown(afterSeconds: configuration.shutdownDelay)
  }

  private func executeCustomScript() throws {
    let paths =
      configuration.customScriptPaths.isEmpty
      ? (configuration.customScriptPath.map { [$0] } ?? [])
      : configuration.customScriptPaths

    guard !paths.isEmpty else {
      throw SystemActionError.scriptNotFound
    }

    for path in paths {
      try systemActions.executeScript(at: path, timeLimit: nil)
    }
  }

  // MARK: - Configuration Persistence

  private func loadConfiguration() {
    guard let data = UserDefaults.standard.data(forKey: "SecurityActionsConfiguration"),
      let config = try? JSONDecoder().decode(Configuration.self, from: data)
    else {
      return
    }
    configuration = config
  }

  private func saveConfiguration() {
    guard let data = try? JSONEncoder().encode(configuration) else { return }
    UserDefaults.standard.set(data, forKey: "SecurityActionsConfiguration")
  }

  #if DEBUG
  private var effectiveMinimumExecutionInterval: TimeInterval {
    testMinimumExecutionInterval ?? minimumExecutionInterval
  }

  private var effectiveMaxExecutionsPerWindow: Int {
    testMaxExecutionsPerWindow ?? maxExecutionsPerWindow
  }

  private var effectiveRateLimitWindow: TimeInterval {
    testRateLimitWindow ?? rateLimitWindow
  }

  private var effectiveMaxConsecutiveFailures: Int {
    testMaxConsecutiveFailures ?? maxConsecutiveFailures
  }

  private var effectiveCircuitOpenDuration: TimeInterval {
    testCircuitOpenDuration ?? circuitOpenDuration
  }

  func resetProtectionStateForTesting() {
    rateLimitLock.lock()
    lastExecutionTime = nil
    executionHistory = []
    rateLimitLock.unlock()

    circuitBreakerLock.lock()
    circuitBreakerState = .closed
    consecutiveFailures = 0
    circuitBreakerLock.unlock()

    clearExecuting()
  }

  func configureRateLimitForTesting(
    minimumInterval: TimeInterval = 0,
    maxExecutions: Int = 10,
    window: TimeInterval = 60
  ) {
    testMinimumExecutionInterval = minimumInterval
    testMaxExecutionsPerWindow = maxExecutions
    testRateLimitWindow = window
  }

  func configureCircuitBreakerForTesting(
    maxFailures: Int = 3,
    openDuration: TimeInterval = 60
  ) {
    testMaxConsecutiveFailures = maxFailures
    testCircuitOpenDuration = openDuration
  }
  #else
  private var effectiveMinimumExecutionInterval: TimeInterval { minimumExecutionInterval }
  private var effectiveMaxExecutionsPerWindow: Int { maxExecutionsPerWindow }
  private var effectiveRateLimitWindow: TimeInterval { rateLimitWindow }
  private var effectiveMaxConsecutiveFailures: Int { maxConsecutiveFailures }
  private var effectiveCircuitOpenDuration: TimeInterval { circuitOpenDuration }
  #endif
}

// MARK: - Objective-C Compatibility

/// Objective-C compatible extension for SecurityActionsService
@objc extension SecurityActionsService {
  /// Execute security actions with simple boolean completion.
  ///
  /// Objective-C compatible method that provides basic success/failure
  /// indication without detailed error information.
  ///
  /// - Parameter completion: Called with true if all actions succeeded
  public func executeActionsObjC(completion: @escaping (Bool) -> Void) {
    executeActions { result in
      completion(result.allSucceeded)
    }
  }

  /// Whether screen lock action is currently enabled.
  ///
  /// Objective-C compatible property for checking if the most basic
  /// security action (screen lock) is configured.
  public var isScreenLockEnabled: Bool {
    return configuration.enabledActions.contains(.lockScreen)
  }

  /// Enable or disable the screen lock security action.
  ///
  /// Objective-C compatible method for toggling the screen lock action.
  /// Changes are persisted automatically.
  ///
  /// - Parameter enabled: True to enable screen lock, false to disable
  public func setScreenLockEnabled(_ enabled: Bool) {
    var newConfig = configuration
    if enabled {
      newConfig.enabledActions.insert(.lockScreen)
    } else {
      newConfig.enabledActions.remove(.lockScreen)
    }
    updateConfiguration(newConfig)
  }
}
