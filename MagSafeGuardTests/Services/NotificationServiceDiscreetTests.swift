//
//  NotificationServiceDiscreetTests.swift
//  MagSafe Guard
//

import XCTest

@testable import MagSafeGuard

final class NotificationServiceDiscreetTests: XCTestCase {

  private var mockDelivery: MockNotificationDeliveryForDiscreet!
  private var sut: NotificationService!

  override func setUp() {
    super.setUp()
    NotificationService.disableForTesting = false
    mockDelivery = MockNotificationDeliveryForDiscreet()
    sut = NotificationService(deliveryMethod: mockDelivery)
    UserDefaultsManager.shared.settings.showSecurityAlerts = true
    UserDefaultsManager.shared.settings.playCriticalAlertSound = false
  }

  override func tearDown() {
    NotificationService.disableForTesting = true
    UserDefaultsManager.shared.settings.showSecurityAlerts = true
    UserDefaultsManager.shared.settings.playCriticalAlertSound = true
    sut = nil
    mockDelivery = nil
    super.tearDown()
  }

  func testShowCriticalAlertDeliversWhenSecurityAlertsEnabled() {
    sut.showCriticalAlert(title: "Security Alert", message: "Grace started")

    XCTAssertEqual(mockDelivery.deliveredNotifications.count, 1)
  }

  func testShowCriticalAlertSkipsVisualWhenSecurityAlertsDisabled() {
    UserDefaultsManager.shared.settings.showSecurityAlerts = false

    sut.showCriticalAlert(title: "Security Alert", message: "Grace started")

    XCTAssertTrue(mockDelivery.deliveredNotifications.isEmpty)
  }
}

private final class MockNotificationDeliveryForDiscreet: NotificationDeliveryProtocol {
  var deliveredNotifications: [(title: String, message: String, identifier: String)] = []

  func deliver(title: String, message: String, identifier: String) {
    deliveredNotifications.append((title, message, identifier))
  }

  func requestPermissions(completion: @escaping (Bool) -> Void) {
    completion(true)
  }
}
