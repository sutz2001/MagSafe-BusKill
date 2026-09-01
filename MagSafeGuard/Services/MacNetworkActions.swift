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

  public func postWebhook(url: URL, event: String, token: String?) throws {
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
    semaphore.wait()

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
