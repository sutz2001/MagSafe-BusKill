//
//  ParanoidConfigurationTests.swift
//  MagSafeGuardCoreTests
//

import XCTest

@testable import MagSafeGuardCore

final class ParanoidConfigurationTests: XCTestCase {

  func testDefaultIsNotReadyToArm() {
    let config = ParanoidConfiguration()
    XCTAssertFalse(config.hasWipeTarget)
    XCTAssertFalse(config.hasCodeword)
    XCTAssertFalse(config.isReadyToArm)
    XCTAssertFalse(config.setupCompleted)
    XCTAssertFalse(config.legalNoticeAccepted)
  }

  func testIsReadyToArmRequiresAllGates() {
    var config = ParanoidConfiguration()
    config.wipePaths = ["/Users/test/vault"]
    config.setupCompleted = true
    config.legalNoticeAccepted = true
    XCTAssertFalse(config.isReadyToArm)

    config.setCodeword("correct-horse")
    XCTAssertTrue(config.isReadyToArm)
  }

  func testEmptyConfigBlocksArmingEvenIfFlagsSet() {
    var config = ParanoidConfiguration()
    config.setupCompleted = true
    config.legalNoticeAccepted = true
    config.setCodeword("secret")
    XCTAssertFalse(config.hasWipeTarget)
    XCTAssertFalse(config.isReadyToArm)
  }

  func testValidatedDropsForbiddenAndEmptyPaths() {
    var config = ParanoidConfiguration()
    config.wipePaths = [
      "/",
      "/System/Library",
      "relative/path",
      "",
      "/Users/test/secrets",
      "/Users/test/secrets",
    ]
    config.apfsVolumeIdentifiers = ["  ABC-123  ", "", "ABC-123"]
    config.setupCompleted = true

    let validated = config.validated()
    XCTAssertEqual(validated.wipePaths, ["/Users/test/secrets"])
    XCTAssertEqual(validated.apfsVolumeIdentifiers, ["ABC-123"])
    XCTAssertTrue(validated.hasWipeTarget)
    XCTAssertTrue(validated.setupCompleted)
  }

  func testValidatedClearsSetupWhenNoTargetsRemain() {
    var config = ParanoidConfiguration()
    config.wipePaths = ["/"]
    config.setupCompleted = true
    XCTAssertFalse(config.validated().setupCompleted)
  }

  func testCodewordHashIsNotPlaintextAndMatches() {
    var config = ParanoidConfiguration()
    config.setCodeword("opensesame")
    XCTAssertNotEqual(config.codewordHash, "opensesame")
    XCTAssertNotNil(config.codewordSalt)
    XCTAssertTrue(config.matchesCodeword("opensesame"))
    XCTAssertFalse(config.matchesCodeword("wrong"))
    XCTAssertFalse(config.matchesCodeword(""))
  }

  func testClearingCodewordRemovesHash() {
    var config = ParanoidConfiguration()
    config.setCodeword("temp")
    config.setCodeword("   ")
    XCTAssertNil(config.codewordHash)
    XCTAssertNil(config.codewordSalt)
    XCTAssertFalse(config.hasCodeword)
  }

  func testCodableRoundTrip() throws {
    var original = ParanoidConfiguration()
    original.wipePaths = ["/Users/test/wipe-me"]
    original.apfsVolumeIdentifiers = ["VOL-UUID"]
    original.recoveryKeyBackupPath = "/Users/test/recovery.txt"
    original.setCodeword("phrase")
    original.setupCompleted = true
    original.legalNoticeAccepted = true

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(ParanoidConfiguration.self, from: data)

    XCTAssertEqual(decoded.wipePaths, original.wipePaths)
    XCTAssertEqual(decoded.apfsVolumeIdentifiers, original.apfsVolumeIdentifiers)
    XCTAssertEqual(decoded.recoveryKeyBackupPath, original.recoveryKeyBackupPath)
    XCTAssertEqual(decoded.codewordHash, original.codewordHash)
    XCTAssertEqual(decoded.codewordSalt, original.codewordSalt)
    XCTAssertTrue(decoded.matchesCodeword("phrase"))
    XCTAssertTrue(decoded.isReadyToArm)
  }

  func testSettingsDecodeWithoutParanoidKeyUsesDefaults() throws {
    let json = """
      {"gracePeriodDuration": 12.0, "allowGracePeriodCancellation": true}
      """.data(using: .utf8)!
    let settings = try JSONDecoder().decode(Settings.self, from: json)
    XCTAssertEqual(settings.gracePeriodDuration, 12.0)
    XCTAssertEqual(settings.paranoid, ParanoidConfiguration())
    XCTAssertFalse(settings.paranoid.isReadyToArm)
  }

  func testSettingsRoundTripIncludesParanoid() throws {
    var settings = Settings()
    settings.paranoid.wipePaths = ["/Users/test/data"]
    settings.paranoid.legalNoticeAccepted = true
    let data = try JSONEncoder().encode(settings)
    let decoded = try JSONDecoder().decode(Settings.self, from: data)
    XCTAssertEqual(decoded.paranoid.wipePaths, ["/Users/test/data"])
    XCTAssertTrue(decoded.paranoid.legalNoticeAccepted)
  }

  func testSettingsValidatedSanitizesParanoid() {
    var settings = Settings()
    settings.paranoid.wipePaths = ["/", "/Users/ok"]
    let validated = settings.validated()
    XCTAssertEqual(validated.paranoid.wipePaths, ["/Users/ok"])
  }

  func testCompleteSetupRequiresFileVaultAndWipeTarget() {
    var config = ParanoidConfiguration()
    XCTAssertFalse(config.completeSetup(fileVaultEnabled: true))
    XCTAssertFalse(config.setupCompleted)

    config.wipePaths = ["/Users/test/secrets"]
    XCTAssertFalse(config.completeSetup(fileVaultEnabled: false))
    XCTAssertFalse(config.setupCompleted)

    XCTAssertTrue(config.completeSetup(fileVaultEnabled: true))
    XCTAssertTrue(config.setupCompleted)
  }

  func testCompleteSetupRejectsForbiddenOnlyPaths() {
    var config = ParanoidConfiguration()
    config.wipePaths = ["/System"]
    XCTAssertFalse(config.canCompleteSetup(fileVaultEnabled: true))
    XCTAssertFalse(config.completeSetup(fileVaultEnabled: true))
  }
}
