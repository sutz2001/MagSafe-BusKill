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
  case clearClipboard = "clear_clipboard"
  case ejectRemovableVolumes = "eject_removable_volumes"
  case unmountCryptomatorVolumes = "unmount_cryptomator_volumes"
  case disableBluetooth = "disable_bluetooth"
  case disableWiFi = "disable_wifi"

  public var displayName: String {
    switch self {
    case .webhook: return "HTTP Webhook"
    case .disconnectVPN: return "Disconnect VPN"
    case .clearSSHAgent: return "Clear SSH Agent"
    case .clearClipboard: return "Clear Clipboard"
    case .ejectRemovableVolumes: return "Eject Removable Volumes"
    case .unmountCryptomatorVolumes: return "Unmount Cryptomator"
    case .disableBluetooth: return "Disable Bluetooth"
    case .disableWiFi: return "Disable Wi-Fi"
    }
  }

  public var symbolName: String {
    switch self {
    case .webhook: return "antenna.radiowaves.left.and.right"
    case .disconnectVPN: return "network.slash"
    case .clearSSHAgent: return "key.slash"
    case .clearClipboard: return "clipboard"
    case .ejectRemovableVolumes: return "externaldrive.badge.xmark"
    case .unmountCryptomatorVolumes: return "lock.rectangle.stack"
    case .disableBluetooth: return "bluetooth.slash"
    case .disableWiFi: return "wifi.slash"
    }
  }
}

/// Remote trigger configuration (URL scheme).
public struct RemoteTriggerSettings: Codable, Equatable, Sendable {
  public var isEnabled: Bool
  /// Shared token for `trigger`, `arm`, and `panic` hosts.
  public var token: String
  /// Optional token for `paranoid` only. Empty → falls back to `token`.
  public var paranoidToken: String

  public init(isEnabled: Bool = false, token: String = "", paranoidToken: String = "") {
    self.isEnabled = isEnabled
    self.token = token
    self.paranoidToken = paranoidToken
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
    token = try container.decodeIfPresent(String.self, forKey: .token) ?? ""
    paranoidToken = try container.decodeIfPresent(String.self, forKey: .paranoidToken) ?? ""
  }

  /// Effective token for `magsafeguard://paranoid`.
  public var effectiveParanoidToken: String {
    let trimmed = paranoidToken.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? token : trimmed
  }
}
