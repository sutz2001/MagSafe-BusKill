//
//  MenuBarIconHelper.swift
//  MagSafe Guard
//

import AppKit
import MagSafeGuardCore

/// Prepares menu bar status item images (monochrome template or subtle accent tints).
enum MenuBarIconHelper {
  private static let menuBarPointSize = NSSize(width: 18, height: 18)

  /// Visual state used for accent tint selection (maps from `AppState`).
  enum VisualState {
    case disarmed
    case armed
    case gracePeriod
    case triggered
  }

  static func symbolImage(
    named symbolName: String,
    appearance: MenuBarIconAppearance,
    state: VisualState
  ) -> NSImage? {
    let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
    guard
      let base = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
        .withSymbolConfiguration(configuration)
    else {
      return nil
    }
    return preparedImage(from: base, appearance: appearance, state: state)
  }

  static func assetImage(
    named assetName: String,
    appearance: MenuBarIconAppearance,
    state: VisualState
  ) -> NSImage? {
    guard let base = NSImage(named: assetName) else { return nil }
    return preparedImage(from: base, appearance: appearance, state: state)
  }

  /// Tint for `NSStatusBarButton.contentTintColor`; `nil` = system monochrome.
  /// Accent colors are baked into the image in `preparedImage` for reliable status-bar rendering.
  static func contentTint(for appearance: MenuBarIconAppearance, state: VisualState) -> NSColor? {
    nil
  }

  static func accentTint(for state: VisualState) -> NSColor {
    switch state {
    case .disarmed:
      return NSColor(srgbRed: 0.55, green: 0.58, blue: 0.64, alpha: 1)
    case .armed:
      return NSColor(srgbRed: 0.35, green: 0.55, blue: 0.82, alpha: 1)
    case .gracePeriod:
      return NSColor(srgbRed: 0.78, green: 0.62, blue: 0.22, alpha: 1)
    case .triggered:
      return NSColor(srgbRed: 0.78, green: 0.35, blue: 0.35, alpha: 1)
    }
  }

  private static func preparedImage(
    from image: NSImage,
    appearance: MenuBarIconAppearance,
    state: VisualState
  ) -> NSImage {
    let copy = (image.copy() as? NSImage) ?? image
    copy.size = menuBarPointSize

    switch appearance {
    case .monochrome:
      copy.isTemplate = true
      return copy
    case .accent:
      copy.isTemplate = true
      return tintedImage(copy, color: accentTint(for: state))
    }
  }

  private static func tintedImage(_ image: NSImage, color: NSColor) -> NSImage {
    let size = image.size
    let tinted = NSImage(size: size)
    tinted.lockFocus()
    color.setFill()
    NSRect(origin: .zero, size: size).fill()
    image.draw(
      in: NSRect(origin: .zero, size: size),
      from: NSRect(origin: .zero, size: size),
      operation: .destinationIn,
      fraction: 1.0
    )
    tinted.unlockFocus()
    tinted.isTemplate = false
    tinted.size = menuBarPointSize
    return tinted
  }
}
