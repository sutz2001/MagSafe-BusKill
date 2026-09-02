//
//  BundledTriggerScripts.swift
//  MagSafe Guard
//

import Foundation

/// Trigger scripts shipped inside the app bundle (`Resources/TriggerScripts/`).
enum BundledTriggerScripts {

  static let subdirectory = "TriggerScripts"
  static let outdatedSubdirectory = "outdated"
  static let userScriptsFolderName = ".magsafe/scripts"

  /// Scripts superseded by built-in network actions — kept in bundle for reference, not installed.
  static let outdatedScriptNames: Set<String> = [
    "clear-clipboard.sh",
    "cryptomator-umount-best-effort.sh",
    "disable-bluetooth-best-effort.sh",
    "eject-removable-volumes.sh",
  ]

  struct InstallResult: Equatable {
    let copiedCount: Int
    let destinationDirectory: String
    let installedPaths: [String]
  }

  enum InstallError: LocalizedError {
    case bundleScriptsMissing
    case copyFailed(path: String, underlying: Error)

    var errorDescription: String? {
      switch self {
      case .bundleScriptsMissing:
        return "Bundled trigger scripts were not found in the app."
      case .copyFailed(let path, let underlying):
        return "Failed to copy \(path): \(underlying.localizedDescription)"
      }
    }
  }

  /// `~/.magsafe/scripts/`
  static func userScriptsDirectoryURL(homeDirectory: String = NSHomeDirectory()) -> URL {
    URL(fileURLWithPath: homeDirectory, isDirectory: true)
      .appendingPathComponent(userScriptsFolderName, isDirectory: true)
  }

  /// Directory containing `.sh` examples inside `MagSafeGuard.app`, when present.
  static func directoryURL(in bundle: Bundle = .main) -> URL? {
    guard let resourceURL = bundle.resourceURL else { return nil }
    let url = resourceURL.appendingPathComponent(subdirectory, isDirectory: true)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
  }

  /// Lists installable `.sh` trigger examples shipped with the app.
  static func bundledScriptURLs(in bundle: Bundle = .main) -> [URL] {
    installableScriptURLs(from: discoverBundledScriptURLs(in: bundle))
  }

  /// All `.sh` files in the bundle (including outdated); for diagnostics only.
  static func allBundledScriptURLs(in bundle: Bundle = .main) -> [URL] {
    discoverBundledScriptURLs(in: bundle)
  }

  private static func discoverBundledScriptURLs(in bundle: Bundle) -> [URL] {
    var found: [URL] = []
    if let directory = directoryURL(in: bundle) {
      found.append(contentsOf: listShellScripts(in: directory) ?? [])
      let outdated = directory.appendingPathComponent(outdatedSubdirectory, isDirectory: true)
      found.append(contentsOf: listShellScripts(in: outdated) ?? [])
    }
    if let resourceURL = bundle.resourceURL {
      found.append(contentsOf: listShellScripts(in: resourceURL) ?? [])
      let outdated = resourceURL.appendingPathComponent(outdatedSubdirectory, isDirectory: true)
      found.append(contentsOf: listShellScripts(in: outdated) ?? [])
    }
    return deduplicatedScripts(found)
  }

  static func installableScriptURLs(from urls: [URL]) -> [URL] {
    urls
      .filter { !isOutdatedScript($0) }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
  }

  static func isOutdatedScript(_ url: URL) -> Bool {
    outdatedScriptNames.contains(url.lastPathComponent)
      || url.deletingLastPathComponent().lastPathComponent == outdatedSubdirectory
  }

  private static func deduplicatedScripts(_ urls: [URL]) -> [URL] {
    var seen = Set<String>()
    return urls.filter { url in
      let key = url.lastPathComponent
      guard !seen.contains(key) else { return false }
      seen.insert(key)
      return true
    }
  }

  private static func listShellScripts(in directory: URL) -> [URL]? {
    guard let entries = try? FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    ) else { return nil }
    return entries
      .filter { $0.pathExtension == "sh" }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
  }

  /// Copies `.sh` files into the user scripts directory (chmod 700). Overwrites same filenames.
  static func installToUserScriptsDirectory(
    fileManager: FileManager = .default,
    bundle: Bundle = .main,
    homeDirectory: String = NSHomeDirectory()
  ) throws -> InstallResult {
    let sources = bundledScriptURLs(in: bundle)
    guard !sources.isEmpty else { throw InstallError.bundleScriptsMissing }
    let destination = userScriptsDirectoryURL(homeDirectory: homeDirectory)
    return try installScripts(from: sources, to: destination, fileManager: fileManager)
  }

  static func installScripts(
    from sources: [URL],
    to destination: URL,
    fileManager: FileManager = .default
  ) throws -> InstallResult {
    try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

    var installed: [String] = []
    for source in sources {
      let target = destination.appendingPathComponent(source.lastPathComponent)
      do {
        if fileManager.fileExists(atPath: target.path) {
          try fileManager.removeItem(at: target)
        }
        try fileManager.copyItem(at: source, to: target)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: target.path)
        installed.append(target.path)
      } catch {
        throw InstallError.copyFailed(path: source.lastPathComponent, underlying: error)
      }
    }

    return InstallResult(
      copiedCount: installed.count,
      destinationDirectory: destination.path,
      installedPaths: installed
    )
  }

  /// Adds installed script paths to Settings and enables the custom-script security action.
  static func registerInstalledPathsInSettings(
    _ paths: [String],
    settingsManager: UserDefaultsManager = .shared
  ) {
    guard !paths.isEmpty else { return }
    settingsManager.updateSettings { settings in
      for path in paths where !path.isEmpty && !settings.customScripts.contains(path) {
        settings.customScripts.append(path)
      }
      if !settings.securityActions.contains(.customScript) {
        settings.securityActions.append(.customScript)
      }
    }
  }

  /// Repo / dev path (not the installed app).
  static var repositoryDirectoryPath: String {
    "MagSafeGuard/Resources/TriggerScripts"
  }
}
