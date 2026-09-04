//
//  RemoteTriggerServiceTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
@testable import MagSafeGuardCore
import XCTest

final class RemoteTriggerServiceTests: XCTestCase {

  private var sutController: AppController!
  private var service: RemoteTriggerService!

  override func setUp() {
    super.setUp()
    AppController.isTestEnvironment = true
    NotificationService.disableForTesting = true
    sutController = AppController()
    service = RemoteTriggerService(appController: sutController, settingsManager: .shared)
    UserDefaultsManager.shared.updateSettings { settings in
      settings.remoteTrigger = RemoteTriggerSettings(
        isEnabled: true,
        token: "shared-token",
        paranoidToken: ""
      )
    }
  }

  override func tearDown() {
    service = nil
    sutController = nil
    super.tearDown()
  }

  func testParanoidHostAcceptsSharedTokenWhenParanoidTokenEmpty() {
    let url = URL(string: "magsafeguard://paranoid?token=shared-token")!
    XCTAssertTrue(service.handle(url: url))
  }

  func testParanoidHostRejectsWrongTokenWithoutTriggering() {
    let url = URL(string: "magsafeguard://paranoid?token=wrong")!
    XCTAssertTrue(service.handle(url: url))
    XCTAssertEqual(sutController.currentState, .disarmed)
  }

  func testParanoidHostRequiresDedicatedTokenWhenSet() {
    UserDefaultsManager.shared.updateSettings { settings in
      settings.remoteTrigger.paranoidToken = "para-only"
    }
    let wrongShared = URL(string: "magsafeguard://paranoid?token=shared-token")!
    XCTAssertTrue(service.handle(url: wrongShared))

    let dedicated = URL(string: "magsafeguard://paranoid?token=para-only")!
    XCTAssertTrue(service.handle(url: dedicated))
  }

  func testEffectiveParanoidTokenFallsBackToShared() {
    var remote = RemoteTriggerSettings(isEnabled: true, token: "a", paranoidToken: "")
    XCTAssertEqual(remote.effectiveParanoidToken, "a")
    remote.paranoidToken = " b "
    XCTAssertEqual(remote.effectiveParanoidToken, "b")
  }

  func testDecodeWithoutParanoidTokenKey() throws {
    let json = #"{"isEnabled":true,"token":"t"}"#.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(RemoteTriggerSettings.self, from: json)
    XCTAssertEqual(decoded.token, "t")
    XCTAssertEqual(decoded.paranoidToken, "")
    XCTAssertEqual(decoded.effectiveParanoidToken, "t")
  }

  func testDisabledRemoteTriggerStillReturnsHandled() {
    UserDefaultsManager.shared.updateSettings { settings in
      settings.remoteTrigger.isEnabled = false
    }
    let url = URL(string: "magsafeguard://paranoid?token=shared-token")!
    XCTAssertTrue(service.handle(url: url))
  }
}
