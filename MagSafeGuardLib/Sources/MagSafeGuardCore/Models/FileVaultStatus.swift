//
//  FileVaultStatus.swift
//  MagSafeGuardCore
//

import Foundation

/// Result of `fdesetup status` (or an injected runner).
public enum FileVaultStatus: Equatable, Sendable {
  case enabled
  case disabled
  case unknown(String)

  public var isEnabled: Bool {
    if case .enabled = self { return true }
    return false
  }
}

/// Reads FileVault state via `/usr/bin/fdesetup status`. Tests inject `outputProvider`.
public struct FileVaultStatusChecker: Sendable {
  public typealias OutputProvider = @Sendable () throws -> String

  private let outputProvider: OutputProvider

  public init(outputProvider: OutputProvider? = nil) {
    self.outputProvider = outputProvider ?? Self.defaultProvider
  }

  public func check() -> FileVaultStatus {
    do {
      return Self.parse(try outputProvider())
    } catch {
      return .unknown(error.localizedDescription)
    }
  }

  public static func parse(_ output: String) -> FileVaultStatus {
    let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
    let lower = trimmed.lowercased()
    if lower.contains("filevault is on") { return .enabled }
    if lower.contains("filevault is off") { return .disabled }
    if trimmed.isEmpty { return .unknown("empty fdesetup output") }
    return .unknown(trimmed)
  }

  private static func defaultProvider() throws -> String {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/fdesetup")
    process.arguments = ["status"]
    process.standardOutput = pipe
    process.standardError = pipe
    try process.run()
    process.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    guard process.terminationStatus == 0 else {
      throw NSError(
        domain: "FileVaultStatusChecker",
        code: Int(process.terminationStatus),
        userInfo: [
          NSLocalizedDescriptionKey: output.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
      )
    }
    return output
  }
}
