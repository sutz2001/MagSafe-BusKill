//
//  MagSafeGuardApp.swift
//  MagSafe Guard
//

import AppKit
import SwiftUI
import UserNotifications

@main
struct MagSafeGuardApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  init() {
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
      || ProcessInfo.processInfo.environment["MAGSAFE_GUARD_TEST_MODE"] != nil
      || ProcessInfo.processInfo.arguments.contains("-SenTest")
      || Bundle.main.bundlePath.hasSuffix(".xctest") {
      NSApplication.shared.setActivationPolicy(.prohibited)
      return
    }
  }

  var body: some Scene {
    Settings {
      EmptyView()
    }
  }
}
