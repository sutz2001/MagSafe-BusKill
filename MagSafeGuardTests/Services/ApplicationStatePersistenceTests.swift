//
//  ApplicationStatePersistenceTests.swift
//  MagSafeGuardTests
//

import XCTest

@testable import MagSafeGuard

final class ApplicationStatePersistenceTests: XCTestCase {
  override func tearDown() {
    ApplicationStatePersistence.clear()
    super.tearDown()
  }

  func testSaveAndLoadWasArmed() {
    XCTAssertFalse(ApplicationStatePersistence.loadWasArmed())
    ApplicationStatePersistence.saveWasArmed(true)
    XCTAssertTrue(ApplicationStatePersistence.loadWasArmed())
  }

  func testClearRemovesPersistedState() {
    ApplicationStatePersistence.saveWasArmed(true)
    ApplicationStatePersistence.clear()
    XCTAssertFalse(ApplicationStatePersistence.loadWasArmed())
  }
}
