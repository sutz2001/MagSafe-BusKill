//
//  ParanoidConfiguration.swift
//  MagSafeGuardCore
//

import CryptoKit
import Foundation
import Security

/// User-configured data-destruction targets for paranoid mode (v0.6).
///
/// Arming paranoid is a later milestone. This type only stores setup data:
/// wipe paths, optional APFS volume identifiers, optional recovery-key backup path,
/// and a hashed codeword (never plaintext).
public struct ParanoidConfiguration: Codable, Equatable, Sendable {

  /// Absolute directory or file paths to delete on trigger (list order = wipe priority).
  public var wipePaths: [String]

  /// APFS volume UUIDs (never the boot volume). Erased on trigger when implemented.
  public var apfsVolumeIdentifiers: [String]

  /// Optional local FileVault recovery-key backup file to delete on trigger.
  public var recoveryKeyBackupPath: String?

  /// Seconds to spend wiping paths in list order before stopping remaining paths.
  /// `0` = no time cap (wipe all configured paths sequentially). Default 10.
  public var pathWipeTimeBudgetSeconds: TimeInterval

  /// SHA-256 hex of `salt || UTF-8(codeword)`. Empty until the user sets a codeword.
  public var codewordHash: String?

  /// Random salt (hex) used with `codewordHash`.
  public var codewordSalt: String?

  /// Setup wizard completed (FileVault check + at least one wipe target).
  public var setupCompleted: Bool

  /// Full paranoid legal notice accepted.
  public var legalNoticeAccepted: Bool

  public init(
    wipePaths: [String] = [],
    apfsVolumeIdentifiers: [String] = [],
    recoveryKeyBackupPath: String? = nil,
    pathWipeTimeBudgetSeconds: TimeInterval = 10,
    codewordHash: String? = nil,
    codewordSalt: String? = nil,
    setupCompleted: Bool = false,
    legalNoticeAccepted: Bool = false
  ) {
    self.wipePaths = wipePaths
    self.apfsVolumeIdentifiers = apfsVolumeIdentifiers
    self.recoveryKeyBackupPath = recoveryKeyBackupPath
    self.pathWipeTimeBudgetSeconds = pathWipeTimeBudgetSeconds
    self.codewordHash = codewordHash
    self.codewordSalt = codewordSalt
    self.setupCompleted = setupCompleted
    self.legalNoticeAccepted = legalNoticeAccepted
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    wipePaths = try container.decodeIfPresent([String].self, forKey: .wipePaths) ?? []
    apfsVolumeIdentifiers =
      try container.decodeIfPresent([String].self, forKey: .apfsVolumeIdentifiers) ?? []
    recoveryKeyBackupPath = try container.decodeIfPresent(String.self, forKey: .recoveryKeyBackupPath)
    pathWipeTimeBudgetSeconds =
      try container.decodeIfPresent(TimeInterval.self, forKey: .pathWipeTimeBudgetSeconds) ?? 10
    codewordHash = try container.decodeIfPresent(String.self, forKey: .codewordHash)
    codewordSalt = try container.decodeIfPresent(String.self, forKey: .codewordSalt)
    setupCompleted = try container.decodeIfPresent(Bool.self, forKey: .setupCompleted) ?? false
    legalNoticeAccepted =
      try container.decodeIfPresent(Bool.self, forKey: .legalNoticeAccepted) ?? false
  }

  /// True when at least one destruction target is configured.
  public var hasWipeTarget: Bool {
    !wipePaths.isEmpty || !apfsVolumeIdentifiers.isEmpty
  }

  /// True when a codeword hash is stored.
  public var hasCodeword: Bool {
    !(codewordHash ?? "").isEmpty && !(codewordSalt ?? "").isEmpty
  }

  /// Gates arming: setup, legal, wipe target, and codeword. FileVault is re-checked at arm time.
  public var isReadyToArm: Bool {
    setupCompleted && legalNoticeAccepted && hasWipeTarget && hasCodeword
  }

