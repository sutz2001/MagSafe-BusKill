//
//  AppLanguage.swift
//  MagSafe Guard
//
//  Supported app language preferences. "system" follows macOS language settings.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
  case system
  case english = "en"
  case german = "de"

  var id: String { rawValue }

  /// Localization key for the picker label (shown in the active UI language).
  var displayNameKey: String {
    switch self {
    case .system: return "settings.language.system"
    case .english: return "settings.language.english"
    case .german: return "settings.language.german"
    }
  }

  static func from(storedValue: String?) -> AppLanguage {
    guard let storedValue, let language = AppLanguage(rawValue: storedValue) else {
      return .system
    }
    return language
  }
}

extension Notification.Name {
  static let appLanguageDidChange = Notification.Name("AppLanguageDidChange")
}
