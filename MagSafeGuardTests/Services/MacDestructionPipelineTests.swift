//
//  MacDestructionPipelineTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
@testable import MagSafeGuardCore
import XCTest

final class MacDestructionPipelineTests: XCTestCase {

  private var tempDir: URL!

  override func setUpWithError() throws {
    tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("magsafe-destruction-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: tempDir)
  }

  /// Simulates `/bin/rm -rf -- path` by removing via FileManager.
  private func rmCapturingShell(
    recorded: UnsafeMutablePointer<[(String, [String])]>? = nil
  ) -> MacDestructionPipeline.ShellCapture {
    { launchPath, args in
      recorded?.pointee.append((launchPath, args))
      if launchPath == "/bin/rm", args.count >= 3, args[0] == "-rf", args[1] == "--" {
        try FileManager.default.removeItem(atPath: args[2])
        return ""
      }
      return ""
    }
  }

  func testPathWipeUsesRmRfAndDeletesFile() throws {
    let target = tempDir.appendingPathComponent("wipe-me.txt")
    try "secret".write(to: target, atomically: true, encoding: .utf8)
    var captured: [(String, [String])] = []

    let pipeline = MacDestructionPipeline(
      policy: DestructionSafetyPolicy(allowPathWipe: true, allowVolumeErase: false),
      captureShell: { path, args in
        captured.append((path, args))
        if path == "/bin/rm", args.count >= 3 {
          try FileManager.default.removeItem(atPath: args[2])
        }
        return ""
      },
      bootIdentity: { ("BOOT-UUID", "/dev/disk3s1") }
    )
    var config = ParanoidConfiguration()
    config.wipePaths = [target.path]

    let result = pipeline.execute(config)

    XCTAssertEqual(result.wipedPaths, [target.path])
    XCTAssertFalse(FileManager.default.fileExists(atPath: target.path))
    XCTAssertEqual(captured.first?.0, "/bin/rm")
    XCTAssertEqual(captured.first?.1, ["-rf", "--", target.path])
  }

  func testWipePathsRunSequentiallyInListOrder() throws {
    let first = tempDir.appendingPathComponent("a")
    let second = tempDir.appendingPathComponent("b")
    try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)
    var order: [String] = []

    let pipeline = MacDestructionPipeline(
      policy: DestructionSafetyPolicy(allowPathWipe: true, allowVolumeErase: false),
      captureShell: { path, args in
        if path == "/bin/rm", args.count >= 3 {
          order.append(args[2])
          try FileManager.default.removeItem(atPath: args[2])
        }
        return ""
      },
      bootIdentity: { ("BOOT-UUID", "/dev/disk3s1") }
    )
    var config = ParanoidConfiguration()
    config.wipePaths = [second.path, first.path]
    config.pathWipeTimeBudgetSeconds = 0

    _ = pipeline.execute(config)
    XCTAssertEqual(order, [second.path, first.path])
  }

  func testWipeBudgetSkipsRemainingPaths() throws {
    let first = tempDir.appendingPathComponent("first.txt")
    let second = tempDir.appendingPathComponent("second.txt")
    try "1".write(to: first, atomically: true, encoding: .utf8)
    try "2".write(to: second, atomically: true, encoding: .utf8)

    let pipeline = MacDestructionPipeline(
      policy: DestructionSafetyPolicy(allowPathWipe: true, allowVolumeErase: false),
      captureShell: { path, args in
        if path == "/bin/rm", args.count >= 3 {
          Thread.sleep(forTimeInterval: 0.15)
          try FileManager.default.removeItem(atPath: args[2])
        }
        return ""
      },
      bootIdentity: { ("BOOT-UUID", "/dev/disk3s1") }
    )
    var config = ParanoidConfiguration()
    config.wipePaths = [first.path, second.path]
    config.pathWipeTimeBudgetSeconds = 0.05

    let result = pipeline.execute(config)
    XCTAssertEqual(result.wipedPaths, [first.path])
    XCTAssertEqual(result.failedPaths.first?.target, second.path)
    XCTAssertEqual(result.failedPaths.first?.message, "Path wipe budget exhausted")
    XCTAssertTrue(FileManager.default.fileExists(atPath: second.path))
  }

  func testDefaultPolicyInXCTestDoesNotDeleteFiles() throws {
    let target = tempDir.appendingPathComponent("keep-me.txt")
    try "keep".write(to: target, atomically: true, encoding: .utf8)

    let pipeline = MacDestructionPipeline(
      captureShell: { _, _ in XCTFail("diskutil must not run"); return "" },
      bootIdentity: { ("BOOT-UUID", "/dev/disk3s1") }
    )
    var config = ParanoidConfiguration()
    config.wipePaths = [target.path]

    let result = pipeline.execute(config)

    XCTAssertTrue(FileManager.default.fileExists(atPath: target.path))
    XCTAssertEqual(result.failedPaths.first?.message, "Path wipe disabled (CI/test)")
  }