  /// Setup wizard finish: FileVault on and at least one wipe target after sanitizing.
  public func canCompleteSetup(fileVaultEnabled: Bool) -> Bool {
    fileVaultEnabled && validated().hasWipeTarget
  }

  /// Marks setup complete, or returns false and leaves `setupCompleted` false.
  public mutating func completeSetup(fileVaultEnabled: Bool) -> Bool {
    guard canCompleteSetup(fileVaultEnabled: fileVaultEnabled) else {
      setupCompleted = false
      return false
    }
    setupCompleted = true
    return true
  }

  /// Trims paths, drops empties/duplicates, and clears obviously unsafe wipe roots.
  public func validated() -> ParanoidConfiguration {
    var copy = self
    copy.wipePaths = Self.sanitizedUniquePaths(wipePaths)
    copy.apfsVolumeIdentifiers = Self.sanitizedUniqueIdentifiers(apfsVolumeIdentifiers)
    let recovery = recoveryKeyBackupPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    copy.recoveryKeyBackupPath = recovery.isEmpty ? nil : recovery
    if (copy.codewordHash ?? "").isEmpty {
      copy.codewordHash = nil
      copy.codewordSalt = nil
    }
    copy.pathWipeTimeBudgetSeconds = max(0, min(60, pathWipeTimeBudgetSeconds))
    if !copy.hasWipeTarget {
      copy.setupCompleted = false
    }
    return copy
  }

  /// Stores a new codeword (overwrites previous hash/salt).
  public mutating func setCodeword(_ plaintext: String) {
    let trimmed = plaintext.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      codewordHash = nil
      codewordSalt = nil
      return
    }
    var salt = Data(count: 16)
    salt.withUnsafeMutableBytes { buffer in
      _ = SecRandomCopyBytes(kSecRandomDefault, 16, buffer.baseAddress!)
    }
    codewordSalt = salt.map { String(format: "%02x", $0) }.joined()
    codewordHash = Self.hashCodeword(trimmed, salt: salt)
  }

  /// Constant-time-ish compare of plaintext against stored hash.
  public func matchesCodeword(_ plaintext: String) -> Bool {
    guard let hash = codewordHash, let saltHex = codewordSalt,
      let salt = Data(hexString: saltHex)
    else { return false }
    let candidate = Self.hashCodeword(plaintext, salt: salt)
    return candidate == hash
  }

  public static func hashCodeword(_ plaintext: String, salt: Data) -> String {
    var hasher = SHA256()
    hasher.update(data: salt)
    hasher.update(data: Data(plaintext.utf8))
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }

  static func sanitizedUniquePaths(_ paths: [String]) -> [String] {
    var seen = Set<String>()
    return paths.compactMap { raw in
      let path = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !path.isEmpty, path.hasPrefix("/"), !seen.contains(path) else { return nil }
      if isForbiddenWipePath(path) { return nil }
      seen.insert(path)
      return path
    }
  }

  static func sanitizedUniqueIdentifiers(_ ids: [String]) -> [String] {
    var seen = Set<String>()
    return ids.compactMap { raw in
      let id = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !id.isEmpty, !seen.contains(id) else { return nil }
      seen.insert(id)
      return id
    }
  }

  /// Rejects wiping the root or core OS locations. User data paths remain allowed.
  public static func isForbiddenWipePath(_ path: String) -> Bool {
    let standardized = (path as NSString).standardizingPath
    if standardized == "/" { return true }
    let forbidden = [
      "/System", "/usr", "/bin", "/sbin", "/private/var/db", "/Library/Apple",
    ]
    return forbidden.contains { prefix in
      standardized == prefix || standardized.hasPrefix(prefix + "/")
    }
  }
}

private extension Data {
  init?(hexString: String) {
    let hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard hex.count.isMultiple(of: 2), !hex.isEmpty else { return nil }
    var data = Data(capacity: hex.count / 2)
    var index = hex.startIndex
    while index < hex.endIndex {
      let next = hex.index(index, offsetBy: 2)
      guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
      data.append(byte)
      index = next
    }
    self = data
  }
}
