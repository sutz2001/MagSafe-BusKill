//
//  SecurityActionsSettingsSync.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore
import MagSafeGuardDomain

/// Maps `Settings` security configuration to `SecurityActionsService` runtime config.
enum SecurityActionsSettingsSync {

  static func sync(
    from settings: Settings,
    to service: SecurityActionsService = .shared
  ) {
    let ordered = settings.securityActions
    guard !ordered.isEmpty else { return }

    var config = service.configuration
    config.enabledActions = Set(ordered)
    config.actionOrder = ordered

    if settings.securityActions.contains(.customScript) {
      let paths = settings.customScripts.filter { !$0.isEmpty }
      config.customScriptPaths = paths
      config.customScriptPath = paths.first
    } else {
      config.customScriptPaths = []
      config.customScriptPath = nil
    }

    service.applyConfiguration(config)
  }
}
