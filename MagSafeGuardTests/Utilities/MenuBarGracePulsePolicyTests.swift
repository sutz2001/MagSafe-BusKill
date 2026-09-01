//
//  MenuBarGracePulsePolicyTests.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import XCTest

@testable import MagSafeGuard

final class MenuBarGracePulsePolicyTests: XCTestCase {

  func testNoPulseWhenSecurityAlertsEnabled() {
    XCTAssertFalse(
      MenuBarGracePulsePolicy.shouldPulse(
        isInGracePeriod: true,
        showSecurityAlerts: true,
        graceRemaining: 5,
        protectionMode: .normal
      )
    )
  }

  func testNoPulseOutsideGracePeriod() {
    XCTAssertFalse(
      MenuBarGracePulsePolicy.shouldPulse(
        isInGracePeriod: false,
        showSecurityAlerts: false,
        graceRemaining: 5,
        protectionMode: .normal
      )
    )
  }

  func testNormalModePulsesOnlyInLastTenSeconds() {
    XCTAssertFalse(
      MenuBarGracePulsePolicy.shouldPulse(
        isInGracePeriod: true,
        showSecurityAlerts: false,
        graceRemaining: 11,
        protectionMode: .normal
      )
    )
    XCTAssertTrue(
      MenuBarGracePulsePolicy.shouldPulse(
        isInGracePeriod: true,
        showSecurityAlerts: false,
        graceRemaining: 10,
        protectionMode: .normal
      )
    )
  }

  func testPanicModePulsesInLastFiveSeconds() {
    XCTAssertFalse(
      MenuBarGracePulsePolicy.shouldPulse(
        isInGracePeriod: true,
        showSecurityAlerts: false,
        graceRemaining: 6,
        protectionMode: .panic
      )
    )
    XCTAssertTrue(
      MenuBarGracePulsePolicy.shouldPulse(
        isInGracePeriod: true,
        showSecurityAlerts: false,
        graceRemaining: 5,
        protectionMode: .panic
      )
    )
  }
}
