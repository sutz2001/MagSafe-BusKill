//
//  NetworkActionsServiceTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
import MagSafeGuardCore
import XCTest

final class NetworkActionsServiceTests: XCTestCase {

  private var mockActions: MockNetworkActions!
  private var sut: NetworkActionsService!

  override func setUp() {
    super.setUp()
    mockActions = MockNetworkActions()
    sut = NetworkActionsService(networkActions: mockActions, settingsManager: .shared)
    UserDefaultsManager.shared.updateSetting(\.enabledNetworkActions, value: [.webhook, .clearSSHAgent])
    UserDefaultsManager.shared.updateSetting(\.webhookURL, value: "https://example.com/hook")
    sut.saveWebhookToken("secret")
  }

  override func tearDown() {
    UserDefaultsManager.shared.updateSetting(\.enabledNetworkActions, value: [])
    UserDefaultsManager.shared.updateSetting(\.webhookURL, value: "")
    sut.saveWebhookToken("")
    super.tearDown()
  }

  func testExecuteEnabledNetworkActions() {
    sut.executeActions(event: "test_event")
    XCTAssertTrue(mockActions.webhookCalled)
    XCTAssertEqual(mockActions.lastEvent, "test_event")
    XCTAssertTrue(mockActions.clearSSHAgentCalled)
  }
}

private final class MockNetworkActions: NetworkActionsProtocol {
  var webhookCalled = false
  var lastEvent = ""
  var clearSSHAgentCalled = false

  func postWebhook(url: URL, event: String, token: String?) throws {
    webhookCalled = true
    lastEvent = event
    XCTAssertEqual(token, "secret")
  }

  func disconnectVPN() throws {}
  func clearSSHAgent() throws { clearSSHAgentCalled = true }
  func disableWiFi() throws {}
}
