//
//  CloudSyncUIAvailabilityTests.swift
//  MagSafe Guard
//

import XCTest

@testable import MagSafeGuard

final class CloudSyncUIAvailabilityTests: XCTestCase {

  func testTabHiddenWithoutCloudKitEntitlement() {
    // Personal Team / debug builds without iCloud capability
    XCTAssertFalse(CloudSyncUIAvailability.isTabVisible)
  }
}
