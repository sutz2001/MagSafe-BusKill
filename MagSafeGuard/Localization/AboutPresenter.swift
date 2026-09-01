//
//  AboutPresenter.swift
//  MagSafe Guard
//
//  Presents the standard macOS About panel (icon, version, copyright, Credits).
//

import AppKit
import MagSafeGuardCore

enum AboutPresenter {
  private enum Links {
    static let forkRepository = URL(string: "https://github.com/sutz2001/MagSafe-BusKill")!
    static let upstreamRepository = URL(string: "https://github.com/lekman/magsafe-buskill")!
    static let license = URL(string: "https://github.com/sutz2001/MagSafe-BusKill/blob/main/LICENSE")!
  }

  @MainActor
  static func show() {
    if NSApp.applicationIconImage == nil {
      NSApp.applicationIconImage = NSImage(named: "AppIcon")
    }

    NSApp.activate(ignoringOtherApps: true)

    let options: [NSApplication.AboutPanelOptionKey: Any] = [
      .applicationName: L10n.tr("app.name"),
      .applicationVersion: AppVersion.marketing,
      .version: String(AppVersion.build),
      .credits: creditsAttributedString()
    ]

    NSApp.orderFrontStandardAboutPanel(options: options)
  }

  private static func creditsAttributedString() -> NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = 2
    paragraph.paragraphSpacing = 6

    let bodyAttributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
      .foregroundColor: NSColor.labelColor,
      .paragraphStyle: paragraph
    ]

    let result = NSMutableAttributedString()

    func appendLine(_ text: String) {
      if result.length > 0 {
        result.append(NSAttributedString(string: "\n", attributes: bodyAttributes))
      }
      result.append(NSAttributedString(string: text, attributes: bodyAttributes))
    }

    func appendLink(_ title: String, url: URL) {
      if result.length > 0 {
        result.append(NSAttributedString(string: "\n", attributes: bodyAttributes))
      }
      var linkAttributes = bodyAttributes
      linkAttributes[.link] = url
      linkAttributes[.foregroundColor] = NSColor.linkColor
      result.append(NSAttributedString(string: title, attributes: linkAttributes))
    }

    appendLine(L10n.tr("about.credits.title"))
    appendLine(L10n.tr("about.credits.maintainer"))
    appendLink(Links.forkRepository.absoluteString, url: Links.forkRepository)
    appendLine(L10n.tr("about.credits.upstream.label"))
    appendLink(Links.upstreamRepository.absoluteString, url: Links.upstreamRepository)

    if result.length > 0 {
      result.append(NSAttributedString(string: "\n", attributes: bodyAttributes))
    }
    result.append(NSAttributedString(string: L10n.tr("about.credits.license"), attributes: bodyAttributes))
    result.append(NSAttributedString(string: " ", attributes: bodyAttributes))
    var licenseLinkAttributes = bodyAttributes
    licenseLinkAttributes[.link] = Links.license
    licenseLinkAttributes[.foregroundColor] = NSColor.linkColor
    result.append(
      NSAttributedString(
        string: L10n.tr("about.credits.license.link"),
        attributes: licenseLinkAttributes
      )
    )

    return result
  }
}
