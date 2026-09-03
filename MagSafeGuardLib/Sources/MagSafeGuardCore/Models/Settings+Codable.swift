//
//  Settings+Codable.swift
//  MagSafeGuardCore
//

import Foundation
import MagSafeGuardDomain

extension Settings {
  enum CodingKeys: String, CodingKey {
    case gracePeriodDuration
    case allowGracePeriodCancellation
    case securityActions
    case alarmVolume
    case boostSystemVolumeForAlarm
    case alarmDurationSeconds
    case scriptTimeBudgetSeconds
    case autoArmEnabled
    case autoArmByLocation
    case trustedNetworks
    case autoArmOnUntrustedNetwork
    case showStatusNotifications
    case showSecurityAlerts
    case panicLegalNoticeAccepted
    case playCriticalAlertSound
    case operationProfile
    case launchAtLogin
    case showInDock
    case menuBarIconAppearance
    case restoreArmedStateOnLaunch
    case hasCompletedOnboarding
    case hasSeenFirstArmAdvisory
    case enabledNetworkActions
    case webhookURL
    case remoteTrigger
    case customScripts
    case debugLoggingEnabled
    case iCloudSyncEnabled
    case iCloudDataLimitMB
    case iCloudDataAgeLimitDays
    case paranoid
  }

  public init(from decoder: Decoder) throws {
    let defaults = Settings()
    let container = try decoder.container(keyedBy: CodingKeys.self)

    gracePeriodDuration =
      try container.decodeIfPresent(TimeInterval.self, forKey: .gracePeriodDuration)
      ?? defaults.gracePeriodDuration
    allowGracePeriodCancellation =
      try container.decodeIfPresent(Bool.self, forKey: .allowGracePeriodCancellation)
      ?? defaults.allowGracePeriodCancellation
    securityActions =
      try container.decodeIfPresent([SecurityActionType].self, forKey: .securityActions)
      ?? defaults.securityActions
    alarmVolume = try container.decodeIfPresent(Float.self, forKey: .alarmVolume) ?? defaults.alarmVolume
    boostSystemVolumeForAlarm =
      try container.decodeIfPresent(Bool.self, forKey: .boostSystemVolumeForAlarm)
      ?? defaults.boostSystemVolumeForAlarm
    alarmDurationSeconds =
      try container.decodeIfPresent(TimeInterval.self, forKey: .alarmDurationSeconds)
      ?? defaults.alarmDurationSeconds
    scriptTimeBudgetSeconds =
      try container.decodeIfPresent(TimeInterval.self, forKey: .scriptTimeBudgetSeconds)
      ?? defaults.scriptTimeBudgetSeconds
    autoArmEnabled =
      try container.decodeIfPresent(Bool.self, forKey: .autoArmEnabled) ?? defaults.autoArmEnabled
    autoArmByLocation =
      try container.decodeIfPresent(Bool.self, forKey: .autoArmByLocation) ?? defaults.autoArmByLocation
    trustedNetworks =
      try container.decodeIfPresent([String].self, forKey: .trustedNetworks) ?? defaults.trustedNetworks
    autoArmOnUntrustedNetwork =
      try container.decodeIfPresent(Bool.self, forKey: .autoArmOnUntrustedNetwork)
      ?? defaults.autoArmOnUntrustedNetwork
    showStatusNotifications =
      try container.decodeIfPresent(Bool.self, forKey: .showStatusNotifications)
      ?? defaults.showStatusNotifications
    showSecurityAlerts =
      try container.decodeIfPresent(Bool.self, forKey: .showSecurityAlerts)
      ?? defaults.showSecurityAlerts
    panicLegalNoticeAccepted =
      try container.decodeIfPresent(Bool.self, forKey: .panicLegalNoticeAccepted)
      ?? defaults.panicLegalNoticeAccepted
    playCriticalAlertSound =
      try container.decodeIfPresent(Bool.self, forKey: .playCriticalAlertSound)
      ?? defaults.playCriticalAlertSound
    operationProfile =
      try container.decodeIfPresent(OperationProfile.self, forKey: .operationProfile)
      ?? defaults.operationProfile
    launchAtLogin =
      try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? defaults.launchAtLogin
    showInDock = try container.decodeIfPresent(Bool.self, forKey: .showInDock) ?? defaults.showInDock
    menuBarIconAppearance =
      try container.decodeIfPresent(MenuBarIconAppearance.self, forKey: .menuBarIconAppearance)
      ?? defaults.menuBarIconAppearance
    restoreArmedStateOnLaunch =
      try container.decodeIfPresent(Bool.self, forKey: .restoreArmedStateOnLaunch)
      ?? defaults.restoreArmedStateOnLaunch
    hasCompletedOnboarding =
      try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding)
      ?? defaults.hasCompletedOnboarding
    hasSeenFirstArmAdvisory =
      try container.decodeIfPresent(Bool.self, forKey: .hasSeenFirstArmAdvisory)
      ?? defaults.hasSeenFirstArmAdvisory
    enabledNetworkActions =
      try container.decodeIfPresent([NetworkActionType].self, forKey: .enabledNetworkActions)
      ?? defaults.enabledNetworkActions
    webhookURL = try container.decodeIfPresent(String.self, forKey: .webhookURL) ?? defaults.webhookURL
    remoteTrigger =
      try container.decodeIfPresent(RemoteTriggerSettings.self, forKey: .remoteTrigger)
      ?? defaults.remoteTrigger
    customScripts =
      try container.decodeIfPresent([String].self, forKey: .customScripts) ?? defaults.customScripts
    debugLoggingEnabled =
      try container.decodeIfPresent(Bool.self, forKey: .debugLoggingEnabled)
      ?? defaults.debugLoggingEnabled
    iCloudSyncEnabled =
      try container.decodeIfPresent(Bool.self, forKey: .iCloudSyncEnabled)
      ?? defaults.iCloudSyncEnabled
    iCloudDataLimitMB =
      try container.decodeIfPresent(Double.self, forKey: .iCloudDataLimitMB)
      ?? defaults.iCloudDataLimitMB
    iCloudDataAgeLimitDays =
      try container.decodeIfPresent(Double.self, forKey: .iCloudDataAgeLimitDays)
      ?? defaults.iCloudDataAgeLimitDays
    paranoid =
      try container.decodeIfPresent(ParanoidConfiguration.self, forKey: .paranoid) ?? defaults.paranoid
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(gracePeriodDuration, forKey: .gracePeriodDuration)
    try container.encode(allowGracePeriodCancellation, forKey: .allowGracePeriodCancellation)
    try container.encode(securityActions, forKey: .securityActions)
    try container.encode(alarmVolume, forKey: .alarmVolume)
    try container.encode(boostSystemVolumeForAlarm, forKey: .boostSystemVolumeForAlarm)
    try container.encode(alarmDurationSeconds, forKey: .alarmDurationSeconds)
    try container.encode(scriptTimeBudgetSeconds, forKey: .scriptTimeBudgetSeconds)
    try container.encode(autoArmEnabled, forKey: .autoArmEnabled)
    try container.encode(autoArmByLocation, forKey: .autoArmByLocation)
    try container.encode(trustedNetworks, forKey: .trustedNetworks)
    try container.encode(autoArmOnUntrustedNetwork, forKey: .autoArmOnUntrustedNetwork)
    try container.encode(showStatusNotifications, forKey: .showStatusNotifications)
    try container.encode(showSecurityAlerts, forKey: .showSecurityAlerts)
    try container.encode(panicLegalNoticeAccepted, forKey: .panicLegalNoticeAccepted)
    try container.encode(playCriticalAlertSound, forKey: .playCriticalAlertSound)
    try container.encode(operationProfile, forKey: .operationProfile)
    try container.encode(launchAtLogin, forKey: .launchAtLogin)
    try container.encode(showInDock, forKey: .showInDock)
    try container.encode(menuBarIconAppearance, forKey: .menuBarIconAppearance)
    try container.encode(restoreArmedStateOnLaunch, forKey: .restoreArmedStateOnLaunch)
    try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
    try container.encode(hasSeenFirstArmAdvisory, forKey: .hasSeenFirstArmAdvisory)
    try container.encode(enabledNetworkActions, forKey: .enabledNetworkActions)
    try container.encode(webhookURL, forKey: .webhookURL)
    try container.encode(remoteTrigger, forKey: .remoteTrigger)
    try container.encode(customScripts, forKey: .customScripts)
    try container.encode(debugLoggingEnabled, forKey: .debugLoggingEnabled)
    try container.encode(iCloudSyncEnabled, forKey: .iCloudSyncEnabled)
    try container.encode(iCloudDataLimitMB, forKey: .iCloudDataLimitMB)
    try container.encode(iCloudDataAgeLimitDays, forKey: .iCloudDataAgeLimitDays)
    try container.encode(paranoid, forKey: .paranoid)
  }
}
