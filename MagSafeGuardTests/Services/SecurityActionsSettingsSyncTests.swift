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
      [.soundAlarm, .lockScreen, .forceLogout])
    XCTAssertEqual(
      service.configuration.enabledActions,
      Set([.soundAlarm, .lockScreen, .forceLogout]))
  }

  func testSyncMapsAlarmVolumeSettings() {
    var settings = Settings()
    settings.alarmVolume = 0.75
    settings.boostSystemVolumeForAlarm = false
    settings.securityActions = [.soundAlarm]

    SecurityActionsSettingsSync.sync(from: settings, to: service)

    XCTAssertEqual(service.configuration.alarmVolume, 0.75, accuracy: 0.001)
    XCTAssertFalse(service.configuration.boostSystemVolumeForAlarm)
    XCTAssertEqual(service.configuration.alarmDurationSeconds, 15)
  }

  func testSyncMapsAlarmDuration() {
    var settings = Settings()
    settings.securityActions = [.soundAlarm]
    settings.alarmDurationSeconds = 0

    SecurityActionsSettingsSync.sync(from: settings, to: service)

    XCTAssertEqual(service.configuration.alarmDurationSeconds, 0)
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
