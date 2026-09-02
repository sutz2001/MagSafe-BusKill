//
//  NetworkActionsService.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore
import Security

public struct NetworkActionResult {
  public let executed: [NetworkActionType]
  public let failed: [(NetworkActionType, Error)]

  public var allSucceeded: Bool { failed.isEmpty }
}

public final class NetworkActionsService {

  public static let shared = NetworkActionsService()

  private let networkActions: NetworkActionsProtocol
  private let settingsManager: UserDefaultsManager
  private let keychainService = "com.sutz2001.MagSafeGuard.network"
  private let webhookTokenAccount = "webhookToken"

  public init(
    networkActions: NetworkActionsProtocol = MacNetworkActions(),
    settingsManager: UserDefaultsManager = .shared
  ) {
    self.networkActions = networkActions
    self.settingsManager = settingsManager
  }

  @discardableResult
  public func executeHygienePhase(event: String = "security_trigger") -> NetworkActionResult {
    let settings = settingsManager.settings
    let enabled = Set(settings.enabledNetworkActions)
    guard !enabled.isEmpty else {
      return NetworkActionResult(executed: [], failed: [])
    }

    let deadline = Date().addingTimeInterval(HygienePhasePolicy.maxDuration)
    var executed: [NetworkActionType] = []
    var failed: [(NetworkActionType, Error)] = []

    for action in HygienePhasePolicy.orderedActions {
      guard enabled.contains(action) else { continue }
      let remaining = deadline.timeIntervalSinceNow
      guard remaining > 0 else {
        Log.info("Hygiene phase budget exhausted — skipping \(action.rawValue)", category: .security)
        break
      }

      do {
        try execute(
          action: action,
          event: event,
          settings: settings,
          timeLimit: remaining
        )
        executed.append(action)
      } catch {
        failed.append((action, error))
        Log.error("Hygiene action failed: \(action)", error: error, category: .security)
      }
    }

    if !executed.isEmpty {
      Log.info(
        "Hygiene phase executed: \(executed.map(\.rawValue).joined(separator: ", "))",
        category: .security)
    }

    return NetworkActionResult(executed: executed, failed: failed)
  }

  @discardableResult
  public func executeActions(event: String = "security_trigger") -> NetworkActionResult {
    let settings = settingsManager.settings
    guard !settings.enabledNetworkActions.isEmpty else {
      return NetworkActionResult(executed: [], failed: [])
    }

    var executed: [NetworkActionType] = []
    var failed: [(NetworkActionType, Error)] = []

    for action in settings.enabledNetworkActions {
      do {
        try execute(action: action, event: event, settings: settings)
        executed.append(action)
      } catch {
        failed.append((action, error))
        Log.error("Network action failed: \(action)", error: error, category: .security)
      }
    }

    if !executed.isEmpty {
      Log.info("Network actions executed: \(executed.map(\.rawValue).joined(separator: ", "))", category: .security)
    }
    if !failed.isEmpty {
      Log.warning("\(failed.count) network actions failed", category: .security)
    }

    return NetworkActionResult(executed: executed, failed: failed)
  }

  public func saveWebhookToken(_ token: String) {
    let data = token.data(using: .utf8) ?? Data()
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: webhookTokenAccount
    ]
    SecItemDelete(query as CFDictionary)
    guard !token.isEmpty else { return }
    var add = query
    add[kSecValueData as String] = data
    SecItemAdd(add as CFDictionary, nil)
  }

  public func loadWebhookToken() -> String {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: webhookTokenAccount,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess,
      let data = item as? Data,
      let token = String(data: data, encoding: .utf8)
    else { return "" }
    return token
  }

  private func execute(
    action: NetworkActionType,
    event: String,
    settings: Settings,
    timeLimit: TimeInterval? = nil
  ) throws {
    switch action {
    case .webhook:
      guard let url = URL(string: settings.webhookURL), !settings.webhookURL.isEmpty else {
        throw NetworkActionError.invalidURL
      }
      let webhookTimeout: TimeInterval
      if let timeLimit {
        webhookTimeout = min(timeLimit, HygienePhasePolicy.webhookTimeout)
      } else {
        webhookTimeout = 60
      }
      try networkActions.postWebhook(
        url: url, event: event, token: loadWebhookToken(), timeout: webhookTimeout)
    case .disconnectVPN:
      try networkActions.disconnectVPN()
    case .clearSSHAgent:
      try networkActions.clearSSHAgent()
    case .clearClipboard:
      try networkActions.clearClipboard()
    case .disableWiFi:
      try networkActions.disableWiFi()
    }
  }
}
