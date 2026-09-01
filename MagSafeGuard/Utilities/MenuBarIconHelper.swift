//
//  MenuBarIconHelper.swift
//  MagSafe Guard
//

import AppKit

/// Prepares consistently sized template images for the menu bar status item.
enum MenuBarIconHelper {
  private static let menuBarPointSize = NSSize(width: 18, height: 18)

  static func symbolImage(named symbolName: String) -> NSImage? {
    let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
    guard
      let base = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
        .withSymbolConfiguration(configuration)
    else {
      return nil
    }
    return templateImage(from: base)
  }

  static func assetImage(named assetName: String) -> NSImage? {
    guard let base = NSImage(named: assetName) else { return nil }
    return templateImage(from: base)
  }

  private static func templateImage(from image: NSImage) -> NSImage {
    let copy = (image.copy() as? NSImage) ?? image
    copy.isTemplate = true
    copy.size = menuBarPointSize
    return copy
  }
}
