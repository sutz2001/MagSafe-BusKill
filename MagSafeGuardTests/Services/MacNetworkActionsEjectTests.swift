//
//  MacNetworkActionsEjectTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
import MagSafeGuardCore
import XCTest

final class MacNetworkActionsEjectTests: XCTestCase {

  func testParseExternalPhysicalDiskDevices() {
    let sample = """
    /dev/disk4 (external, physical):
       #:                       TYPE NAME                    SIZE       IDENTIFIER
       0:     FDisk_partition_scheme                        *15.9 GB    disk4
       1:                 DOS_FAT_32 USBSTICK                15.9 GB    disk4s1

    /dev/disk5 (external, physical):
       #:                       TYPE NAME                    SIZE       IDENTIFIER
    """

    XCTAssertEqual(
      MacNetworkActions.parseExternalPhysicalDiskDevices(from: sample),
      ["/dev/disk4", "/dev/disk5"]
    )
  }

  func testParseExternalPhysicalDiskDevicesEmpty() {
    XCTAssertEqual(MacNetworkActions.parseExternalPhysicalDiskDevices(from: ""), [])
  }

  func testHardEjectExternalDevicesNoOpWhenEmpty() throws {
    try MacNetworkActions.hardEjectExternalDevices([]) { _ in
      XCTFail("Should not eject when device list is empty")
    }
  }

  func testHardEjectExternalDevicesSucceedsWhenAnyDeviceEjects() throws {
    var ejected: [String] = []
    try MacNetworkActions.hardEjectExternalDevices(["/dev/disk4", "/dev/disk5"]) { device in
      ejected.append(device)
      if device == "/dev/disk4" {
        throw NetworkActionError.commandFailed(action: .ejectRemovableVolumes, message: "busy")
      }
    }
    XCTAssertEqual(ejected, ["/dev/disk4", "/dev/disk5"])
  }

  func testHardEjectExternalDevicesThrowsWhenAllFail() {
    XCTAssertThrowsError(
      try MacNetworkActions.hardEjectExternalDevices(["/dev/disk4"]) { _ in
        throw NetworkActionError.commandFailed(action: .ejectRemovableVolumes, message: "busy")
      }
    )
  }

  func testEjectRemovableVolumesNoDevicesIsNoOp() throws {
    let sut = MacNetworkActions(processRunner: { launchPath, args in
      XCTAssertEqual(launchPath, "/usr/sbin/diskutil")
      XCTAssertEqual(args, ["list", "external", "physical"])
    })

    try sut.ejectRemovableVolumes()
  }
}
