//
//  SecurityActionsSettingsSyncTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
import MagSafeGuardCore
import MagSafeGuardDomain
import XCTest

final class SecurityActionsSettingsSyncTests: XCTestCase {

  private var mockSystemActions: MockSystemActions!
  private var service: SecurityActionsService!

  override func setUp() {
    super.setUp()
    mockSystemActions = MockSystemActions()
    service = SecurityActionsService(systemActions: mockSystemActions)
    service.resetToDefault()
  }

  func testSyncPreservesSettingsActionOrder() {
    var settings = Settings()
    settings.securityActions = [.soundAlarm, .lockScreen, .forceLogout]

    SecurityActionsSettingsSync.sync(from: settings, to: service)

    XCTAssertEqual(
      service.configuration.actionOrder,
      [.soundAlarm, .screenLock, .forceLogout])
    XCTAssertEqual(
      service.configuration.enabledActions,
      Set([.soundAlarm, .screenLock, .forceLogout]))
  }

  func testSyncMapsCustomScriptPaths() {
    var settings = Settings()
    settings.securityActions = [.lockScreen, .customScript]
    settings.customScripts = ["/usr/local/magsafe-scripts/a.sh", "/usr/local/magsafe-scripts/b.sh"]

    SecurityActionsSettingsSync.sync(from: settings, to: service)

    XCTAssertEqual(
      service.configuration.customScriptPaths,
      ["/usr/local/magsafe-scripts/a.sh", "/usr/local/magsafe-scripts/b.sh"])
    XCTAssertEqual(service.configuration.customScriptPath, "/usr/local/magsafe-scripts/a.sh")
  }
}
