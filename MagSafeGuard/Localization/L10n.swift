//
//  L10n.swift
//  MagSafe Guard
//
//  Central localization helper. String tables live in:
//    MagSafeGuard/<language>.lproj/Localizable.strings
//    MagSafeGuard/<language>.lproj/InfoPlist.strings
//
//  Default: macOS system language. Override via Settings → General → Language.
//

import Foundation
import SwiftUI

enum L10n {
  private static let table = "Localizable"

  /// Localized string for the active language (system or manual override).
  static func tr(_ key: String) -> String {
    NSLocalizedString(
      key,
      tableName: table,
      bundle: LanguageManager.localizationBundle,
      value: key,
      comment: ""
    )
  }

  /// Localized string with format arguments (`%@`, `%d`, `%lld`, etc.).
  static func tr(_ key: String, _ arguments: CVarArg...) -> String {
    let format = tr(key)
    return String(format: format, locale: LanguageManager.formattingLocale, arguments: arguments)
  }
}

extension Text {
  init(l10n key: String) {
    self.init(L10n.tr(key))
  }
}

extension String {
  init(l10n key: String) {
    self = L10n.tr(key)
  }
}
