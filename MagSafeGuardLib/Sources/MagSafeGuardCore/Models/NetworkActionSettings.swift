//
//  NetworkActionSettings.swift
//  MagSafeGuardCore
//

import Foundation

/// Network reactions that run alongside security actions on trigger.
public enum NetworkActionType: String, CaseIterable, Codable, Sendable, Equatable {
  case webhook = "webhook"
  case disconnectVPN = "disconnect_vpn"
  case clearSSHAgent = "clear_ssh_agent"
  case disableWiFi = "disable_wifi"

  public var displayName: String {
    switch self {
    case .webhook: return "HTTP Webhook"
    case .disconnectVPN: return "Disconnect VPN"
    case .clearSSHAgent: return "Clear SSH Agent"
    case .disableWiFi: return "Disable Wi-Fi"
    }
  }

  public var symbolName: String {
    switch self {
    case .webhook: return "antenna.radiowaves.left.and.right"
    case .disconnectVPN: return "network.slash"
    case .clearSSHAgent: return "key.slash"
    case .disableWiFi: return "wifi.slash"
    }
  }
}

/// Remote trigger configuration (URL scheme).
public struct RemoteTriggerSettings: Codable, Equatable, Sendable {
  public var isEnabled: Bool
  public var token: String

  public init(isEnabled: Bool = false, token: String = "") {
    self.isEnabled = isEnabled
    self.token = token
  }
}
