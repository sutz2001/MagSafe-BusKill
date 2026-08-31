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
    UserDefaultsManager.shared.updateSetting(\.showSecurityAlerts, value: true)
    UserDefaultsManager.shared.updateSetting(\.playCriticalAlertSound, value: false)
  }

  override func tearDown() {
    NotificationService.disableForTesting = true
    UserDefaultsManager.shared.updateSetting(\.showSecurityAlerts, value: true)
    UserDefaultsManager.shared.updateSetting(\.playCriticalAlertSound, value: true)
    sut = nil
    mockDelivery = nil
    super.tearDown()
  }

  func testShowCriticalAlertDeliversWhenSecurityAlertsEnabled() {
    sut.showCriticalAlert(title: "Security Alert", message: "Grace started")

    XCTAssertEqual(mockDelivery.deliveredNotifications.count, 1)
  }

  func testShowCriticalAlertSkipsVisualWhenSecurityAlertsDisabled() {
    UserDefaultsManager.shared.updateSetting(\.showSecurityAlerts, value: false)

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
