//
//  CloudSyncSettingsView.swift
//  MagSafe Guard
//
//  Created on 2025-07-28.
//
//  Settings view for configuring iCloud sync features
//

import Combine
import SwiftUI

/// Settings view for iCloud sync configuration
struct CloudSyncSettingsView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @StateObject private var syncService = SyncServiceFactory.create() ?? SyncService()
  @State private var isSyncing = false
  @State private var showingError = false
  @State private var errorMessage = ""

  var body: some View {
    Form {
      enableSection
      statusSection
      syncSection
      limitsSection
      dataSection
    }
    .formStyle(.grouped)
    .alert(L10n.tr("cloudSync.error.title"), isPresented: $showingError) {
      Button(L10n.tr("common.ok"), role: .cancel) {
        // Dismisses alert automatically
      }
    } message: {
      Text(errorMessage)
    }
  }

  private var statusSection: some View {
    Section(header: Label(L10n.tr("cloudSync.status.header"), systemImage: "cloud")) {
      HStack {
        Label(L10n.tr("cloudSync.status.label"), systemImage: syncService.syncStatus.symbolName)
        Spacer()
        Text(syncService.syncStatus.displayText)
          .foregroundColor(statusColor)
          .font(.caption)
      }

      if let lastSync = syncService.lastSyncDate {
        HStack {
          Label(L10n.tr("cloudSync.lastSync"), systemImage: "clock.fill")
          Spacer()
          Text(lastSync, style: .relative)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      if !syncService.isAvailable {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.orange)
            Text(l10n: "cloudSync.unavailable")
              .font(.subheadline)
          }
          Text(unavailabilityReason)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
      }
    }
  }

  private var syncSection: some View {
    Section(header: Label(L10n.tr("cloudSync.actions.header"), systemImage: "arrow.triangle.2.circlepath")) {
      HStack {
        Button(action: performManualSync) {
          Label(L10n.tr("cloudSync.syncNow"), systemImage: "arrow.triangle.2.circlepath")
        }
        .disabled(!syncService.isAvailable || isSyncing)

        if isSyncing {
          ProgressView()
            .scaleEffect(0.8)
            .padding(.leading, 8)
        }

        Spacer()
      }

      Text(l10n: "cloudSync.manualHint")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .disabled(!settingsManager.settings.iCloudSyncEnabled)
    .opacity(settingsManager.settings.iCloudSyncEnabled ? 1.0 : 0.6)
  }

  private var dataSection: some View {
    Section(header: Label(L10n.tr("cloudSync.data.header"), systemImage: "externaldrive.badge.icloud")) {
      // Settings sync
      HStack {
        Image(systemName: "gearshape.fill")
          .foregroundColor(.gray)
        VStack(alignment: .leading) {
          Text(l10n: "cloudSync.data.settings.title")
            .font(.subheadline)
          Text(l10n: "cloudSync.data.settings.caption")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      // Evidence sync
      HStack {
        Image(systemName: "camera.fill")
          .foregroundColor(.orange)
        VStack(alignment: .leading) {
          Text(l10n: "cloudSync.data.evidence.title")
            .font(.subheadline)
          Text(l10n: "cloudSync.data.evidence.caption")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      // Storage info
      HStack {
        Image(systemName: "lock.shield.fill")
          .foregroundColor(.green)
        VStack(alignment: .leading) {
          Text(l10n: "cloudSync.data.encrypted.title")
            .font(.subheadline)
          Text(l10n: "cloudSync.data.encrypted.caption")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .disabled(!settingsManager.settings.iCloudSyncEnabled)
    .opacity(settingsManager.settings.iCloudSyncEnabled ? 1.0 : 0.6)
  }

  private var enableSection: some View {
    Section(header: Label(L10n.tr("cloudSync.enable.header"), systemImage: "icloud.and.arrow.up")) {
      Toggle(
        isOn: Binding(
          get: { settingsManager.settings.iCloudSyncEnabled },
          set: { settingsManager.updateSetting(\.iCloudSyncEnabled, value: $0) }
        )
      ) {
        VStack(alignment: .leading, spacing: 4) {
          Text(l10n: "cloudSync.enable.title")
          Text(l10n: "cloudSync.enable.caption")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      .onChange(of: settingsManager.settings.iCloudSyncEnabled) { _, newValue in
        if newValue {
          // Enable CloudKit sync
          syncService.enableSync()

          // Trigger initial sync after a short delay
          Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
            try? await syncService.syncAll()
          }
        } else {
          // Disable CloudKit sync
          syncService.disableSync()
        }
      }
    }
  }

  private var limitsSection: some View {
    Section(header: Label(L10n.tr("cloudSync.limits.header"), systemImage: "internaldrive")) {
      // Data size limit
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(l10n: "cloudSync.limits.maxStorage")
          Spacer()
          Text(L10n.tr("cloudSync.limits.mbUnit", Int(settingsManager.settings.iCloudDataLimitMB)))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.secondary)
        }

        Slider(
          value: Binding(
            get: { settingsManager.settings.iCloudDataLimitMB },
            set: { settingsManager.updateSetting(\.iCloudDataLimitMB, value: $0) }
          ),
          in: 10...1000,
          step: 10
        ) {
          Text(l10n: "cloudSync.limits.maxStorage.slider")
        } minimumValueLabel: {
          Text("10")
            .font(.caption)
        } maximumValueLabel: {
          Text("1000")
            .font(.caption)
        }

        Text(l10n: "cloudSync.limits.maxStorage.hint")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      // Data age limit
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(l10n: "cloudSync.limits.retention")
          Spacer()
          Text(L10n.tr("cloudSync.limits.daysUnit", Int(settingsManager.settings.iCloudDataAgeLimitDays)))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.secondary)
        }

        Slider(
          value: Binding(
            get: { settingsManager.settings.iCloudDataAgeLimitDays },
            set: { settingsManager.updateSetting(\.iCloudDataAgeLimitDays, value: $0) }
          ),
          in: 7...365,
          step: 1
        ) {
          Text(l10n: "cloudSync.limits.retention.slider")
        } minimumValueLabel: {
          Text("7")
            .font(.caption)
        } maximumValueLabel: {
          Text("365")
            .font(.caption)
        }

        Text(l10n: "cloudSync.limits.retention.hint")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .disabled(!settingsManager.settings.iCloudSyncEnabled)
    .opacity(settingsManager.settings.iCloudSyncEnabled ? 1.0 : 0.6)
  }

  // MARK: - Helper Properties

  private var statusColor: Color {
    switch syncService.syncStatus {
    case .idle:
      return .green
    case .syncing:
      return .blue
    case .error:
      return .red
    case .noAccount, .restricted, .temporarilyUnavailable:
      return .orange
    case .unknown:
      return .gray
    }
  }

  private var unavailabilityReason: String {
    switch syncService.syncStatus {
    case .noAccount:
      return L10n.tr("cloudSync.unavailable.noAccount")
    case .restricted:
      return L10n.tr("cloudSync.unavailable.restricted")
    case .temporarilyUnavailable:
      return L10n.tr("cloudSync.unavailable.temporarilyUnavailable")
    default:
      return L10n.tr("cloudSync.unavailable.default")
    }
  }

  // MARK: - Actions

  private func performManualSync() {
    isSyncing = true

    Task {
      do {
        try await syncService.syncAll()
      } catch {
        errorMessage = error.localizedDescription
        showingError = true
      }
      isSyncing = false
    }
  }
}

// MARK: - Preview

#if DEBUG
  struct CloudSyncSettingsView_Previews: PreviewProvider {
    static var previews: some View {
      CloudSyncSettingsView()
        .environmentObject(UserDefaultsManager.shared)
    }
  }
#endif
