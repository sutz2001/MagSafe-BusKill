//
//  MacDestructionPipeline.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

/// Production destruction pipeline. Never erases the boot volume. No-ops in CI/XCTest
/// unless a test injects `DestructionSafetyPolicy`.
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

    var wiped: [String] = []
    var failedPaths: [DestructionResult.Failure] = []
    var erased: [String] = []
    var failedVolumes: [DestructionResult.Failure] = []
    var recoveryDeleted = false
    var recoveryError: String?

    let lock = NSLock()
    let group = DispatchGroup()
    let queue = DispatchQueue(
      label: "com.sutz2001.MagSafeGuard.destruction",
      qos: .userInitiated,
      attributes: .concurrent
    )

    for path in validated.wipePaths {
      group.enter()
      queue.async {
        defer { group.leave() }
        let outcome = self.wipePath(path)
        lock.lock()
        switch outcome {
        case .wiped(let p): wiped.append(p)
        case .failed(let f): failedPaths.append(f)
        }
        lock.unlock()
      }
    }

    if let recovery = validated.recoveryKeyBackupPath {
      group.enter()
      queue.async {
        defer { group.leave() }
        let outcome = self.wipePath(recovery)
        lock.lock()
        switch outcome {
        case .wiped:
          recoveryDeleted = true
        case .failed(let f):
          recoveryError = f.message
        }
        lock.unlock()
      }
    }

    for volumeID in validated.apfsVolumeIdentifiers {
      group.enter()
      queue.async {
        defer { group.leave() }
        let outcome = self.eraseVolume(volumeID, bootUUID: boot.uuid, bootDevice: boot.deviceNode)
        lock.lock()
        switch outcome {
        case .erased(let id): erased.append(id)
        case .failed(let f): failedVolumes.append(f)
        }
        lock.unlock()
      }
    }

    group.wait()

    return DestructionResult(
      wipedPaths: wiped.sorted(),
      failedPaths: failedPaths.sorted { $0.target < $1.target },
      erasedVolumes: erased.sorted(),
      failedVolumes: failedVolumes.sorted { $0.target < $1.target },
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
      try fileManager.removeItem(atPath: path)
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
