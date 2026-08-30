//
//  LanguageManager.swift
//  MagSafe Guard
//
//  Persists manual language override. Default: follow macOS system language.
//

import Combine
import Foundation

@MainActor
final class LanguageManager: ObservableObject {
  static let shared = LanguageManager()

  private static let userDefaultsKey = "com.sutz2001.MagSafeGuard.appLanguage"

  @Published private(set) var preference: AppLanguage

  private init() {
    let stored = UserDefaults.standard.string(forKey: Self.userDefaultsKey)
    preference = AppLanguage.from(storedValue: stored)
  }

  /// Apply a language preference and refresh UI (menu bar, settings).
  func setPreference(_ language: AppLanguage) {
    guard preference != language else { return }
    preference = language
    UserDefaults.standard.set(language.rawValue, forKey: Self.userDefaultsKey)
    NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
  }

  /// Bundle used for `Localizable.strings` lookups.
  nonisolated static var localizationBundle: Bundle {
    let stored = UserDefaults.standard.string(forKey: userDefaultsKey)
    let preference = AppLanguage.from(storedValue: stored)

    switch preference {
    case .system:
      return .main
    case .english, .german:
      guard let path = Bundle.main.path(forResource: preference.rawValue, ofType: "lproj"),
        let bundle = Bundle(path: path)
      else {
        return .main
      }
      return bundle
    }
  }

  /// Locale for `String(format:)` with translated format strings.
  nonisolated static var formattingLocale: Locale {
    let stored = UserDefaults.standard.string(forKey: userDefaultsKey)
    let preference = AppLanguage.from(storedValue: stored)

    switch preference {
    case .system:
      return .current
    case .english:
      return Locale(identifier: "en")
    case .german:
      return Locale(identifier: "de")
    }
  }
}
