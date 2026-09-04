//
//  FileVaultStatusTests.swift
//  MagSafeGuardCoreTests
//

import XCTest

@testable import MagSafeGuardCore

final class FileVaultStatusTests: XCTestCase {

  func testParseOn() {
    XCTAssertEqual(FileVaultStatusChecker.parse("FileVault is On.\n"), .enabled)
    XCTAssertEqual(
      FileVaultStatusChecker.parse(
        "FileVault is On, but needs to be restarted to complete."
      ),
      .enabled
    )
  }

  func testParseOff() {
    XCTAssertEqual(FileVaultStatusChecker.parse("FileVault is Off."), .disabled)
  }

  func testParseUnknown() {
    XCTAssertEqual(
      FileVaultStatusChecker.parse("unexpected"),
      .unknown("unexpected")
    )
    XCTAssertEqual(
      FileVaultStatusChecker.parse("   "),
      .unknown("empty fdesetup output")
    )
  }

  func testInjectedProvider() {
    let on = FileVaultStatusChecker(outputProvider: { "FileVault is On." })
    XCTAssertTrue(on.check().isEnabled)

    let off = FileVaultStatusChecker(outputProvider: { "FileVault is Off." })
    XCTAssertEqual(off.check(), .disabled)

    let failing = FileVaultStatusChecker(outputProvider: { throw NSError(domain: "t", code: 1) })
    guard case .unknown = failing.check() else {
      return XCTFail("Expected unknown on thrown error")
    }
  }
}
