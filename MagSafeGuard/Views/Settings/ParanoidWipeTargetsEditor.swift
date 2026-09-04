//
//  ParanoidWipeTargetsEditor.swift
//  MagSafe Guard
//

import AppKit
import MagSafeGuardCore
import SwiftUI

/// Shared path / volume / recovery-key editors for Settings and the setup wizard.
struct ParanoidWipeTargetsEditor: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @State private var volumeIDDraft = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      wipePathsBlock
      volumeIDsBlock
      recoveryKeyBlock
    }
  }

  private var wipePathsBlock: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(l10n: "settings.paranoid.wipePaths")
        .font(.headline)

      if settingsManager.settings.paranoid.wipePaths.isEmpty {
        Text(l10n: "settings.paranoid.wipePaths.empty")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
        ForEach(settingsManager.settings.paranoid.wipePaths, id: \.self) { path in
          HStack {
            Text(path)
              .font(.caption)
              .lineLimit(2)
              .textSelection(.enabled)
            Spacer()
            Button(role: .destructive) {
              removeWipePath(path)
            } label: {
              Image(systemName: "minus.circle.fill")
            }
            .buttonStyle(.borderless)
            .help(L10n.tr("settings.paranoid.removePath"))
          }
        }
      }

      Button(L10n.tr("settings.paranoid.addPath")) {
        addWipePath()
      }
    }
  }

  private var volumeIDsBlock: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(l10n: "settings.paranoid.volumes")
        .font(.headline)
      Text(l10n: "settings.paranoid.volumes.caption")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      ForEach(settingsManager.settings.paranoid.apfsVolumeIdentifiers, id: \.self) { id in
        HStack {
          Text(id)
            .font(.caption)
            .textSelection(.enabled)
          Spacer()
          Button(role: .destructive) {
            removeVolumeID(id)
          } label: {
            Image(systemName: "minus.circle.fill")
          }
          .buttonStyle(.borderless)
        }
      }

      HStack {
        TextField(L10n.tr("settings.paranoid.volumes.placeholder"), text: $volumeIDDraft)
        Button(L10n.tr("settings.paranoid.addVolume")) {
          addVolumeID()
        }
        .disabled(volumeIDDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
  }

  private var recoveryKeyBlock: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(l10n: "settings.paranoid.recoveryKey")
        .font(.headline)
      Text(l10n: "settings.paranoid.recoveryKey.caption")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      if let path = settingsManager.settings.paranoid.recoveryKeyBackupPath {
        HStack {
          Text(path)
            .font(.caption)
            .lineLimit(2)
            .textSelection(.enabled)
          Spacer()
          Button(L10n.tr("settings.paranoid.clearRecoveryKey")) {
            updateParanoid { $0.recoveryKeyBackupPath = nil }
          }
        }
      }

      Button(L10n.tr("settings.paranoid.chooseRecoveryKey")) {
        chooseRecoveryKey()
      }
    }
  }

  private func updateParanoid(_ mutate: (inout ParanoidConfiguration) -> Void) {
    settingsManager.updateSettings { settings in
      mutate(&settings.paranoid)
    }
  }

  private func addWipePath() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = true
    panel.canCreateDirectories = false
    panel.message = L10n.tr("settings.paranoid.pathPicker.message")
    guard panel.runModal() == .OK else { return }
    let paths = panel.urls.map(\.path)
    updateParanoid { config in
      for path in paths where !config.wipePaths.contains(path) {
        config.wipePaths.append(path)
      }
    }
  }

  private func removeWipePath(_ path: String) {
    updateParanoid { $0.wipePaths.removeAll { $0 == path } }
  }

  private func addVolumeID() {
    let id = volumeIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !id.isEmpty else { return }
    updateParanoid { config in
      if !config.apfsVolumeIdentifiers.contains(id) {
        config.apfsVolumeIdentifiers.append(id)
      }
    }
    volumeIDDraft = ""
  }

  private func removeVolumeID(_ id: String) {
    updateParanoid { $0.apfsVolumeIdentifiers.removeAll { $0 == id } }
  }

  private func chooseRecoveryKey() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.message = L10n.tr("settings.paranoid.recoveryKeyPicker.message")
    guard panel.runModal() == .OK, let path = panel.url?.path else { return }
    updateParanoid { $0.recoveryKeyBackupPath = path }
  }
}
