//
//  DestructionPipeline.swift
//  MagSafeGuardCore
//

import Foundation

/// Outcome of a (best-effort) destruction pass. Shutdown must not wait on this.
public struct DestructionResult: Equatable, Sendable {
  public struct Failure: Equatable, Sendable, Error {
    public let target: String
    public let message: String

    public init(target: String, message: String) {
      self.target = target
      self.message = message
    }

    public var errorDescription: String? { message }
  }

  public let wipedPaths: [String]
  public let failedPaths: [Failure]
  public let erasedVolumes: [String]
  public let failedVolumes: [Failure]
  public let recoveryKeyDeleted: Bool
  public let recoveryKeyError: String?
  public let skipped: Bool
  public let skipReason: String?

  public init(
    wipedPaths: [String] = [],
    failedPaths: [Failure] = [],
    erasedVolumes: [String] = [],
    failedVolumes: [Failure] = [],
    recoveryKeyDeleted: Bool = false,
    recoveryKeyError: String? = nil,
    skipped: Bool = false,
    skipReason: String? = nil
  ) {
    self.wipedPaths = wipedPaths
    self.failedPaths = failedPaths
    self.erasedVolumes = erasedVolumes
    self.failedVolumes = failedVolumes
    self.recoveryKeyDeleted = recoveryKeyDeleted
    self.recoveryKeyError = recoveryKeyError
    self.skipped = skipped
    self.skipReason = skipReason
  }

  public static let empty = DestructionResult()

  public static func skipped(_ reason: String) -> DestructionResult {
    DestructionResult(skipped: true, skipReason: reason)
  }
}

/// Fire-and-forget data destruction for paranoid mode.
public protocol DestructionPipeline: AnyObject, Sendable {
  func execute(_ config: ParanoidConfiguration) -> DestructionResult
}

/// Records calls and never touches the filesystem. Use in CI and unit tests.
public final class MockDestructionPipeline: DestructionPipeline, @unchecked Sendable {
  public private(set) var executeCallCount = 0
  public private(set) var lastConfig: ParanoidConfiguration?
  public var resultToReturn: DestructionResult = .empty

  public var onExecute: ((ParanoidConfiguration) -> Void)?

  public init() {}

  public func execute(_ config: ParanoidConfiguration) -> DestructionResult {
    executeCallCount += 1
    lastConfig = config
    onExecute?(config)
    return resultToReturn
  }

  public func reset() {
    executeCallCount = 0
    lastConfig = nil
    resultToReturn = .empty
    onExecute = nil
  }
}

/// Gates real IO. CI and XCTest never wipe or erase unless tests inject a custom policy.
public struct DestructionSafetyPolicy: Equatable, Sendable {
  public var allowPathWipe: Bool
  public var allowVolumeErase: Bool

  public init(allowPathWipe: Bool, allowVolumeErase: Bool) {
    self.allowPathWipe = allowPathWipe
    self.allowVolumeErase = allowVolumeErase
  }

  /// Production: allow both. CI / XCTest: allow neither.
  public static func fromEnvironment(
    _ environment: [String: String] = ProcessInfo.processInfo.environment
  ) -> DestructionSafetyPolicy {
    if isRestrictedTestEnvironment(environment) {
      return DestructionSafetyPolicy(allowPathWipe: false, allowVolumeErase: false)
    }
    return DestructionSafetyPolicy(allowPathWipe: true, allowVolumeErase: true)
  }

  public static func isRestrictedTestEnvironment(_ environment: [String: String]) -> Bool {
    if environment["CI"] != nil { return true }
    if environment["GITHUB_ACTIONS"] != nil { return true }
    if environment["XCTestConfigurationFilePath"] != nil { return true }
    return false
  }
}

/// Parses `diskutil info -plist` XML for volume identity guards.
public enum DestructionVolumeIdentity {
  public static func volumeUUID(fromDiskutilPlist plist: Data) -> String? {
    guard let object = try? PropertyListSerialization.propertyList(from: plist, format: nil),
      let dict = object as? [String: Any]
    else { return nil }
    if let uuid = dict["VolumeUUID"] as? String, !uuid.isEmpty { return uuid }
    if let uuid = dict["DiskUUID"] as? String, !uuid.isEmpty { return uuid }
    return nil
  }

  public static func deviceNode(fromDiskutilPlist plist: Data) -> String? {
    guard let object = try? PropertyListSerialization.propertyList(from: plist, format: nil),
      let dict = object as? [String: Any]
    else { return nil }
    return dict["DeviceNode"] as? String
  }

  /// True when `identifier` is the boot volume UUID or a whole-disk / slice of the boot device.
  public static func isBootVolume(
    identifier: String,
    bootVolumeUUID: String?,
    bootDeviceNode: String?
  ) -> Bool {
    let id = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !id.isEmpty else { return true }
    if let bootVolumeUUID, id.caseInsensitiveCompare(bootVolumeUUID) == .orderedSame {
      return true
    }
    if let bootDeviceNode {
      let boot = bootDeviceNode.trimmingCharacters(in: .whitespacesAndNewlines)
      if id == boot || id == boot.replacingOccurrences(of: "/dev/", with: "") {
        return true
      }
      let bootDisk = wholeDiskName(fromDeviceNode: boot)
      if id == bootDisk || id == "/dev/\(bootDisk)" {
        return true
      }
    }
    return false
  }

  static func wholeDiskName(fromDeviceNode node: String) -> String {
    let trimmed = node.replacingOccurrences(of: "/dev/", with: "")
    if let range = trimmed.range(of: #"^disk\d+"#, options: .regularExpression) {
      return String(trimmed[range])
    }
    return trimmed
  }
}
