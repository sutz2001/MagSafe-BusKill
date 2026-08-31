//
//  AutoArmManagerTests.swift
//  MagSafe Guard
//

import CoreLocation
@testable import MagSafeGuard
import MagSafeGuardDomain
import XCTest

final class AutoArmManagerTests: XCTestCase {

  private var appController: AppController!
  private var mockLocationManager: MockLocationManagerForAutoArm!
  private var sut: AutoArmManager!

  override func setUp() {
    super.setUp()
    NotificationService.disableForTesting = true
    AppController.isTestEnvironment = true

    mockLocationManager = MockLocationManagerForAutoArm()
    appController = AppController(
      powerMonitor: PowerMonitorService.shared,
      authService: MockAuthenticationServiceForAutoArm().createConfiguredService(),
      securityActions: SecurityActionsService(systemActions: MockSystemActions()),
      notificationService: NotificationService(deliveryMethod: MockNotificationServiceForAutoArm())
    )
    sut = AutoArmManager(appController: appController, locationManager: mockLocationManager)
    sut.autoArmCooldownOverride = 30
    UserDefaultsManager.shared.updateSetting(\.autoArmEnabled, value: true)
    UserDefaultsManager.shared.updateSetting(\.autoArmByLocation, value: true)
  }

  override func tearDown() {
    sut.stopMonitoring()
    sut = nil
    appController = nil
    mockLocationManager = nil
    AppController.isTestEnvironment = false
    NotificationService.disableForTesting = false
    UserDefaultsManager.shared.updateSetting(\.autoArmEnabled, value: false)
    super.tearDown()
  }

  func testSkipsAutoArmWhenAlreadyArmed() {
    armAppController()
    sut.locationManagerDidLeaveTrustedLocation()
    XCTAssertEqual(appController.currentState, .armed)
  }

  func testCooldownPreventsRapidAutoArm() {
    sut.setLastAutoArmTimeForTesting(Date())
    sut.locationManagerDidLeaveTrustedLocation()
    XCTAssertEqual(appController.currentState, .disarmed)
  }

  func testTemporaryDisableBlocksAutoArm() {
    sut.temporarilyDisable(for: 3600)
    sut.locationManagerDidLeaveTrustedLocation()
    XCTAssertEqual(appController.currentState, .disarmed)
  }

  func testStartsMonitoringWhenAutoArmEnabledViaUpdateSettings() {
    sut.stopMonitoring()
    XCTAssertFalse(sut.isMonitoring)

    UserDefaultsManager.shared.updateSetting(\.autoArmEnabled, value: true)
    UserDefaultsManager.shared.updateSetting(\.autoArmByLocation, value: true)
    sut.updateSettings()

    XCTAssertTrue(sut.isMonitoring)
  }

  func testAutoArmArmsWithoutInteractiveAuth() {
    let exp = expectation(description: "auto arm without auth")
    sut.locationManagerDidLeaveTrustedLocation()

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
      XCTAssertEqual(self.appController.currentState, .armed)
      exp.fulfill()
    }
    waitForExpectations(timeout: 4)
  }

  private func armAppController() {
    let exp = expectation(description: "arm")
    appController.arm { _ in exp.fulfill() }
    waitForExpectations(timeout: 1)
  }
}

// MARK: - Mocks

private final class MockLocationManagerForAutoArm: LocationManagerProtocol {
  weak var delegate: LocationManagerDelegate?
  var trustedLocations: [TrustedLocation] = []
  var isMonitoring = false
  var currentLocation: CLLocation?
  var isInTrustedLocation = true

  func startMonitoring() { isMonitoring = true }
  func stopMonitoring() { isMonitoring = false }
  func addTrustedLocation(_ location: TrustedLocation) { trustedLocations.append(location) }
  func removeTrustedLocation(id: UUID) {
    trustedLocations.removeAll { $0.id == id }
  }
  func updateTrustedLocations(_ locations: [TrustedLocation]) { trustedLocations = locations }
  func checkIfInTrustedLocation() -> Bool { isInTrustedLocation }
}

private final class MockAuthenticationServiceForAutoArm {
  private let mockContext = MockAuthenticationContext()

  func createConfiguredService() -> AuthenticationService {
    mockContext.canEvaluatePolicyResult = true
    mockContext.evaluatePolicyShouldSucceed = true
    return AuthenticationService(
      contextFactory: MockAuthenticationContextFactory(mockContext: mockContext))
  }
}

private final class MockNotificationServiceForAutoArm: NotificationDeliveryProtocol {
  func deliver(title: String, message: String, identifier: String) {}
  func requestPermissions(completion: @escaping (Bool) -> Void) { completion(true) }
}
