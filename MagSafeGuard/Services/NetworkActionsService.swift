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
      kSecAttrAccount as String: webhookTokenAccount,
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
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess,
      let data = item as? Data,
      let token = String(data: data, encoding: .utf8)
    else { return "" }
    return token
  }

  private func execute(action: NetworkActionType, event: String, settings: Settings) throws {
    switch action {
    case .webhook:
      guard let url = URL(string: settings.webhookURL), !settings.webhookURL.isEmpty else {
        throw NetworkActionError.invalidURL
      }
      try networkActions.postWebhook(url: url, event: event, token: loadWebhookToken())
    case .disconnectVPN:
      try networkActions.disconnectVPN()
    case .clearSSHAgent:
      try networkActions.clearSSHAgent()
    case .disableWiFi:
      try networkActions.disableWiFi()
    }
  }
}
