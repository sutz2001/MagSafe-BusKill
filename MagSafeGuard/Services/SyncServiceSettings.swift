//
//  SyncServiceSettings.swift
//  MagSafe Guard
//
//  Created on 2025-07-31.
//

import CloudKit
import Foundation
import MagSafeGuardCore
import MagSafeGuardDomain

/// Handles settings synchronization with CloudKit
final class SyncServiceSettings {
  private let container: CKContainer
  private let database: CKDatabase
  private let recordType = "Settings"
  private let settingsRecordID = CKRecord.ID(recordName: "UserSettings")

  init(container: CKContainer) {
    self.container = container
    self.database = container.privateCloudDatabase
  }

  /// Sync settings to iCloud
  func syncSettings() async throws {
    Log.info("Syncing settings to iCloud", category: .general)

    let settings = UserDefaultsManager.shared.settings
    let record = try await fetchOrCreateSettingsRecord()

    // Update record with current settings
    record["gracePeriodDuration"] = settings.gracePeriodDuration
    record["allowGracePeriodCancellation"] = settings.allowGracePeriodCancellation ? 1 : 0

    // Encode security actions as a comma-separated string
    let actionsString = settings.securityActions.map { $0.rawValue }.joined(separator: ",")
    record["securityActions"] = actionsString
    record["alarmVolume"] = Double(settings.alarmVolume)
    record["boostSystemVolumeForAlarm"] = settings.boostSystemVolumeForAlarm ? 1 : 0
    record["alarmDurationSeconds"] = settings.alarmDurationSeconds
    record["scriptTimeBudgetSeconds"] = settings.scriptTimeBudgetSeconds

    // Auto-arm settings
    record["autoArmEnabled"] = settings.autoArmEnabled ? 1 : 0
    record["autoArmByLocation"] = settings.autoArmByLocation ? 1 : 0
    record["autoArmOnUntrustedNetwork"] = settings.autoArmOnUntrustedNetwork ? 1 : 0

    // Encode trusted networks as JSON
    if let trustedNetworksData = try? JSONEncoder().encode(settings.trustedNetworks) {
      record["trustedNetworks"] = String(data: trustedNetworksData, encoding: .utf8)
    }

    // Notification settings
    record["showStatusNotifications"] = settings.showStatusNotifications ? 1 : 0
    record["showSecurityAlerts"] = settings.showSecurityAlerts ? 1 : 0
    record["playCriticalAlertSound"] = settings.playCriticalAlertSound ? 1 : 0
    record["panicLegalNoticeAccepted"] = settings.panicLegalNoticeAccepted ? 1 : 0
    if let paranoidData = try? JSONEncoder().encode(settings.paranoid),
      let paranoidJSON = String(data: paranoidData, encoding: .utf8) {
      record["paranoid"] = paranoidJSON
    }

    // General settings
    record["launchAtLogin"] = settings.launchAtLogin ? 1 : 0
    record["showInDock"] = settings.showInDock ? 1 : 0
    record["menuBarIconAppearance"] = settings.menuBarIconAppearance.rawValue

    // Advanced settings
    if let customScriptsData = try? JSONEncoder().encode(settings.customScripts) {
      record["customScripts"] = String(data: customScriptsData, encoding: .utf8)
    }
    record["debugLoggingEnabled"] = settings.debugLoggingEnabled ? 1 : 0

    // Network actions + remote trigger (v0.4.x)
    let networkActionsString = settings.enabledNetworkActions.map(\.rawValue).joined(separator: ",")
    record["enabledNetworkActions"] = networkActionsString
    record["webhookURL"] = settings.webhookURL
    if let remoteData = try? JSONEncoder().encode(settings.remoteTrigger) {
      record["remoteTrigger"] = String(data: remoteData, encoding: .utf8)
    }

    // Cloud sync settings
    record["iCloudSyncEnabled"] = settings.iCloudSyncEnabled ? 1 : 0
    record["iCloudDataLimitMB"] = settings.iCloudDataLimitMB
    record["iCloudDataAgeLimitDays"] = settings.iCloudDataAgeLimitDays

    record["lastModified"] = Date()

    // Save to CloudKit
    try await database.save(record)
    Log.info("Settings synced successfully", category: .general)
  }

  /// Download settings from iCloud
  func downloadSettings() async throws {
    Log.info("Downloading settings from iCloud", category: .general)

    do {
      let record = try await database.record(for: settingsRecordID)
      applySettingsFromRecord(record)
      Log.info("Settings downloaded successfully", category: .general)
    } catch let error as CKError where error.code == .unknownItem {
      // No settings in cloud yet, use local settings
      Log.info("No cloud settings found, using local settings", category: .general)
    }
  }

  // MARK: - Private Methods

  private func fetchOrCreateSettingsRecord() async throws -> CKRecord {
    do {
      return try await database.record(for: settingsRecordID)
    } catch let error as CKError where error.code == .unknownItem {
      // Record doesn't exist, create it
      return CKRecord(recordType: recordType, recordID: settingsRecordID)
    }
  }

