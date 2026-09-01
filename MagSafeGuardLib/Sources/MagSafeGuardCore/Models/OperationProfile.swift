//
//  OperationProfile.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardDomain

/// User-facing operation presets (Normal, Discreet, Panic).
public enum OperationProfile: String, Codable, CaseIterable, Sendable, Equatable {
  case normal
  case discreet
  case panic
  /// Legacy persisted value — normalized to `.normal` on load.
  case custom

  public static let selectableCases: [OperationProfile] = [.normal, .discreet, .panic]

  /// User-selectable profile; maps legacy `.custom` to `.normal`.
  public var selectable: OperationProfile {
    switch self {
    case .custom: return .normal
    case .normal, .discreet, .panic: return self
    }
  }
}

/// Resolves whether the app should appear in the Dock given settings and armed protection mode.
public enum DockVisibilityPolicy {
  public static func shouldShowInDock(settings: Settings, protectionMode: ProtectionMode) -> Bool {
    guard !protectionMode.forcesHiddenDock else { return false }
    return settings.showInDock
  }
}

/// Applies and detects operation-profile presets for notification, grace, and security-action defaults.
public enum OperationProfilePresets {

  /// Network actions for panic and paranoid (no Wi‑Fi off — keeps Find My; webhook is user-specific).
  public static let highAssuranceNetworkActions: [NetworkActionType] = [
    .disconnectVPN, .clearSSHAgent, .clearClipboard,
  ]

  /// Network actions enabled by the Panic operation preset.
  public static let panicNetworkActions: [NetworkActionType] = highAssuranceNetworkActions

  /// Network actions for paranoid protection mode (v0.6+); same baseline as panic today.
  public static let paranoidNetworkActions: [NetworkActionType] = highAssuranceNetworkActions

  public static func apply(_ profile: OperationProfile, to settings: inout Settings) {
    switch profile {
    case .normal:
      settings.showStatusNotifications = true
      settings.showSecurityAlerts = true
      settings.playCriticalAlertSound = true
      settings.gracePeriodDuration = 30
      settings.allowGracePeriodCancellation = true
      settings.securityActions = [.lockScreen, .soundAlarm]
      settings.enabledNetworkActions = []
    case .discreet:
      settings.showStatusNotifications = false
      settings.showSecurityAlerts = false
      settings.playCriticalAlertSound = false
      settings.showInDock = false
      settings.gracePeriodDuration = 20
      settings.allowGracePeriodCancellation = true
      settings.securityActions = [.lockScreen]
      settings.enabledNetworkActions = []
    case .panic:
      settings.showStatusNotifications = false
      settings.showSecurityAlerts = false
      settings.playCriticalAlertSound = false
      settings.showInDock = false
      settings.gracePeriodDuration = 5
      settings.allowGracePeriodCancellation = false
      settings.securityActions = [.lockScreen, .forceLogout]
      settings.enabledNetworkActions = panicNetworkActions
    case .custom:
      break
    }

    if profile != .custom {
      settings.operationProfile = profile
    }
  }

  /// Whether `settings` still matches the factory defaults for `profile`.
  public static func isUsingDefaults(for profile: OperationProfile, settings: Settings) -> Bool {
    let profile = profile.selectable
    return matches(profile, settings)
  }

  /// Legacy helper for migration — prefer `settings.operationProfile` + `isUsingDefaults`.
  public static func detect(from settings: Settings) -> OperationProfile {
    if matches(.panic, settings) { return .panic }
    if matches(.discreet, settings) { return .discreet }
    if matches(.normal, settings) { return .normal }
    return .custom
  }

  private static func matches(_ profile: OperationProfile, _ settings: Settings) -> Bool {
    var expected = Settings()
    apply(profile, to: &expected)
    guard behaviorFingerprint(settings) == behaviorFingerprint(expected) else { return false }
    switch profile {
    case .discreet, .panic:
      return !settings.showInDock
    case .normal, .custom:
      return true
    }
  }

  private static func behaviorFingerprint(_ settings: Settings) -> BehaviorFingerprint {
    BehaviorFingerprint(
      showStatusNotifications: settings.showStatusNotifications,
      showSecurityAlerts: settings.showSecurityAlerts,
      playCriticalAlertSound: settings.playCriticalAlertSound,
      gracePeriodDuration: settings.gracePeriodDuration,
      allowGracePeriodCancellation: settings.allowGracePeriodCancellation,
      securityActions: settings.securityActions,
      enabledNetworkActions: settings.enabledNetworkActions.sorted { $0.rawValue < $1.rawValue }
    )
  }
}

private struct BehaviorFingerprint: Equatable {
  let showStatusNotifications: Bool
  let showSecurityAlerts: Bool
  let playCriticalAlertSound: Bool
  let gracePeriodDuration: TimeInterval
  let allowGracePeriodCancellation: Bool
  let securityActions: [SecurityActionType]
  let enabledNetworkActions: [NetworkActionType]
}
