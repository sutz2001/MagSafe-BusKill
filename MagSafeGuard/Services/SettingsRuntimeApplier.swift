//
//  SettingsRuntimeApplier.swift
//  MagSafe Guard
//

import AppKit
import Foundation
import MagSafeGuardCore
import ServiceManagement

/// Applies persisted settings to runtime services (login item, dock, logging, security actions).
enum SettingsRuntimeApplier {

  /// Set in `applicationDidFinishLaunching` before any dock policy changes.
  private(set) static var isApplicationReady = false

  /// Updated by `AppDelegate` when protection mode changes (panic/paranoid force Dock hidden).
  static var currentProtectionMode: ProtectionMode = .normal

  /// Set while the custom settings `NSWindow` is open — blocks dock policy from hiding it.
  static var isSettingsWindowOpen = false

  static func markApplicationReady() {
    isApplicationReady = true
  }

  static func apply(_ settings: Settings) {
    SecurityActionsSettingsSync.sync(from: settings)
    applyLaunchAtLogin(settings.launchAtLogin)
    Log.isDebugLoggingEnabled = settings.debugLoggingEnabled
    // Dock visibility must not run here — UserDefaultsManager.init runs before NSApp is ready.
  }

  /// Applies dock / activation policy from settings and current protection mode.
  static func applyDockVisibility(settings: Settings) {
    applyDockVisibility(
      showInDock: DockVisibilityPolicy.shouldShowInDock(
        settings: settings,
        protectionMode: currentProtectionMode
      )
    )
  }

  /// Applies dock / activation policy. Safe to call only after `applicationDidFinishLaunching`.
  private static func applyDockVisibility(showInDock: Bool) {
    guard isApplicationReady else { return }
    guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
      return
    }

    let update = {
      if isSettingsWindowOpen {
        return
      }

      let settingsWindowOpen = NSApp.windows.contains {
        $0.title == L10n.tr("app.settingsWindow") && $0.isVisible
      }
      guard !settingsWindowOpen else { return }

      NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }

    if Thread.isMainThread {
      update()
    } else {
      DispatchQueue.main.async(execute: update)
    }
  }

  static func applyLaunchAtLogin(_ enabled: Bool) {
    guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
    guard #available(macOS 13.0, *) else { return }
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
    } catch {
      Log.error("Failed to update launch at login", error: error, category: .settings)
    }
  }
}
