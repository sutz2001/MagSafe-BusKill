//
//  AppControllerTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Tests for AppController - the central coordinator
//

import XCTest

@testable import MagSafeGuard

final class AppControllerTests: XCTestCase {

  // MARK: - Properties

  private var sut: AppController!
  private var mockAuthService: MockAuthenticationService!
  private var authService: AuthenticationService!
  private var mockSecurityActions: MockSystemActions!
  private var mockNotificationService: MockNotificationService!

  // MARK: - Setup

  override func setUp() {
    super.setUp()

    // Disable notifications for testing
    NotificationService.disableForTesting = true

    // Disable auto-arm for testing to avoid location permission issues
    AppController.isTestEnvironment = true

    mockAuthService = MockAuthenticationService()
    authService = mockAuthService.createConfiguredService()
    authService.resetAuthenticationAttempts()
    mockSecurityActions = MockSystemActions()
    mockNotificationService = MockNotificationService()
    let securityService = SecurityActionsService(systemActions: mockSecurityActions)

    sut = AppController(
      powerMonitor: PowerMonitorService.shared,  // Use real service for now
      authService: authService,
      securityActions: securityService,
      notificationService: NotificationService(deliveryMethod: mockNotificationService),
      triggerPipeline: SecurityTriggerPipeline(
        networkActions: NetworkActionsService(settingsManager: .shared),
        securityActions: securityService,
        settingsManager: .shared
      )
    )
  }

  override func tearDown() {
    sut = nil
    authService = nil
    mockAuthService = nil
    mockSecurityActions = nil
    mockNotificationService = nil

    // Re-enable notifications after testing
    NotificationService.disableForTesting = false

    // Reset test environment flag
    AppController.isTestEnvironment = false

    super.tearDown()
  }

  // MARK: - Initial State Tests

  func testInitialState() {
    XCTAssertEqual(sut.currentState, .disarmed)
    XCTAssertFalse(sut.isInGracePeriod)
    XCTAssertEqual(sut.gracePeriodRemaining, 0)
    // Grace period should be between 5-30 seconds (validated by settings)
    XCTAssertGreaterThanOrEqual(sut.gracePeriodDuration, 5.0)
    XCTAssertLessThanOrEqual(sut.gracePeriodDuration, 30.0)
    // Default value from Settings is true, but can be persisted from previous test runs
    // Just verify it's a Boolean
    _ = sut.allowGracePeriodCancellation  // Can be true or false based on persisted settings
  }

  // MARK: - Arming Tests

  func testArmingWithSuccessfulAuthentication() {
    let expectation = expectation(description: "Arm completion")
    mockAuthService.shouldSucceed = true

    sut.arm { result in
      switch result {
      case .success:
        XCTAssertEqual(self.sut.currentState, .armed)
        XCTAssertTrue(
          self.mockNotificationService.deliveredNotifications.contains {
            $0.title == L10n.tr("notification.armed.title")
          })
      case .failure:
        XCTFail("Arming should succeed")
      }
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)
  }

  func testArmingWithFailedAuthentication() {
    let expectation = expectation(description: "Arm completion")
    mockAuthService.shouldSucceed = false

    // Re-create the app controller with failed auth
    sut = AppController(
      powerMonitor: PowerMonitorService.shared,
      authService: mockAuthService.createConfiguredService(),
      securityActions: SecurityActionsService(systemActions: mockSecurityActions),
      notificationService: NotificationService(deliveryMethod: mockNotificationService)
    )

    sut.arm { result in
      switch result {
      case .success:
        XCTFail("Arming should fail")
      case .failure(let error):
        XCTAssertEqual(self.sut.currentState, .disarmed)
        XCTAssertNotNil(error)
      }
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)
  }

  func testArmingFromNonDisarmedState() {
    // First arm the system
    mockAuthService.shouldSucceed = true
    let armExpectation = expectation(description: "Initial arm")

    sut.arm { _ in
      armExpectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)

    // Try to arm again
    let rearmExpectation = expectation(description: "Re-arm attempt")

    sut.arm { result in
      switch result {
      case .success:
        XCTFail("Should not be able to arm when already armed")
      case .failure(let error):
        XCTAssertTrue(error is AppControllerError)
      }
      rearmExpectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)
  }

