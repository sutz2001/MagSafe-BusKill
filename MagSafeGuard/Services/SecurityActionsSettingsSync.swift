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
    let ordered = settings.securityActions.compactMap(mapAction)
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

  static func mapAction(_ type: SecurityActionType) -> SecurityActionsService.SecurityAction? {
    switch type {
    case .lockScreen: return .screenLock
    case .soundAlarm: return .soundAlarm
    case .forceLogout: return .forceLogout
    case .shutdown: return .shutdown
    case .customScript: return .customScript
    }
  }
}
