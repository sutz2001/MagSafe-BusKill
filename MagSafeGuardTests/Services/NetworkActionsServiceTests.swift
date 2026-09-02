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

  func testHygienePhaseRunsClipboardBeforeSSH() {
    UserDefaultsManager.shared.updateSetting(
      \.enabledNetworkActions,
      value: [.clearSSHAgent, .clearClipboard, .webhook]
    )
    mockActions.executionOrder = []

    _ = sut.executeHygienePhase(event: "hygiene_test")

    XCTAssertEqual(mockActions.executionOrder, [.clearClipboard, .clearSSHAgent, .webhook])
  }
}

private final class MockNetworkActions: NetworkActionsProtocol {
  var webhookCalled = false
  var lastEvent = ""
  var clearSSHAgentCalled = false
  var clearClipboardCalled = false
  var executionOrder: [NetworkActionType] = []

  func postWebhook(url: URL, event: String, token: String?, timeout: TimeInterval) throws {
    webhookCalled = true
    lastEvent = event
    executionOrder.append(.webhook)
    XCTAssertEqual(token, "secret")
  }

  func disconnectVPN() throws {
    executionOrder.append(.disconnectVPN)
  }

  func clearSSHAgent() throws {
    clearSSHAgentCalled = true
    executionOrder.append(.clearSSHAgent)
  }

  func clearClipboard() throws {
    clearClipboardCalled = true
    executionOrder.append(.clearClipboard)
  }

  func disableWiFi() throws {
    executionOrder.append(.disableWiFi)
  }
}
