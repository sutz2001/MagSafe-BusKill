//
//  ParanoidWipePathSuggestionsTests.swift
//  MagSafeGuardCoreTests
//

import XCTest

@testable import MagSafeGuardCore

final class ParanoidWipePathSuggestionsTests: XCTestCase {

  func testAvailableOnlyReturnsExistingNonForbiddenPaths() {
    let home = "/Users/test"
    let exists: Set<String> = [
      "/Users/test/Cryptomator",
      "/Users/test/Secure",
    ]
    let items = ParanoidWipePathSuggestions.available(
      homeDirectory: home,
      fileExists: { exists.contains($0) }
    )
    XCTAssertEqual(items.map(\.id).sorted(), ["cryptomator", "secure"])
    XCTAssertEqual(
      items.map(\.absolutePath).sorted(),
      ["/Users/test/Cryptomator", "/Users/test/Secure"]
    )
  }

  func testAvailableEmptyWhenNothingExists() {
    let items = ParanoidWipePathSuggestions.available(
      homeDirectory: "/Users/nobody",
      fileExists: { _ in false }
    )
    XCTAssertTrue(items.isEmpty)
  }

  func testMergeAppendsWithoutDuplicates() {
    let merged = ParanoidWipePathSuggestions.merge(
      selectedPaths: ["/Users/a/Vault", "/Users/a/Cryptomator", "/System"],
      into: ["/Users/a/Vault"]
    )
    XCTAssertEqual(merged, ["/Users/a/Vault", "/Users/a/Cryptomator"])
  }

  func testAvailableIncludesBroadUserTreesWhenPresent() {
    let home = "/Users/test"
    let exists: Set<String> = [
      "/Users/test",
      "/Users/test/Documents",
      "/Users/test/Desktop",
      "/Users/test/Downloads",
      "/Users/test/Cryptomator",
    ]
    let items = ParanoidWipePathSuggestions.available(
      homeDirectory: home,
      fileExists: { exists.contains($0) }
    )
    XCTAssertEqual(
      items.map(\.id),
      ["home", "documents", "desktop", "downloads", "cryptomator"]
    )
  }

  func testTemplatesIncludeBroadHomeTreesForParanoidOptIn() {
    let relatives = ParanoidWipePathSuggestions.homeRelativeTemplates.map(\.relativePath)
    XCTAssertTrue(relatives.contains(""))
    XCTAssertTrue(relatives.contains("Documents"))
    XCTAssertTrue(relatives.contains("Desktop"))
    XCTAssertTrue(relatives.contains("Downloads"))
  }
}
