//
//  NetworkActionType+Localized.swift
//  MagSafe Guard
//

import MagSafeGuardCore

extension NetworkActionType {
  /// User-facing localized name for settings toggles.
  var localizedName: String {
    switch self {
    case .webhook: return L10n.tr("networkAction.webhook.name")
    case .disconnectVPN: return L10n.tr("networkAction.disconnectVPN.name")
    case .clearSSHAgent: return L10n.tr("networkAction.clearSSHAgent.name")
    case .disableWiFi: return L10n.tr("networkAction.disableWiFi.name")
    }
  }

  /// Short name for event log entries.
  var localizedLogName: String { localizedName }
}
