//
//  ProtectionMode.swift
//  MagSafeGuardCore
//

import Foundation

/// High-assurance protection profile when the system is armed.
public enum ProtectionMode: String, Codable, Sendable, Equatable {
  /// Standard armed mode (grace period, configurable actions).
  case normal
  /// Panic mode — zero grace, immediate lock/logout/shutdown on cable pull.
  case panic
  /// Paranoid mode (v0.6) — data destruction then hard shutdown when armed.
  case paranoid

  /// When armed in panic or paranoid, the Dock icon stays hidden regardless of settings.
  public var forcesHiddenDock: Bool {
    switch self {
    case .normal: return false
    case .panic, .paranoid: return true
    }
  }
}
