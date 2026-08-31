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
}
