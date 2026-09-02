//
//  CryptomatorMountParserTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
import XCTest

final class CryptomatorMountParserTests: XCTestCase {

  func testParseMacFUSECryptomatorMount() {
    let sample = """
    Cryptomator@macfuse0 on /Volumes/Secrets (macfuse, nodev, nosuid, synchronous, mounted by marc)
    """
    XCTAssertEqual(
      CryptomatorMountParser.parseMountPoints(from: sample),
      ["/Volumes/Secrets"]
    )
  }

  func testParseWebDAVCryptomatorMount() {
    let sample = """
    //guest@localhost:42427/vault-id/MyVault on /Volumes/MyVault (webdav, noexec, nosuid)
    """
    XCTAssertEqual(
      CryptomatorMountParser.parseMountPoints(from: sample),
      ["/Volumes/MyVault"]
    )
  }

  func testParseIgnoresNonCryptomatorVolumes() {
    let sample = """
    /dev/disk3s1 on /Volumes/Data (apfs, local, journaled)
    """
    XCTAssertTrue(CryptomatorMountParser.parseMountPoints(from: sample).isEmpty)
  }

  func testExtractVolumeMountPoint() {
    let line = "Cryptomator@macfuse0 on /Volumes/Test (macfuse, nosuid)"
    XCTAssertEqual(CryptomatorMountParser.extractVolumeMountPoint(from: line), "/Volumes/Test")
  }
}
