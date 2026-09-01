//
//  CloudSyncUIAvailability.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore
import Security

/// Whether iCloud sync UI should be shown (requires CloudKit entitlement + feature flag).
enum CloudSyncUIAvailability {

  static var isTabVisible: Bool {
    guard FeatureFlags.shared.isCloudSyncEnabled else { return false }
    return hasCloudKitEntitlement
  }

  private static var hasCloudKitEntitlement: Bool {
    guard let task = SecTaskCreateFromSelf(nil) else { return false }
    guard
      let raw = SecTaskCopyValueForEntitlement(
        task,
        "com.apple.developer.icloud-services" as CFString,
        nil
      )
    else {
      return false
    }

    if let services = raw as? [String] {
      return services.contains(where: { $0.caseInsensitiveCompare("CloudKit") == .orderedSame })
    }
    return false
  }
}
