//
//  HygienePhasePolicyTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
import MagSafeGuardCore
import XCTest

final class HygienePhasePolicyTests: XCTestCase {

  func testOrderedActionsPrioritizeClipboardAndSSH() {
    let order = HygienePhasePolicy.orderedActions
    XCTAssertEqual(order.first, .clearClipboard)
    XCTAssertEqual(order[1], .clearSSHAgent)
    XCTAssertTrue(order.firstIndex(of: .webhook)! > order.firstIndex(of: .clearSSHAgent)!)
    XCTAssertTrue(order.firstIndex(of: .disconnectVPN)! > order.firstIndex(of: .webhook)!)
  }

  func testMaxDurationIsTwoSeconds() {
    XCTAssertEqual(HygienePhasePolicy.maxDuration, 2.0)
  }
}
