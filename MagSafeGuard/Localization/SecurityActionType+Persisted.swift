//
//  SecurityActionType+Persisted.swift
//  MagSafe Guard
//

import MagSafeGuardDomain

extension SecurityActionType {
  /// Decode legacy service-layer raw values (`screen_lock`) and domain values (`lock_screen`).
  init?(persistedRawValue: String) {
    let normalized = persistedRawValue == "screen_lock" ? Self.lockScreen.rawValue : persistedRawValue
    self.init(rawValue: normalized)
  }
}
