//
//  MacDestructionPipeline.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

/// Production destruction pipeline. Never erases the boot volume. No-ops in CI/XCTest
/// unless a test injects `DestructionSafetyPolicy`.
///
/// Paths are wiped **sequentially in list order** (user priority) via `/bin/rm -rf --`.
/// `pathWipeTimeBudgetSeconds` stops starting further paths when the budget elapses (`0` = no cap).
public final class MacDestructionPipeline: DestructionPipeline, @unchecked Sendable {

  public typealias ShellCapture = (String, [String]) throws -> String

  private let fileManager: FileManager
  private let policy: DestructionSafetyPolicy
  private let captureShell: ShellCapture
  private let bootIdentity: () -> (uuid: String?, deviceNode: String?)

  public init(
    fileManager: FileManager = .default,
    policy: DestructionSafetyPolicy = .fromEnvironment(),
    captureShell: ShellCapture? = nil,
    bootIdentity: (() -> (uuid: String?, deviceNode: String?))? = nil
  ) {
    self.fileManager = fileManager
    self.policy = policy
    self.captureShell = captureShell ?? Self.defaultCaptureShell
    self.bootIdentity = bootIdentity ?? {
      Self.readBootIdentity(captureShell: captureShell ?? Self.defaultCaptureShell)
    }
  }

  public func execute(_ config: ParanoidConfiguration) -> DestructionResult {
    let validated = config.validated()
    let boot = bootIdentity()
    let budget = validated.pathWipeTimeBudgetSeconds
    let deadline: Date? = budget > 0 ? Date().addingTimeInterval(budget) : nil

    var wiped: [String] = []
    var failedPaths: [DestructionResult.Failure] = []
    var erased: [String] = []
    var failedVolumes: [DestructionResult.Failure] = []
    var recoveryDeleted = false
    var recoveryError: String?

    for path in validated.wipePaths {
      if let deadline, Date() >= deadline {
        failedPaths.append(
          .init(target: path, message: "Path wipe budget exhausted")
        )
        continue
      }
      switch wipePath(path) {
      case .wiped(let p): wiped.append(p)
      case .failed(let f): failedPaths.append(f)
      }
    }

    if let recovery = validated.recoveryKeyBackupPath {
      if let deadline, Date() >= deadline {
        recoveryError = "Path wipe budget exhausted"
      } else {
        switch wipePath(recovery) {
        case .wiped:
          recoveryDeleted = true
        case .failed(let f):
          recoveryError = f.message
        }
      }
    }

    for volumeID in validated.apfsVolumeIdentifiers {
      if let deadline, Date() >= deadline {
        failedVolumes.append(
          .init(target: volumeID, message: "Path wipe budget exhausted")
        )
        continue
      }
      switch eraseVolume(volumeID, bootUUID: boot.uuid, bootDevice: boot.deviceNode) {
      case .erased(let id): erased.append(id)
      case .failed(let f): failedVolumes.append(f)
      }
    }

    return DestructionResult(
      wipedPaths: wiped,
      failedPaths: failedPaths,
      erasedVolumes: erased,
      failedVolumes: failedVolumes,
      recoveryKeyDeleted: recoveryDeleted,
      recoveryKeyError: recoveryError
    )
  }

  private enum PathOutcome {
    case wiped(String)
    case failed(DestructionResult.Failure)
  }

  private enum VolumeOutcome {
    case erased(String)
    case failed(DestructionResult.Failure)
  }

  private func wipePath(_ path: String) -> PathOutcome {
    guard policy.allowPathWipe else {
      return .failed(.init(target: path, message: "Path wipe disabled (CI/test)"))
    }
    guard !ParanoidConfiguration.isForbiddenWipePath(path) else {
      return .failed(.init(target: path, message: "Forbidden system path"))
    }
    guard fileManager.fileExists(atPath: path) else {
      return .failed(.init(target: path, message: "Path not found"))
    }
    do {
      // argv form — no shell. Equivalent to `rm -rf -- <path>`.
      _ = try captureShell("/bin/rm", ["-rf", "--", path])
      return .wiped(path)
    } catch {
      return .failed(.init(target: path, message: error.localizedDescription))
    }
  }

  private func eraseVolume(
    _ identifier: String,
    bootUUID: String?,
    bootDevice: String?
  ) -> VolumeOutcome {
    guard policy.allowVolumeErase else {
      return .failed(.init(target: identifier, message: "Volume erase disabled (CI/test)"))
    }
    guard bootUUID != nil else {
      return .failed(.init(target: identifier, message: "Boot volume UUID unavailable; refusing erase"))
    }
    guard !DestructionVolumeIdentity.isBootVolume(
      identifier: identifier,
      bootVolumeUUID: bootUUID,
      bootDeviceNode: bootDevice
    ) else {
      return .failed(.init(target: identifier, message: "Refusing to erase boot volume"))
    }
    do {
      _ = try captureShell("/usr/sbin/diskutil", [
        "apfs", "eraseVolume", identifier, "-name", "WIPED",
      ])
      return .erased(identifier)
    } catch {
      return .failed(.init(target: identifier, message: error.localizedDescription))
    }
  }

  static func readBootIdentity(
    captureShell: ShellCapture
  ) -> (uuid: String?, deviceNode: String?) {
    guard let output = try? captureShell("/usr/sbin/diskutil", ["info", "-plist", "/"]),
      let data = output.data(using: .utf8)
    else {
      return (nil, nil)
    }
    return (
      DestructionVolumeIdentity.volumeUUID(fromDiskutilPlist: data),
      DestructionVolumeIdentity.deviceNode(fromDiskutilPlist: data)
    )
  }

  private static func defaultCaptureShell(_ launchPath: String, _ args: [String]) throws -> String {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = args
    process.standardOutput = pipe
    process.standardError = pipe
    try process.run()
    process.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    guard process.terminationStatus == 0 else {
      throw NSError(
        domain: "MacDestructionPipeline",
        code: Int(process.terminationStatus),
        userInfo: [NSLocalizedDescriptionKey: output.trimmingCharacters(in: .whitespacesAndNewlines)]
      )
    }
    return output
  }
}