  func testForbiddenRecoveryKeyIsRejectedEvenWhenWipeAllowed() {
    let pipeline = MacDestructionPipeline(
      policy: DestructionSafetyPolicy(allowPathWipe: true, allowVolumeErase: false),
      captureShell: { _, _ in "" },
      bootIdentity: { ("BOOT-UUID", "/dev/disk3s1") }
    )
    var config = ParanoidConfiguration()
    config.recoveryKeyBackupPath = "/System/Library/CoreServices"

    let result = pipeline.execute(config)
    XCTAssertFalse(result.recoveryKeyDeleted)
    XCTAssertEqual(result.recoveryKeyError, "Forbidden system path")
  }

  func testRecoveryKeyFileDeletedWhenAllowed() throws {
    let key = tempDir.appendingPathComponent("recovery.txt")
    try "KEY".write(to: key, atomically: true, encoding: .utf8)

    let pipeline = MacDestructionPipeline(
      policy: DestructionSafetyPolicy(allowPathWipe: true, allowVolumeErase: false),
      captureShell: { path, args in
        if path == "/bin/rm", args.count >= 3 {
          try FileManager.default.removeItem(atPath: args[2])
        }
        return ""
      },
      bootIdentity: { ("BOOT-UUID", "/dev/disk3s1") }
    )
    var config = ParanoidConfiguration()
    config.recoveryKeyBackupPath = key.path

    let result = pipeline.execute(config)
    XCTAssertTrue(result.recoveryKeyDeleted)
    XCTAssertFalse(FileManager.default.fileExists(atPath: key.path))
  }

  func testVolumeEraseRefusesBootUUID() {
    var captured: [(String, [String])] = []
    let pipeline = MacDestructionPipeline(
      policy: DestructionSafetyPolicy(allowPathWipe: false, allowVolumeErase: true),
      captureShell: { path, args in
        captured.append((path, args))
        return ""
      },
      bootIdentity: { ("BOOT-UUID", "/dev/disk3s1") }
    )
    var config = ParanoidConfiguration()
    config.apfsVolumeIdentifiers = ["BOOT-UUID"]

    let result = pipeline.execute(config)
    XCTAssertTrue(captured.isEmpty)
    XCTAssertEqual(result.failedVolumes.first?.message, "Refusing to erase boot volume")
  }

  func testVolumeEraseRefusesWhenBootUUIDUnknown() {
    var captured: [(String, [String])] = []
    let pipeline = MacDestructionPipeline(
      policy: DestructionSafetyPolicy(allowPathWipe: false, allowVolumeErase: true),
      captureShell: { path, args in
        captured.append((path, args))
        return ""
      },
      bootIdentity: { (nil, nil) }
    )
    var config = ParanoidConfiguration()
    config.apfsVolumeIdentifiers = ["SAFE-UUID"]

    let result = pipeline.execute(config)
    XCTAssertTrue(captured.isEmpty)
    XCTAssertEqual(
      result.failedVolumes.first?.message,
      "Boot volume UUID unavailable; refusing erase"
    )
  }

  func testVolumeEraseCallsDiskutilApfsEraseVolumeForNonBoot() {
    var captured: [(String, [String])] = []
    let pipeline = MacDestructionPipeline(
      policy: DestructionSafetyPolicy(allowPathWipe: false, allowVolumeErase: true),
      captureShell: { path, args in
        captured.append((path, args))
        return ""
      },
      bootIdentity: { ("BOOT-UUID", "/dev/disk3s1") }
    )
    var config = ParanoidConfiguration()
    config.apfsVolumeIdentifiers = ["SAFE-UUID"]

    let result = pipeline.execute(config)
    XCTAssertEqual(result.erasedVolumes, ["SAFE-UUID"])
    XCTAssertEqual(captured.count, 1)
    XCTAssertEqual(captured[0].0, "/usr/sbin/diskutil")
    XCTAssertEqual(captured[0].1, ["apfs", "eraseVolume", "SAFE-UUID", "-name", "WIPED"])
  }

  func testVolumeEraseDisabledInDefaultTestPolicy() {
    var captured = 0
    let pipeline = MacDestructionPipeline(
      captureShell: { _, _ in
        captured += 1
        return ""
      },
      bootIdentity: { ("BOOT-UUID", "/dev/disk3s1") }
    )
    var config = ParanoidConfiguration()
    config.apfsVolumeIdentifiers = ["SAFE-UUID"]

    let result = pipeline.execute(config)
    XCTAssertEqual(captured, 0)
    XCTAssertEqual(result.failedVolumes.first?.message, "Volume erase disabled (CI/test)")
  }
}