  // MARK: - Disarming Tests

  func testDisarmingFromArmedState() {
    // First arm the system
    mockAuthService.shouldSucceed = true
    let armExpectation = expectation(description: "Arm")

    sut.arm { _ in
      armExpectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)

    // Now disarm
    let disarmExpectation = expectation(description: "Disarm")

    sut.disarm { result in
      switch result {
      case .success:
        XCTAssertEqual(self.sut.currentState, .disarmed)
        XCTAssertTrue(
          self.mockNotificationService.deliveredNotifications.contains {
            $0.title == L10n.tr("notification.disarmed.title")
          })
      case .failure:
        XCTFail("Disarming should succeed")
      }
      disarmExpectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)
  }

  // MARK: - Power Disconnect & Grace Period Tests

  func testPowerDisconnectStartsGracePeriod() {
    armSystem()

    sut.simulatePowerDisconnectForTesting()

    XCTAssertEqual(sut.currentState, .gracePeriod)
    XCTAssertTrue(sut.isInGracePeriod)
    XCTAssertGreaterThan(sut.gracePeriodRemaining, 0)
    XCTAssertTrue(sut.getEventLog().contains { $0.event == .powerDisconnected })
    XCTAssertTrue(sut.getEventLog().contains { $0.event == .gracePeriodStarted })
    XCTAssertFalse(mockSecurityActions.lockScreenCalled)
  }

  func testGracePeriodExpiryExecutesSecurityActions() {
    armSystem()
    sut.simulatePowerDisconnectForTesting()

    sut.expireGracePeriodForTesting()

    waitUntil("security actions run") {
      self.mockSecurityActions.lockScreenCalled
    }

    XCTAssertFalse(sut.isInGracePeriod)
    XCTAssertEqual(sut.currentState, .armed)
    XCTAssertTrue(sut.getEventLog().contains { $0.event == .securityActionExecuted })
  }

  func testZeroGracePeriodExecutesSecurityActionsImmediately() {
    armSystem()
    sut.setGracePeriodDurationForTesting(0)

    sut.simulatePowerDisconnectForTesting()

    XCTAssertFalse(sut.isInGracePeriod)
    waitUntil("immediate security actions") {
      self.mockSecurityActions.lockScreenCalled
    }
    XCTAssertTrue(sut.getEventLog().contains { $0.event == .powerDisconnected })
    XCTAssertFalse(sut.getEventLog().contains { $0.event == .gracePeriodStarted })
  }

  func testPowerReconnectDuringGracePeriodCancelsTrigger() {
    armSystem()
    sut.simulatePowerDisconnectForTesting()
    XCTAssertTrue(sut.isInGracePeriod)

    sut.simulatePowerConnectForTesting()

    XCTAssertFalse(sut.isInGracePeriod)
    XCTAssertEqual(sut.currentState, .armed)
    XCTAssertEqual(sut.gracePeriodRemaining, 0)
    XCTAssertTrue(sut.getEventLog().contains { $0.event == .gracePeriodCancelled })
    XCTAssertFalse(mockSecurityActions.lockScreenCalled)
  }

  func testGraceExpiryAfterReconnectDoesNotExecuteActions() {
    armSystem()
    sut.simulatePowerDisconnectForTesting()
    sut.simulatePowerConnectForTesting()

    XCTAssertEqual(sut.currentState, .armed)
    sut.attemptGraceExpiryAfterCancelForTesting()

    XCTAssertEqual(sut.currentState, .armed)
    XCTAssertFalse(mockSecurityActions.lockScreenCalled)
  }

  func testCancelGracePeriodWithAuthSuccess() {
    armSystem()
    sut.simulatePowerDisconnectForTesting()
    mockAuthService.shouldSucceed = true

    let cancelExpectation = expectation(description: "Cancel grace period")
    sut.cancelGracePeriodWithAuth { result in
      switch result {
      case .success:
        XCTAssertFalse(self.sut.isInGracePeriod)
        XCTAssertEqual(self.sut.currentState, .armed)
        XCTAssertFalse(self.mockSecurityActions.lockScreenCalled)
      case .failure:
        XCTFail("Cancellation should succeed")
      }
      cancelExpectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)
  }