  private func applySettingsFromRecord(_ record: CKRecord) {
    let manager = UserDefaultsManager.shared

    // Apply numeric settings
    applyNumericSettings(from: record, to: manager)

    // Apply boolean settings
    applyBooleanSettings(from: record, to: manager)

    // Apply complex settings
    applyComplexSettings(from: record, to: manager)
  }

  private func applyNumericSettings(from record: CKRecord, to manager: UserDefaultsManager) {
    let numericMappings: [(key: String, keyPath: WritableKeyPath<Settings, TimeInterval>)] = [
      ("gracePeriodDuration", \.gracePeriodDuration)
    ]

    for mapping in numericMappings {
      if let value = record[mapping.key] as? TimeInterval {
        manager.updateSetting(mapping.keyPath, value: value)
      }
    }

    // Apply Double settings
    let doubleMappings: [(key: String, keyPath: WritableKeyPath<Settings, Double>)] = [
      ("iCloudDataLimitMB", \.iCloudDataLimitMB),
      ("iCloudDataAgeLimitDays", \.iCloudDataAgeLimitDays)
    ]

    for mapping in doubleMappings {
      if let value = record[mapping.key] as? Double {
        manager.updateSetting(mapping.keyPath, value: value)
      }
    }

    if let alarmVolume = record["alarmVolume"] as? Double {
      manager.updateSetting(\.alarmVolume, value: Float(alarmVolume))
    }

    if let alarmDuration = record["alarmDurationSeconds"] as? TimeInterval {
      manager.updateSetting(\.alarmDurationSeconds, value: alarmDuration)
    }
    if let scriptBudget = record["scriptTimeBudgetSeconds"] as? TimeInterval {
      manager.updateSetting(\.scriptTimeBudgetSeconds, value: scriptBudget)
    }
  }

  private func applyBooleanSettings(from record: CKRecord, to manager: UserDefaultsManager) {
    let booleanMappings: [(key: String, keyPath: WritableKeyPath<Settings, Bool>)] = [
      ("allowGracePeriodCancellation", \.allowGracePeriodCancellation),
      ("autoArmEnabled", \.autoArmEnabled),
      ("autoArmByLocation", \.autoArmByLocation),
      ("autoArmOnUntrustedNetwork", \.autoArmOnUntrustedNetwork),
      ("showStatusNotifications", \.showStatusNotifications),
      ("showSecurityAlerts", \.showSecurityAlerts),
      ("playCriticalAlertSound", \.playCriticalAlertSound),
      ("boostSystemVolumeForAlarm", \.boostSystemVolumeForAlarm),
      ("panicLegalNoticeAccepted", \.panicLegalNoticeAccepted),
      ("launchAtLogin", \.launchAtLogin),
      ("showInDock", \.showInDock),
      ("debugLoggingEnabled", \.debugLoggingEnabled),
      ("iCloudSyncEnabled", \.iCloudSyncEnabled)
    ]

    for mapping in booleanMappings {
      if let value = record[mapping.key] as? Int {
        manager.updateSetting(mapping.keyPath, value: value == 1)
      }
    }
  }

  private func applyComplexSettings(from record: CKRecord, to manager: UserDefaultsManager) {
    // Decode security actions
    if let actionsString = record["securityActions"] as? String {
      let actionStrings = actionsString.split(separator: ",").map { String($0) }
      let actions = actionStrings.compactMap { SecurityActionType(rawValue: $0) }
      if !actions.isEmpty {
        manager.updateSetting(\.securityActions, value: actions)
      }
    }

    // Decode trusted networks
    if let trustedNetworksString = record["trustedNetworks"] as? String,
      let data = trustedNetworksString.data(using: .utf8),
      let networks = try? JSONDecoder().decode([String].self, from: data) {
      manager.updateSetting(\.trustedNetworks, value: networks)
    }

    // Decode custom scripts
    if let customScriptsString = record["customScripts"] as? String,
      let data = customScriptsString.data(using: .utf8),
      let scripts = try? JSONDecoder().decode([String].self, from: data) {
      manager.updateSetting(\.customScripts, value: scripts)
    }

    if let networkActionsString = record["enabledNetworkActions"] as? String, !networkActionsString.isEmpty {
      let actions = networkActionsString.split(separator: ",").compactMap {
        NetworkActionType(rawValue: String($0))
      }
      if !actions.isEmpty {
        manager.updateSetting(\.enabledNetworkActions, value: actions)
      }
    }

    if let webhookURL = record["webhookURL"] as? String {
      manager.updateSetting(\.webhookURL, value: webhookURL)
    }

    if let remoteString = record["remoteTrigger"] as? String,
      let data = remoteString.data(using: .utf8),
      let remote = try? JSONDecoder().decode(RemoteTriggerSettings.self, from: data) {
      manager.updateSetting(\.remoteTrigger, value: remote)
    }

    if let appearanceRaw = record["menuBarIconAppearance"] as? String,
      let appearance = MenuBarIconAppearance(rawValue: appearanceRaw) {
      manager.updateSetting(\.menuBarIconAppearance, value: appearance)
    }

    if let paranoidString = record["paranoid"] as? String,
      let data = paranoidString.data(using: .utf8),
      let paranoid = try? JSONDecoder().decode(ParanoidConfiguration.self, from: data) {
      manager.updateSetting(\.paranoid, value: paranoid)
    }
  }
}
