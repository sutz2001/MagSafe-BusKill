//
//  ParanoidWipePathSuggestions.swift
//  MagSafeGuardCore
//

import Foundation

/// Catalog of optional wipe-path suggestions. Never applied automatically —
/// the user must pick items in the UI. Includes severe user trees (Home,
/// Documents, Desktop, Downloads) plus vault-style folders.
public enum ParanoidWipePathSuggestions {

  public struct Item: Equatable, Sendable, Identifiable {
    public let id: String
    /// Localization key for the checkbox label (e.g. `settings.paranoid.suggest.cryptomator`).
    public let titleKey: String
    /// Absolute path after expanding `~` / home directory.
    public let absolutePath: String
    public let exists: Bool

    public init(id: String, titleKey: String, absolutePath: String, exists: Bool) {
      self.id = id
      self.titleKey = titleKey
      self.absolutePath = absolutePath
      self.exists = exists
    }
  }

  /// Relative-to-home templates. Broad user trees are included on purpose (paranoid opt-in).
  public static let homeRelativeTemplates: [(id: String, titleKey: String, relativePath: String)] = [
    ("home", "settings.paranoid.suggest.home", ""),
    ("documents", "settings.paranoid.suggest.documents", "Documents"),
    ("desktop", "settings.paranoid.suggest.desktop", "Desktop"),
    ("downloads", "settings.paranoid.suggest.downloads", "Downloads"),
    ("cryptomator", "settings.paranoid.suggest.cryptomator", "Cryptomator"),
    ("veracrypt", "settings.paranoid.suggest.veracrypt", "VeraCrypt"),
    ("secure", "settings.paranoid.suggest.secure", "Secure"),
    ("vault", "settings.paranoid.suggest.vault", "Vault"),
    (
      "cryptomatorSupport",
      "settings.paranoid.suggest.cryptomatorSupport",
      "Library/Application Support/Cryptomator"
    ),
  ]

  /// Resolves templates under `homeDirectory`. Only returns existing, non-forbidden paths.
  public static func available(
    homeDirectory: String = NSHomeDirectory(),
    fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
  ) -> [Item] {
    let home = (homeDirectory as NSString).standardizingPath
    return homeRelativeTemplates.compactMap { template in
      let absolute: String
      if template.relativePath.isEmpty {
        absolute = home
      } else {
        absolute = (home as NSString).appendingPathComponent(template.relativePath)
      }
      let standardized = (absolute as NSString).standardizingPath
      guard standardized.hasPrefix("/"),
        !ParanoidConfiguration.isForbiddenWipePath(standardized),
        fileExists(standardized)
      else { return nil }
      return Item(
        id: template.id,
        titleKey: template.titleKey,
        absolutePath: standardized,
        exists: true
      )
    }
  }

  /// Appends selected absolute paths that are not already configured.
  public static func merge(
    selectedPaths: [String],
    into existing: [String]
  ) -> [String] {
    var result = existing
    let seen = Set(existing)
    for path in ParanoidConfiguration.sanitizedUniquePaths(selectedPaths)
    where !seen.contains(path) && !result.contains(path) {
      result.append(path)
    }
    return result
  }
}
