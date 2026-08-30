//
//  ApplicationStatePersistence.swift
//  MagSafe Guard
//
//  Persists whether protection was armed across app restarts (optional).
//

import Foundation

enum ApplicationStatePersistence {
  private static let wasArmedKey = "com.sutz2001.MagSafeGuard.persistedWasArmed"

  static func saveWasArmed(_ wasArmed: Bool) {
    UserDefaults.standard.set(wasArmed, forKey: wasArmedKey)
  }

  static func loadWasArmed() -> Bool {
    UserDefaults.standard.bool(forKey: wasArmedKey)
  }

  static func clear() {
    UserDefaults.standard.removeObject(forKey: wasArmedKey)
  }
}
