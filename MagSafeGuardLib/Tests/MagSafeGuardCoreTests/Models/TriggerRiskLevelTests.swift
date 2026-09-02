//
//  TriggerRiskLevelTests.swift
//  MagSafeGuardCoreTests
//

import XCTest

@testable import MagSafeGuardCore
@testable import MagSafeGuardDomain

final class TriggerRiskLevelTests: XCTestCase {

  func testSecurityActionRiskLevels() {
    XCTAssertEqual(SecurityActionType.lockScreen.triggerRiskLevel, .low)
    XCTAssertEqual(SecurityActionType.shutdown.triggerRiskLevel, .moderate)
    XCTAssertEqual(SecurityActionType.customScript.triggerRiskLevel, .severe)
  }

  func testMaxConfiguredRiskBeginnerProfile() {
    var settings = Settings()
    OperationProfilePresets.apply(.beginner, to: &settings)
    XCTAssertEqual(TriggerRiskAssessor.maxConfiguredRisk(in: settings), .low)
  }

  func testMaxConfiguredRiskWithShutdown() {
    var settings = Settings()
    settings.securityActions = [.lockScreen, .shutdown]
    XCTAssertEqual(TriggerRiskAssessor.maxConfiguredRisk(in: settings), .moderate)
  }

  func testCustomScriptsElevateToSevere() {
    var settings = Settings()
    settings.securityActions = [.lockScreen]
    settings.customScripts = ["/tmp/wipe.sh"]
    XCTAssertEqual(TriggerRiskAssessor.maxConfiguredRisk(in: settings), .severe)
  }

  func testProtectionModePanicIsSevere() {
    XCTAssertEqual(ProtectionMode.panic.triggerRiskLevel, .severe)
  }
}
