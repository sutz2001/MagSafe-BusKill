//
//  SecurityActionType+Localized.swift
//  MagSafe Guard
//
//  Localized display names for domain security action types.
//

import MagSafeGuardDomain

extension SecurityActionType {
  /// User-facing localized name for settings and menus.
  var localizedName: String {
    switch self {
    case .lockScreen: return L10n.tr("securityAction.lockScreen.name")
    case .soundAlarm: return L10n.tr("securityAction.soundAlarm.name")
    case .forceLogout: return L10n.tr("securityAction.forceLogout.name")
    case .shutdown: return L10n.tr("securityAction.shutdown.name")
    case .customScript: return L10n.tr("securityAction.customScript.name")
    }
  }

  /// User-facing localized description for settings.
  var localizedDescription: String {
    switch self {
    case .lockScreen: return L10n.tr("securityAction.lockScreen.description")
    case .soundAlarm: return L10n.tr("securityAction.soundAlarm.description")
    case .forceLogout: return L10n.tr("securityAction.forceLogout.description")
    case .shutdown: return L10n.tr("securityAction.shutdown.description")
    case .customScript: return L10n.tr("securityAction.customScript.description")
    }
  }

  /// One-line risk hint for the settings catalog.
  var localizedRiskCaption: String {
    switch self {
    case .lockScreen: return L10n.tr("securityAction.lockScreen.riskCaption")
    case .soundAlarm: return L10n.tr("securityAction.soundAlarm.riskCaption")
    case .forceLogout: return L10n.tr("securityAction.forceLogout.riskCaption")
    case .shutdown: return L10n.tr("securityAction.shutdown.riskCaption")
    case .customScript: return L10n.tr("securityAction.customScript.riskCaption")
    }
  }
}
