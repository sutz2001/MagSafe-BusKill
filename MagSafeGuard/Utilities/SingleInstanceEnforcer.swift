//
//  SingleInstanceEnforcer.swift
//  MagSafe Guard
//

import AppKit
import Foundation
import MagSafeGuardCore

/// Ensures only one MagSafe Guard process runs per bundle identifier (new launch wins).
enum SingleInstanceEnforcer {

  /// Terminates other running app instances with the same bundle ID. Returns how many were asked to quit.
  @discardableResult
  static func terminateOtherInstances(bundleIdentifier: String? = Bundle.main.bundleIdentifier) -> Int {
    guard !isTestEnvironment else { return 0 }
    guard let bundleIdentifier, !bundleIdentifier.isEmpty else { return 0 }

    let current = NSRunningApplication.current
    let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
      .filter { $0 != current }

    var terminated = 0
    for app in others {
      if app.terminate() {
        terminated += 1
      } else {
        app.forceTerminate()
        terminated += 1
      }
    }

    if terminated > 0 {
      Log.info(
        "Terminated \(terminated) other MagSafe Guard instance(s) — only one may run",
        category: .general
      )
    }
    return terminated
  }

  private static var isTestEnvironment: Bool {
    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
      || ProcessInfo.processInfo.environment["MAGSAFE_GUARD_TEST_MODE"] != nil
      || ProcessInfo.processInfo.arguments.contains("-SenTest")
      || Bundle.main.bundlePath.hasSuffix(".xctest")
  }
}
