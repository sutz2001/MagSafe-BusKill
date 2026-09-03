//
//  SecurityActionExecutionContext.swift
//  MagSafe Guard
//

import Foundation

/// Controls rate limits, ordering, and shutdown behaviour for security action runs.
public enum SecurityActionExecutionContext: Equatable, Sendable {
  /// Manual / settings-driven execution (rate limits and circuit breaker apply).
  case standard
  /// Cable disconnect or remote `trigger` (protection-first, no rate limit).
  case theftTrigger
  /// Panic mode (protection-first, immediate shutdown).
  case panic
  /// Paranoid mode (protection-first, immediate shutdown, destruction runs in parallel).
  case paranoid

  var usesProtectionFirstPath: Bool {
    switch self {
    case .theftTrigger, .panic, .paranoid: return true
    case .standard: return false
    }
  }

  var runsTriggerScripts: Bool {
    switch self {
    case .theftTrigger, .panic, .paranoid: return true
    case .standard: return false
    }
  }

  var forcesImmediateShutdown: Bool {
    switch self {
    case .panic, .paranoid: return true
    case .standard, .theftTrigger: return false
    }
  }
}
