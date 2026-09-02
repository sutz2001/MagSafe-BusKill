//
//  TriggerRiskLevel.swift
//  MagSafeGuardCore
//

import Foundation
import MagSafeGuardDomain

/// User-facing impact tier for triggers and actions (informational only — never gates features).
public enum TriggerRiskLevel: Int, Codable, Sendable, Comparable, CaseIterable {
  /// Minimal disruption; no meaningful data loss expected (e.g. lock screen).
  case low = 0
  /// Session or unsaved work may be lost (e.g. logout, shutdown, network hygiene).
  case moderate = 1
  /// User-defined or immediate destructive response (custom scripts, panic-armed cable pull).
  case severe = 2

  public static func < (lhs: TriggerRiskLevel, rhs: TriggerRiskLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// MARK: - Per-action risk

extension SecurityActionType {
  public var triggerRiskLevel: TriggerRiskLevel {
    switch self {
    case .lockScreen, .soundAlarm:
      return .low
    case .forceLogout, .shutdown:
      return .moderate
    case .customScript:
      return .severe
    }
  }
}

extension NetworkActionType {
  public var triggerRiskLevel: TriggerRiskLevel {
    switch self {
    case .webhook, .disconnectVPN, .clearSSHAgent, .clearClipboard, .disableWiFi:
      return .moderate
    case .ejectRemovableVolumes, .unmountCryptomatorVolumes:
      return .severe
    case .disableBluetooth:
      return .moderate
    }
  }
}

extension OperationProfile {
  /// Highest risk implied by the preset defaults (not custom tweaks).
  public var presetRiskLevel: TriggerRiskLevel {
    switch selectable {
    case .beginner, .discreet:
      return .low
    case .normal:
      return .low
    case .panic:
      return .moderate
    case .custom:
      return .low
    }
  }
}

extension ProtectionMode {
  public var triggerRiskLevel: TriggerRiskLevel {
    switch self {
    case .normal:
      return .low
    case .panic, .paranoid:
      return .severe
    }
  }
}

// MARK: - Aggregated assessment

public enum TriggerRiskAssessor {

  public static func maxRisk(for securityActions: [SecurityActionType]) -> TriggerRiskLevel {
    securityActions.map(\.triggerRiskLevel).max() ?? .low
  }

  public static func maxRisk(for networkActions: [NetworkActionType]) -> TriggerRiskLevel {
    networkActions.map(\.triggerRiskLevel).max() ?? .low
  }

  /// Highest risk from configured settings (security + network + scripts + grace posture).
  public static func maxConfiguredRisk(in settings: Settings) -> TriggerRiskLevel {
    var level = max(
      maxRisk(for: settings.securityActions),
      maxRisk(for: settings.enabledNetworkActions)
    )

    if !settings.customScripts.isEmpty {
      level = max(level, .severe)
    }

    if settings.operationProfile.selectable == .panic {
      level = max(level, .moderate)
    }

    if !settings.allowGracePeriodCancellation {
      level = max(level, .moderate)
    }

    return level
  }

  public static func hasDestructiveSecurityActions(in settings: Settings) -> Bool {
    settings.securityActions.contains { $0.triggerRiskLevel >= .moderate }
  }
}

// MARK: - CLI status file (shared with magsafeguard-cli)

public enum CLIIPC {
  public static let commandNotification = Notification.Name("com.sutz2001.MagSafeGuard.cli.command")
  public static let responseNotification = Notification.Name("com.sutz2001.MagSafeGuard.cli.response")

  public static let statusFileName = "cli-status.json"

  public static func applicationSupportDirectory() -> URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("MagSafeGuard", isDirectory: true)
  }

  public static func statusFileURL() -> URL {
    applicationSupportDirectory().appendingPathComponent(statusFileName)
  }
}

public struct CLIStatusSnapshot: Codable, Sendable, Equatable {
  public var appState: String
  public var protectionMode: String
  public var operationProfile: String
  public var maxConfiguredRisk: String
  public var marketingVersion: String
  public var updatedAt: Date

  public init(
    appState: String,
    protectionMode: String,
    operationProfile: String,
    maxConfiguredRisk: String,
    marketingVersion: String,
    updatedAt: Date = Date()
  ) {
    self.appState = appState
    self.protectionMode = protectionMode
    self.operationProfile = operationProfile
    self.maxConfiguredRisk = maxConfiguredRisk
    self.marketingVersion = marketingVersion
    self.updatedAt = updatedAt
  }
}
