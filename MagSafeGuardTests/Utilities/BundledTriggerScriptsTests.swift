//
//  BundledTriggerScriptsTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
import XCTest

final class BundledTriggerScriptsTests: XCTestCase {

  private var tempHome: URL!
  private var tempSources: URL!

  override func setUpWithError() throws {
    tempHome = FileManager.default.temporaryDirectory
      .appendingPathComponent("magsafe-home-\(UUID().uuidString)", isDirectory: true)
    tempSources = FileManager.default.temporaryDirectory
      .appendingPathComponent("magsafe-src-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: tempHome, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: tempSources, withIntermediateDirectories: true)
    try "#!/bin/bash\necho ok".write(
      to: tempSources.appendingPathComponent("sample.sh"),
      atomically: true,
      encoding: .utf8
    )
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: tempHome)
    try? FileManager.default.removeItem(at: tempSources)
  }

  func testInstallScriptsSetsPermissions() throws {
    let destination = tempHome.appendingPathComponent(".magsafe/scripts", isDirectory: true)
    let result = try BundledTriggerScripts.installScripts(
      from: [tempSources.appendingPathComponent("sample.sh")],
      to: destination
    )

    XCTAssertEqual(result.copiedCount, 1)
    let attrs = try FileManager.default.attributesOfItem(atPath: result.installedPaths[0])
    let perms = (attrs[.posixPermissions] as? NSNumber)?.intValue ?? 0
    XCTAssertEqual(perms & 0o777, 0o700)
  }

  func testRegisterInstalledPathsInSettingsAppendsAndEnablesCustomScript() {
    let suiteName = "magsafe-test-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    addTeardownBlock { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    let manager = UserDefaultsManager(userDefaults: defaults)
    manager.updateSettings { settings in
      settings.customScripts = ["/existing/script.sh"]
      settings.securityActions = [.lockScreen]
    }

    BundledTriggerScripts.registerInstalledPathsInSettings(
      ["/existing/script.sh", "/new/script.sh"],
      settingsManager: manager
    )

    XCTAssertEqual(manager.settings.customScripts, ["/existing/script.sh", "/new/script.sh"])
    XCTAssertTrue(manager.settings.securityActions.contains(.customScript))
    XCTAssertTrue(manager.settings.securityActions.contains(.lockScreen))
  }

  func testBundledScriptsInAppBundleArePresent() {
    let scripts = BundledTriggerScripts.bundledScriptURLs()
    XCTAssertFalse(scripts.isEmpty, "Expected installable TriggerScripts in the app bundle")
    XCTAssertTrue(scripts.contains { $0.lastPathComponent == "quit-browsers.sh" })
    XCTAssertFalse(scripts.contains { $0.lastPathComponent == "clear-clipboard.sh" })
    XCTAssertFalse(scripts.contains { $0.lastPathComponent == "eject-removable-volumes.sh" })
  }

  func testOutdatedScriptsExcludedFromInstallableList() {
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("magsafe-bundle-\(UUID().uuidString)", isDirectory: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: tempDir) }
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    let filtered = BundledTriggerScripts.installableScriptURLs(from: [
      tempDir.appendingPathComponent("quit-browsers.sh"),
      tempDir.appendingPathComponent("clear-clipboard.sh"),
      tempDir.appendingPathComponent("eject-removable-volumes.sh"),
    ])
    XCTAssertEqual(filtered.map(\.lastPathComponent), ["quit-browsers.sh"])
  }
}
