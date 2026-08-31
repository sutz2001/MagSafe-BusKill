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

  static func apply(_ settings: Settings) {
    SecurityActionsSettingsSync.sync(from: settings)
    applyLaunchAtLogin(settings.launchAtLogin)
    Log.isDebugLoggingEnabled = settings.debugLoggingEnabled
    applyDockVisibility(showInDock: settings.showInDock)
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

  static func applyDockVisibility(showInDock: Bool) {
    guard !ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath") else {
      return
    }

    let settingsWindowOpen = NSApp.windows.contains {
      $0.title == L10n.tr("app.settingsWindow") && $0.isVisible
    }
    guard !settingsWindowOpen else { return }

    NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
  }
}