  func testCancelGracePeriodWithAuthFailure() {
    armSystem()
    sut.gracePeriodDuration = 60
    sut.simulatePowerDisconnectForTesting()
    mockAuthService.shouldSucceed = false
    mockAuthService.applyAuthConfiguration()

    let cancelExpectation = expectation(description: "Cancel grace period failure")
    sut.cancelGracePeriodWithAuth { result in
      switch result {
      case .success:
        XCTFail("Cancellation should fail")
      case .failure:
        XCTAssertTrue(self.sut.isInGracePeriod)
        XCTAssertEqual(self.sut.currentState, .gracePeriod)
      }
      cancelExpectation.fulfill()
    }

    waitForExpectations(timeout: 3.0)
  }

  // MARK: - Grace Period Cancellation Tests

  func testCancelGracePeriodNotAllowed() {
    // Disable grace period cancellation
    sut.allowGracePeriodCancellation = false

    let cancelExpectation = expectation(description: "Cancel")
    sut.cancelGracePeriodWithAuth { result in
      switch result {
      case .success:
        XCTFail("Should fail when cancellation not allowed")
      case .failure(let error as AppControllerError):
        // Can't use XCTAssertEqual as AppControllerError doesn't conform to Equatable
        if case .gracePeriodNotCancellable = error {
          XCTAssertTrue(true)
        } else {
          XCTFail("Wrong error type")
        }
      case .failure:
        XCTFail("Wrong error type")
      }
      cancelExpectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)
  }

  // MARK: - Configuration Tests

  func testGracePeriodConfiguration() {
    // Test setting grace period duration
    sut.gracePeriodDuration = 15.0
    XCTAssertEqual(sut.gracePeriodDuration, 15.0)

    // Test validation bounds
    sut.gracePeriodDuration = 3.0
    XCTAssertEqual(sut.gracePeriodDuration, 5.0)  // Should be clamped to minimum

    sut.gracePeriodDuration = 35.0
    XCTAssertEqual(sut.gracePeriodDuration, 30.0)  // Should be clamped to maximum
  }

  func testAllowGracePeriodCancellationConfiguration() {
    sut.allowGracePeriodCancellation = false
    XCTAssertFalse(sut.allowGracePeriodCancellation)

    sut.allowGracePeriodCancellation = true
    XCTAssertTrue(sut.allowGracePeriodCancellation)
  }

  // MARK: - Event Logging Tests

  func testEventLogging() {
    // Clear any existing events from initialization
    sut.clearEventLog()

    // Now should be empty
    var events = sut.getEventLog()
    XCTAssertTrue(events.isEmpty)

    // Arm the system
    mockAuthService.shouldSucceed = true
    let armExpectation = expectation(description: "Arm")

    sut.arm { _ in
      armExpectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)

    // Check events were logged
    events = sut.getEventLog()
    XCTAssertFalse(events.isEmpty)
    XCTAssertTrue(events.contains { $0.event == .authenticationSucceeded })
    XCTAssertTrue(events.contains { $0.event == .armed })
  }

  func testEventLogClearing() {
    // Log some events
    sut.logEvent(.armed, details: "Test event")

    var events = sut.getEventLog()
    XCTAssertFalse(events.isEmpty)

    // Clear log
    sut.clearEventLog()

    // Check immediately since clearEventLog is now synchronous
    events = sut.getEventLog()
    XCTAssertTrue(events.isEmpty, "Event log should be empty after clearing")
  }

  // MARK: - Demo Mode Tests

  // TODO: Add demo mode tests when demo functionality is implemented
  // The AppController doesn't currently have a runDemo method

  // MARK: - State Transition Tests

  func testStateChangeCallback() {
    let stateExpectation = expectation(description: "State change")
    var oldStateReceived: AppState?
    var newStateReceived: AppState?

    sut.onStateChange = { old, new in
      guard old == .disarmed, new == .armed else { return }
      oldStateReceived = old
      newStateReceived = new
      stateExpectation.fulfill()
    }

    mockAuthService.shouldSucceed = true
    mockAuthService.applyAuthConfiguration()
    let armExpectation = expectation(description: "Arm")
    sut.arm { _ in armExpectation.fulfill() }

    waitForExpectations(timeout: 3.0)

    XCTAssertEqual(oldStateReceived, .disarmed)
    XCTAssertEqual(newStateReceived, .armed)
  }

