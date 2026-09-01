//
//  MenuBarIconAppearance.swift
//  MagSafe Guard
//

import Foundation

/// Menu bar icon coloring: system monochrome (default) or subtle state accents.
public enum MenuBarIconAppearance: String, Codable, CaseIterable, Sendable {
  /// Standard macOS template icon (adapts to light/dark menu bar).
  case monochrome
  /// Template icon with a soft tint per security state.
  case accent

  public var localizationKey: String {
    switch self {
    case .monochrome:
      return "settings.general.menuBarIcons.monochrome"
    case .accent:
      return "settings.general.menuBarIcons.accent"
    }
  }
}
