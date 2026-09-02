import Foundation
import MagSafeGuardCore

@main
struct MagSafeGuardCLI {
  static func main() {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let command = args.first else {
      printUsage()
      exit(1)
    }

    switch command {
    case "status":
      runStatus()
    case "arm", "disarm", "apply-profile":
      runCommand(command: command, args: Array(args.dropFirst()))
    case "-h", "--help", "help":
      printUsage()
    default:
      fputs("Unknown command: \(command)\n", stderr)
      printUsage()
      exit(1)
    }
  }

  private static func printUsage() {
    let text = """
    MagSafe Guard CLI — control a running MagSafe Guard instance

    Usage:
      MagSafeGuardCLI status
      MagSafeGuardCLI arm
      MagSafeGuardCLI disarm
      MagSafeGuardCLI apply-profile <beginner|normal|discreet|panic>

    Notes:
      - MagSafe Guard must be running (menu bar).
      - arm/disarm trigger Touch ID / password in the app.
      - status reads ~/Library/Application Support/MagSafeGuard/cli-status.json
    """
    print(text)
  }

  private static func runStatus() {
    postCommand("status", profile: nil)

    let url = CLIIPC.statusFileURL()
    guard let data = try? Data(contentsOf: url),
      let json = try? JSONDecoder().decode(CLIStatusSnapshot.self, from: data)
    else {
      fputs("Status unavailable — is MagSafe Guard running?\n", stderr)
      exit(2)
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    if let out = try? encoder.encode(json), let text = String(data: out, encoding: .utf8) {
      print(text)
    }
  }

  private static func runCommand(command: String, args: [String]) {
    var profile: String?
    if command == "apply-profile" {
      guard let name = args.first else {
        fputs("Missing profile name\n", stderr)
        exit(1)
      }
      profile = name
    }

    postCommand(command, profile: profile)
    waitForResponse()
  }

  private static func postCommand(_ command: String, profile: String?) {
    var userInfo: [String: Any] = ["command": command]
    if let profile {
      userInfo["profile"] = profile
    }
    DistributedNotificationCenter.default().post(
      name: CLIIPC.commandNotification,
      object: nil,
      userInfo: userInfo
    )
  }

  private static func waitForResponse() {
    let semaphore = DispatchSemaphore(value: 0)
    var observer: NSObjectProtocol?
    observer = DistributedNotificationCenter.default().addObserver(
      forName: CLIIPC.responseNotification,
      object: nil,
      queue: nil
    ) { notification in
      let ok = notification.userInfo?["ok"] as? Bool ?? false
      let message = notification.userInfo?["message"] as? String ?? "no message"
      if ok {
        print(message)
      } else {
        fputs("\(message)\n", stderr)
      }
      if let observer {
        DistributedNotificationCenter.default().removeObserver(observer)
      }
      semaphore.signal()
    }

    let result = semaphore.wait(timeout: .now() + 30)
    if result == .timedOut {
      fputs("Timed out waiting for MagSafe Guard\n", stderr)
      exit(3)
    }
  }
}