  // MARK: - Menu Integration Tests

  func testMenuTitleForStates() {
    // Disarmed
    XCTAssertEqual(sut.armDisarmMenuTitle, L10n.tr("menu.arm"))

    // Armed
    mockAuthService.shouldSucceed = true
    let armExpectation = expectation(description: "Arm")

    sut.arm { _ in
      armExpectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)

    XCTAssertEqual(sut.armDisarmMenuTitle, L10n.tr("menu.disarm"))
  }

  func testStatusIconNames() {
    XCTAssertEqual(sut.statusIconName, "shield")  // Disarmed
    XCTAssertEqual(sut.statusMenuBarImageName, "MenuBarIconDisarmed")
    XCTAssertEqual(AppController.menuBarImageName(for: .gracePeriod), "MenuBarIconGracePeriod")
    XCTAssertEqual(AppController.menuBarImageName(for: .triggered), "MenuBarIconTriggered")

    // Arm
    mockAuthService.shouldSucceed = true
    let armExpectation = expectation(description: "Arm")

    sut.arm { _ in
      armExpectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)

    XCTAssertEqual(sut.statusIconName, "shield.fill")  // Armed
    XCTAssertEqual(sut.statusMenuBarImageName, "MenuBarIconArmed")
  }

  // MARK: - Panic Mode Tests

  func testArmPanicRequiresLegalNotice() {
    UserDefaultsManager.shared.updateSetting(\.panicLegalNoticeAccepted, value: false)
    mockAuthService.shouldSucceed = true

    let expectation = expectation(description: "arm panic without legal")
    sut.armPanic { result in
      guard case .failure(AppControllerError.panicLegalNoticeRequired) = result else {
        XCTFail("Expected panicLegalNoticeRequired")
        return
      }
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1.0)
    XCTAssertEqual(sut.currentState, .disarmed)
  }

  func testArmPanicSucceedsWhenLegalNoticeAccepted() {
    UserDefaultsManager.shared.updateSetting(\.panicLegalNoticeAccepted, value: true)
    mockAuthService.shouldSucceed = true

    let expectation = expectation(description: "arm panic")
    sut.armPanic { result in
      if case .failure = result {
        XCTFail("Panic arm should succeed")
      }
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1.0)

    XCTAssertEqual(sut.currentState, .armed)
    XCTAssertEqual(sut.protectionMode, .panic)
    XCTAssertEqual(sut.statusMenuBarImageName, "MenuBarIconTriggered")
    XCTAssertEqual(sut.statusDescription, L10n.tr("status.panicArmed"))
  }

  func testPanicPowerDisconnectSkipsGracePeriod() {
    UserDefaultsManager.shared.updateSetting(\.panicLegalNoticeAccepted, value: true)
    mockAuthService.shouldSucceed = true

    let securityService = SecurityActionsService(systemActions: mockSecurityActions)
    let pipeline = SecurityTriggerPipeline(
      networkActions: NetworkActionsService(settingsManager: .shared),
      securityActions: securityService,
      settingsManager: .shared
    )
    let panicExecutor = PanicModeExecutor(pipeline: pipeline)
    sut = AppController(
      powerMonitor: PowerMonitorService.shared,
      authService: mockAuthService.createConfiguredService(),
      securityActions: securityService,
      notificationService: NotificationService(deliveryMethod: mockNotificationService),
      panicExecutor: panicExecutor,
      triggerPipeline: pipeline
    )

    let armExpectation = expectation(description: "arm panic")
    sut.armPanic { _ in armExpectation.fulfill() }
    waitForExpectations(timeout: 1.0)

    sut.simulatePowerDisconnectForTesting()

    XCTAssertFalse(sut.isInGracePeriod)
    XCTAssertNotEqual(sut.currentState, .gracePeriod)
    waitUntil("panic immediate shutdown") {
      self.mockSecurityActions.executeImmediateShutdownCalled
    }
    XCTAssertTrue(sut.getEventLog().contains { $0.details == L10n.tr("logDetail.panicTriggered") })
  }

