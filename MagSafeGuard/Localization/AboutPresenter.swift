//
//  AboutPresenter.swift
//  MagSafe Guard
//
//  Presents the standard macOS About panel (icon, version, copyright, Credits).
//

import AppKit
import MagSafeGuardCore

enum AboutPresenter {
  @MainActor
  static func show() {
    if NSApp.applicationIconImage == nil {
      NSApp.applicationIconImage = NSImage(named: "AppIcon")
    }

    NSApp.activate(ignoringOtherApps: true)

    var options: [NSApplication.AboutPanelOptionKey: Any] = [
      .applicationName: L10n.tr("app.name"),
      .applicationVersion: AppVersion.full,
      .credits: creditsAttributedString(),
    ]

    NSApp.orderFrontStandardAboutPanel(options: options)
  }

  private static func creditsAttributedString() -> NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = 3
    paragraph.paragraphSpacing = 8

    let body = L10n.tr("about.credits.body")
    return NSAttributedString(
      string: body,
      attributes: [
        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
        .foregroundColor: NSColor.labelColor,
        .paragraphStyle: paragraph,
      ]
    )
  }
}
