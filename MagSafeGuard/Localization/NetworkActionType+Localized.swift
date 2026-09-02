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
    case .clearClipboard: return L10n.tr("networkAction.clearClipboard.name")
    case .ejectRemovableVolumes: return L10n.tr("networkAction.ejectRemovableVolumes.name")
    case .unmountCryptomatorVolumes: return L10n.tr("networkAction.unmountCryptomatorVolumes.name")
    case .disableBluetooth: return L10n.tr("networkAction.disableBluetooth.name")
    case .disableWiFi: return L10n.tr("networkAction.disableWiFi.name")
    }
  }

  /// Short name for event log entries.
  var localizedLogName: String { localizedName }

  /// Risk hint shown under the toggle in Settings.
  var localizedRiskCaption: String {
    switch self {
    case .webhook: return L10n.tr("networkAction.webhook.riskCaption")
    case .disconnectVPN: return L10n.tr("networkAction.disconnectVPN.riskCaption")
    case .clearSSHAgent: return L10n.tr("networkAction.clearSSHAgent.riskCaption")
    case .clearClipboard: return L10n.tr("networkAction.clearClipboard.riskCaption")
    case .ejectRemovableVolumes: return L10n.tr("networkAction.ejectRemovableVolumes.riskCaption")
    case .unmountCryptomatorVolumes: return L10n.tr("networkAction.unmountCryptomatorVolumes.riskCaption")
    case .disableBluetooth: return L10n.tr("networkAction.disableBluetooth.riskCaption")
    case .disableWiFi: return L10n.tr("networkAction.disableWiFi.riskCaption")
    }
  }
}
