//
//  GracePeriodAlertPresenter.swift
//  MagSafe Guard
//

import AppKit
import MagSafeGuardCore

/// Non-blocking grace-period dialog (sheet). Unlike `NSAlert.runModal()`, this does not freeze the run loop.
enum GracePeriodAlertPresenter {

  private static var hostWindow: NSWindow?
  private static var isShowing = false

  static func show(title: String, message: String) {
    DispatchQueue.main.async {
      guard !isShowing else { return }
      isShowing = true

      let alert = NSAlert()
      alert.messageText = title
      alert.informativeText = message
      alert.alertStyle = .critical
      alert.addButton(withTitle: L10n.tr("common.ok"))

      if UserDefaultsManager.shared.settings.allowGracePeriodCancellation {
        alert.addButton(withTitle: L10n.tr("notification.cancelAction"))
      }

      let window = ensureHostWindow()
      NSApp.activate(ignoringOtherApps: true)
      alert.beginSheetModal(for: window) { response in
        isShowing = false
        if response == .alertSecondButtonReturn {
          NotificationCenter.default.post(
            name: Notification.Name("MagSafeGuard.CancelGracePeriod"),
            object: nil
          )
        }
      }
    }
  }

  static func dismiss() {
    DispatchQueue.main.async {
      if let window = hostWindow, let sheet = window.attachedSheet {
        window.endSheet(sheet)
      }
      isShowing = false
    }
  }

  private static func ensureHostWindow() -> NSWindow {
    let window: NSWindow
    if let hostWindow {
      window = hostWindow
    } else {
      window = NSWindow(
        contentRect: centeredHostFrame(),
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
      )
      window.isReleasedWhenClosed = false
      window.alphaValue = 0
      window.level = .floating
      window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
      hostWindow = window
    }

    window.setFrame(centeredHostFrame(), display: true)
    window.makeKeyAndOrderFront(nil)
    return window
  }

  /// Invisible anchor window centered on the main screen so the sheet appears in the middle.
  private static func centeredHostFrame() -> NSRect {
    let size = NSSize(width: 120, height: 120)
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
    return NSRect(
      x: screenFrame.midX - size.width / 2,
      y: screenFrame.midY - size.height / 2,
      width: size.width,
      height: size.height
    )
  }
}
