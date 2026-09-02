//
//  NetworkActionsProtocol.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

public protocol NetworkActionsProtocol: Sendable {
  func postWebhook(url: URL, event: String, token: String?, timeout: TimeInterval) throws
  func disconnectVPN() throws
  func clearSSHAgent() throws
  func clearClipboard() throws
  func disableWiFi() throws
}

public enum NetworkActionError: LocalizedError, Equatable {
  case invalidURL
  case webhookFailed(statusCode: Int)
  case commandFailed(action: NetworkActionType, message: String)

  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid webhook URL"
    case .webhookFailed(let statusCode):
      return "Webhook request failed (HTTP \(statusCode))"
    case .commandFailed(let action, let message):
      return "\(action.displayName) failed: \(message)"
    }
  }
}
