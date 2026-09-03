//
//  DestructionPipelineTests.swift
//  MagSafeGuardCoreTests
//

import XCTest

@testable import MagSafeGuardCore

final class DestructionPipelineTests: XCTestCase {

  func testMockRecordsConfigAndNeverImpliesIO() {
    let mock = MockDestructionPipeline()
    var config = ParanoidConfiguration()
    config.wipePaths = ["/Users/test/secrets"]
    mock.resultToReturn = DestructionResult(wipedPaths: ["/Users/test/secrets"])

    let result = mock.execute(config)

    XCTAssertEqual(mock.executeCallCount, 1)
    XCTAssertEqual(mock.lastConfig?.wipePaths, ["/Users/test/secrets"])
    XCTAssertEqual(result.wipedPaths, ["/Users/test/secrets"])
    XCTAssertFalse(result.skipped)
  }

  func testSafetyPolicyRestrictsCIAndXCTest() {
    XCTAssertTrue(
      DestructionSafetyPolicy.isRestrictedTestEnvironment(["CI": "true"])
    )
    XCTAssertTrue(
      DestructionSafetyPolicy.isRestrictedTestEnvironment(["GITHUB_ACTIONS": "true"])
    )
    XCTAssertTrue(
      DestructionSafetyPolicy.isRestrictedTestEnvironment([
        "XCTestConfigurationFilePath": "/tmp/xctest"
      ])
    )
    XCTAssertFalse(
      DestructionSafetyPolicy.isRestrictedTestEnvironment([:])
    )

    let ci = DestructionSafetyPolicy.fromEnvironment(["CI": "true"])
    XCTAssertFalse(ci.allowPathWipe)
    XCTAssertFalse(ci.allowVolumeErase)

    let prod = DestructionSafetyPolicy.fromEnvironment([:])
    XCTAssertTrue(prod.allowPathWipe)
    XCTAssertTrue(prod.allowVolumeErase)
  }

  func testVolumeUUIDParserReadsPlist() throws {
    let plist = """
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>VolumeUUID</key>
        <string>AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE</string>
        <key>DeviceNode</key>
        <string>/dev/disk3s1</string>
      </dict>
      </plist>
      """.data(using: .utf8)!

    XCTAssertEqual(
      DestructionVolumeIdentity.volumeUUID(fromDiskutilPlist: plist),
      "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
    )
    XCTAssertEqual(
      DestructionVolumeIdentity.deviceNode(fromDiskutilPlist: plist),
      "/dev/disk3s1"
    )
  }

  func testIsBootVolumeMatchesUUIDAndWholeDisk() {
    XCTAssertTrue(
      DestructionVolumeIdentity.isBootVolume(
        identifier: "BOOT-UUID",
        bootVolumeUUID: "BOOT-UUID",
        bootDeviceNode: "/dev/disk3s1"
      )
    )
    XCTAssertTrue(
      DestructionVolumeIdentity.isBootVolume(
        identifier: "disk3",
        bootVolumeUUID: "BOOT-UUID",
        bootDeviceNode: "/dev/disk3s1"
      )
    )
    XCTAssertTrue(
      DestructionVolumeIdentity.isBootVolume(
        identifier: "/dev/disk3s1",
        bootVolumeUUID: "BOOT-UUID",
        bootDeviceNode: "/dev/disk3s1"
      )
    )
    XCTAssertFalse(
      DestructionVolumeIdentity.isBootVolume(
        identifier: "OTHER-UUID",
        bootVolumeUUID: "BOOT-UUID",
        bootDeviceNode: "/dev/disk3s1"
      )
    )
  }

  func testEmptyIdentifierTreatedAsBoot() {
    XCTAssertTrue(
      DestructionVolumeIdentity.isBootVolume(
        identifier: "  ",
        bootVolumeUUID: "BOOT",
        bootDeviceNode: "/dev/disk3s1"
      )
    )
  }
}