  func testPanicHotkeyTriggersResponseWhenPanicArmed() {
    UserDefaultsManager.shared.updateSetting(\.panicLegalNoticeAccepted, value: true)
    mockAuthService.shouldSucceed = true

    let securityService = SecurityActionsService(systemActions: mockSecurityActions)
    let pipeline = SecurityTriggerPipeline(
      networkActions: NetworkActionsService(settingsManager: .shared),
      securityActions: securityService,
      settingsManager: .shared
    )
    let panicExecutor = PanicModeExecutor(pipeline: pipeline)
    sut = AppController(
      powerMonitor: PowerMonitorService.shared,
      authService: mockAuthService.createConfiguredService(),
      securityActions: securityService,
      notificationService: NotificationService(deliveryMethod: mockNotificationService),
      panicExecutor: panicExecutor,
      triggerPipeline: pipeline
    )

    let armExpectation = expectation(description: "arm panic")
    sut.armPanic { _ in armExpectation.fulfill() }
    waitForExpectations(timeout: 1.0)

    sut.triggerPanicHotkeyResponse()

    waitUntil("panic hotkey shutdown") {
      self.mockSecurityActions.executeImmediateShutdownCalled
    }
    XCTAssertTrue(
      sut.getEventLog().contains { $0.details == L10n.tr("logDetail.panicHotkey") })
  }

  func testPanicHotkeyIgnoredWhenNotPanicArmed() {
    armSystem()
    sut.triggerPanicHotkeyResponse()
    XCTAssertFalse(mockSecurityActions.executeImmediateShutdownCalled)
  }

  func testEnterGracePeriodForTesting() {
    mockAuthService.shouldSucceed = true
    let armExpectation = expectation(description: "Arm")
    sut.arm { _ in armExpectation.fulfill() }
    waitForExpectations(timeout: 1.0)

    sut.enterGracePeriodForTesting()

    XCTAssertEqual(sut.currentState, .gracePeriod)
    XCTAssertTrue(sut.isInGracePeriod)
    XCTAssertGreaterThan(sut.gracePeriodRemaining, 0)
  }

  // MARK: - Test Helpers

  private func armSystem(file: StaticString = #filePath, line: UInt = #line) {
    mockAuthService.shouldSucceed = true
    sut.allowGracePeriodCancellation = true
    let armExpectation = expectation(description: "Arm system")
    sut.arm { result in
      if case .failure = result {
        XCTFail("Expected arm to succeed", file: file, line: line)
      }
      armExpectation.fulfill()
    }
    waitForExpectations(timeout: 1.0)
    XCTAssertEqual(sut.currentState, .armed, file: file, line: line)
  }

  private func waitUntil(
    _ description: String,
    timeout: TimeInterval = 2.0,
    file: StaticString = #filePath,
    line: UInt = #line,
    condition: @escaping () -> Bool
  ) {
    let predicate = NSPredicate { _, _ in condition() }
    let expectation = expectation(for: predicate, evaluatedWith: nil)
    wait(for: [expectation], timeout: timeout)
    XCTAssertTrue(condition(), "Condition not met: \(description)", file: file, line: line)
  }
}

// MARK: - Mock Classes

private class MockAuthenticationService {
  var shouldSucceed = true
  private let mockContext = MockAuthenticationContext()

  init() {
    // Configure mock context
    mockContext.canEvaluatePolicyResult = true
  }

  func createConfiguredService() -> AuthenticationService {
    applyAuthConfiguration()
    return AuthenticationService(
      contextFactory: MockAuthenticationContextFactory(mockContext: mockContext))
  }

  func applyAuthConfiguration() {
    mockContext.evaluatePolicyShouldSucceed = shouldSucceed
  }
}

private class MockNotificationService: NotificationDeliveryProtocol {
  var deliveredNotifications: [(title: String, message: String, identifier: String)] = []
  var permissionsRequested = false

  func deliver(title: String, message: String, identifier: String) {
    deliveredNotifications.append((title, message, identifier))
  }

  func requestPermissions(completion: @escaping (Bool) -> Void) {
    permissionsRequested = true
    completion(true)
  }
}
