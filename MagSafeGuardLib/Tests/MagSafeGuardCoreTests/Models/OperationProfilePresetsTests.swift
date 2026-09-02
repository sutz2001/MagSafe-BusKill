//
//  OperationProfilePresetsTests.swift
//  MagSafe Guard
//

import XCTest

@testable import MagSafeGuardCore
@testable import MagSafeGuardDomain

final class OperationProfilePresetsTests: XCTestCase {

  func testApplyBeginnerPreset() {
    var settings = Settings()
    OperationProfilePresets.apply(.beginner, to: &settings)

    XCTAssertEqual(settings.operationProfile, .beginner)
    XCTAssertEqual(settings.gracePeriodDuration, 30)
    XCTAssertTrue(settings.allowGracePeriodCancellation)
    XCTAssertEqual(settings.securityActions, [.lockScreen])
    XCTAssertTrue(settings.showStatusNotifications)
    XCTAssertEqual(OperationProfilePresets.detect(from: settings), .beginner)
  }

  func testApplyNormalPreset() {
    var settings = Settings()
    OperationProfilePresets.apply(.normal, to: &settings)

    XCTAssertEqual(settings.operationProfile, .normal)
    XCTAssertTrue(settings.showStatusNotifications)
    XCTAssertTrue(settings.showSecurityAlerts)
    XCTAssertTrue(settings.playCriticalAlertSound)
    XCTAssertEqual(settings.securityActions, [.lockScreen, .soundAlarm])
    XCTAssertEqual(OperationProfilePresets.detect(from: settings), .normal)
  }

  func testApplyDiscreetPresetHidesDock() {
    var settings = Settings()
    settings.showInDock = true
    OperationProfilePresets.apply(.discreet, to: &settings)

    XCTAssertEqual(settings.operationProfile, .discreet)
    XCTAssertFalse(settings.showInDock)
    XCTAssertEqual(settings.securityActions, [.lockScreen])
    XCTAssertTrue(settings.isDiscreetOperation)
    XCTAssertEqual(OperationProfilePresets.detect(from: settings), .discreet)
  }

  func testApplyPanicPreset() {
    var settings = Settings()
    OperationProfilePresets.apply(.panic, to: &settings)

    XCTAssertEqual(settings.operationProfile, .panic)
    XCTAssertEqual(settings.gracePeriodDuration, 5)
    XCTAssertFalse(settings.allowGracePeriodCancellation)
    XCTAssertFalse(settings.showStatusNotifications)
    XCTAssertFalse(settings.showSecurityAlerts)
    XCTAssertFalse(settings.playCriticalAlertSound)
    XCTAssertEqual(settings.securityActions, [.lockScreen, .forceLogout])
    XCTAssertEqual(
      settings.enabledNetworkActions.sorted { $0.rawValue < $1.rawValue },
      OperationProfilePresets.panicNetworkActions.sorted { $0.rawValue < $1.rawValue }
    )
    XCTAssertTrue(settings.enabledNetworkActions.contains(.clearClipboard))
    XCTAssertFalse(settings.showInDock)
    XCTAssertEqual(OperationProfilePresets.detect(from: settings), .panic)
  }

  func testParanoidNetworkActionsMatchPanicBaseline() {
    XCTAssertEqual(
      OperationProfilePresets.paranoidNetworkActions.sorted { $0.rawValue < $1.rawValue },
      OperationProfilePresets.panicNetworkActions.sorted { $0.rawValue < $1.rawValue }
    )
  }

  func testDetectCustomWhenGraceChanged() {
    var settings = Settings()
    OperationProfilePresets.apply(.normal, to: &settings)
    settings.gracePeriodDuration = 15

    XCTAssertFalse(OperationProfilePresets.isUsingDefaults(for: .normal, settings: settings))
    XCTAssertEqual(OperationProfilePresets.detect(from: settings), .custom)
  }

  func testDetectCustomWhenDockEnabledInDiscreet() {
    var settings = Settings()
    OperationProfilePresets.apply(.discreet, to: &settings)
    settings.showInDock = true

    XCTAssertEqual(OperationProfilePresets.detect(from: settings), .custom)
  }

  func testDockHiddenWhenPanicArmedRegardlessOfSetting() {
    var settings = Settings()
    settings.showInDock = true

    XCTAssertFalse(DockVisibilityPolicy.shouldShowInDock(settings: settings, protectionMode: .panic))
    XCTAssertFalse(DockVisibilityPolicy.shouldShowInDock(settings: settings, protectionMode: .paranoid))
    XCTAssertTrue(DockVisibilityPolicy.shouldShowInDock(settings: settings, protectionMode: .normal))
  }

  func testDockRespectsSettingWhenNormalArmed() {
    var settings = Settings()
    settings.showInDock = false
    XCTAssertFalse(DockVisibilityPolicy.shouldShowInDock(settings: settings, protectionMode: .normal))

    settings.showInDock = true
    XCTAssertTrue(DockVisibilityPolicy.shouldShowInDock(settings: settings, protectionMode: .normal))
  }
}
