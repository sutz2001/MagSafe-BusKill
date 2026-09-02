//
//  MacNetworkActions.swift
//  MagSafe Guard
//

import AppKit
import Foundation
import MagSafeGuardCore

/// Production network actions using URLSession and `/usr/bin` tools.
public final class MacNetworkActions: NetworkActionsProtocol {

  private let session: URLSession
  private let processRunner: (@Sendable (String, [String]) throws -> Void)?

  public init(
    session: URLSession = .shared,
    processRunner: (@Sendable (String, [String]) throws -> Void)? = nil
  ) {
    self.session = session
    self.processRunner = processRunner
  }

  public func postWebhook(url: URL, event: String, token: String?, timeout: TimeInterval = 60) throws {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let token, !token.isEmpty {
      request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
    }
    let body: [String: String] = [
      "event": event,
      "source": "MagSafeGuard",
      "timestamp": ISO8601DateFormatter().string(from: Date())
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    request.timeoutInterval = timeout

    let semaphore = DispatchSemaphore(value: 0)
    var statusCode = 0
    var requestError: Error?

    let task = session.dataTask(with: request) { _, response, error in
      defer { semaphore.signal() }
      if let error {
        requestError = error
        return
      }
      statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
    }
    task.resume()
    let waitResult = semaphore.wait(timeout: .now() + timeout)

    if waitResult == .timedOut {
      task.cancel()
      throw NetworkActionError.commandFailed(action: .webhook, message: "Timed out after \(timeout)s")
    }

    if let requestError {
      throw NetworkActionError.commandFailed(action: .webhook, message: requestError.localizedDescription)
    }
    guard (200...299).contains(statusCode) else {
      throw NetworkActionError.webhookFailed(statusCode: statusCode)
    }
  }

  public func disconnectVPN() throws {
    try runShell("/usr/bin/osascript", args: [
      "-e",
      """
      tell application "System Events"
        try
          do shell script "scutil --nc list | grep Connected | head -1 | sed 's/.*\"\\(.*\\)\".*/\\1/' | xargs -I{} scutil --nc stop '{}'"
        end try
      end tell
      """
    ])
  }

  public func clearSSHAgent() throws {
    try runShell("/usr/bin/ssh-add", args: ["-D"])
  }

  public func clearClipboard() throws {
    NSPasteboard.general.clearContents()
  }

  public func ejectRemovableVolumes() throws {
    let output: String
    do {
      output = try captureShell("/usr/sbin/diskutil", args: ["list", "external", "physical"])
    } catch {
      throw NetworkActionError.commandFailed(
        action: .ejectRemovableVolumes,
        message: "diskutil list failed"
      )
    }

    let devices = Self.parseExternalPhysicalDiskDevices(from: output)
    try Self.hardEjectExternalDevices(devices) { device in
      try runShell("/usr/sbin/diskutil", args: ["eject", device])
    }
  }

  /// Best-effort hard eject for each device; throws only when every eject fails.
  static func hardEjectExternalDevices(
    _ devices: [String],
    eject: (String) throws -> Void
  ) throws {
    guard !devices.isEmpty else { return }

    var failures: [String] = []
    for device in devices {
      do {
        try eject(device)
      } catch {
        failures.append(device)
        Log.warning("Hard eject failed for \(device)", category: .security)
      }
    }

    if failures.count == devices.count {
      throw NetworkActionError.commandFailed(
        action: .ejectRemovableVolumes,
        message: "Could not eject: \(failures.joined(separator: ", "))"
      )
    }
  }

  /// Parses `/dev/diskN` identifiers from `diskutil list external physical` output.
  static func parseExternalPhysicalDiskDevices(from output: String) -> [String] {
    output.split(separator: "\n").compactMap { line in
      let trimmed = String(line).trimmingCharacters(in: .whitespaces)
      guard trimmed.hasPrefix("/dev/disk") else { return nil }
      return trimmed.split(separator: " ", maxSplits: 1).first.map(String.init)
    }
  }

  public func unmountCryptomatorVolumes() throws {
    try runShell("/usr/bin/osascript", args: ["-e", "tell application \"Cryptomator\" to quit"])
    try? runShell("/usr/bin/killall", args: ["Cryptomator"])

    let mountOutput: String
    do {
      mountOutput = try captureShell("/sbin/mount", args: [])
    } catch {
      throw NetworkActionError.commandFailed(
        action: .unmountCryptomatorVolumes,
        message: "mount listing failed"
      )
    }

    let mountPoints = CryptomatorMountParser.parseMountPoints(from: mountOutput)
    try Self.hardEjectExternalDevices(mountPoints) { mountPoint in
      try runShell("/usr/sbin/diskutil", args: ["unmount", "force", mountPoint])
    }
  }

  public func disableBluetooth() throws {
    guard let blueutil = Self.blueutilExecutablePath() else {
      throw NetworkActionError.commandFailed(
        action: .disableBluetooth,
        message: "blueutil not found — install with: brew install blueutil"
      )
    }
    try runShell(blueutil, args: ["-p", "0"])
  }

  static func blueutilExecutablePath() -> String? {
    let candidates = ["/opt/homebrew/bin/blueutil", "/usr/local/bin/blueutil"]
    for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
      return path
    }
    return nil
  }

  public func disableWiFi() throws {
    let interface = try wifiInterfaceName()
    try runShell("/usr/sbin/networksetup", args: ["-setairportpower", interface, "off"])
  }

  private func wifiInterfaceName() throws -> String {
    let output = try captureShell("/usr/sbin/networksetup", args: ["-listallhardwareports"])
    let blocks = output.components(separatedBy: "\n\n")
    for block in blocks where block.contains("Hardware Port: Wi-Fi")
      || block.contains("Hardware Port: AirPort") {
      for line in block.components(separatedBy: "\n") where line.hasPrefix("Device: ") {
        return String(line.dropFirst("Device: ".count)).trimmingCharacters(in: .whitespaces)
      }
    }
    return "en0"
  }

  private func runShell(_ launchPath: String, args: [String]) throws {
    _ = try captureShell(launchPath, args: args)
  }

  private func captureShell(_ launchPath: String, args: [String]) throws -> String {
    if let processRunner {
      try processRunner(launchPath, args)
      return ""
    }

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
      throw NetworkActionError.commandFailed(
        action: .clearSSHAgent,
        message: output.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    }
    return output
  }
}
