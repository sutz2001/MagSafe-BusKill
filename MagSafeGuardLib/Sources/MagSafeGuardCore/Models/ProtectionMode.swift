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
}
