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
  @State private var customPathDraft = ""
  @State private var customPathError: String?
  @State private var showingSuggestions = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      wipePathsBlock
      volumeIDsBlock
      recoveryKeyBlock
    }
    .sheet(isPresented: $showingSuggestions) {
      ParanoidWipePathSuggestionsSheet(isPresented: $showingSuggestions)
        .environmentObject(settingsManager)
    }
  }

  private var wipePathsBlock: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(l10n: "settings.paranoid.wipePaths")
        .font(.headline)
      Text(l10n: "settings.paranoid.wipePaths.caption")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      if settingsManager.settings.paranoid.wipePaths.isEmpty {
        Text(l10n: "settings.paranoid.wipePaths.empty")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
        Text(l10n: "settings.paranoid.wipePaths.orderHint")
          .font(.caption)
          .foregroundColor(.secondary)

        ForEach(Array(settingsManager.settings.paranoid.wipePaths.enumerated()), id: \.element) {
          index,
          path in
          HStack(spacing: 8) {
            Text("\(index + 1).")
              .font(.caption.monospacedDigit())
              .foregroundColor(.secondary)
              .frame(width: 22, alignment: .trailing)
            Text(path)
              .font(.caption)
              .lineLimit(2)
              .textSelection(.enabled)
            Spacer()
            Button {
              moveWipePath(from: index, direction: -1)
            } label: {
              Image(systemName: "arrow.up")
            }
            .buttonStyle(.borderless)
            .disabled(index == 0)
            .help(L10n.tr("settings.paranoid.wipePaths.moveUp"))
            Button {
              moveWipePath(from: index, direction: 1)
            } label: {
              Image(systemName: "arrow.down")
            }
            .buttonStyle(.borderless)
            .disabled(index >= settingsManager.settings.paranoid.wipePaths.count - 1)
            .help(L10n.tr("settings.paranoid.wipePaths.moveDown"))
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

      wipeBudgetBlock

      HStack {
        TextField(L10n.tr("settings.paranoid.customPath.placeholder"), text: $customPathDraft)
          .onSubmit { addCustomPathFromDraft() }
        Button(L10n.tr("settings.paranoid.customPath.add")) {
          addCustomPathFromDraft()
        }
        .disabled(customPathDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }

      if let customPathError {
        Text(customPathError)
          .font(.caption)
          .foregroundColor(.orange)
          .fixedSize(horizontal: false, vertical: true)
      }

      HStack {
        Button(L10n.tr("settings.paranoid.addPath")) {
          addWipePath()
        }
        Button(L10n.tr("settings.paranoid.suggest.open")) {
          showingSuggestions = true
        }
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

  private var wipeBudgetBlock: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(l10n: "settings.paranoid.wipeBudget.title")
        .font(.headline)
      Text(wipeBudgetCaption)
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      HStack {
        Text(l10n: "settings.paranoid.wipeBudget.min")
          .font(.caption)
        Slider(value: wipeBudgetBinding, in: 0...60, step: 1)
        Text(l10n: "settings.paranoid.wipeBudget.max")
          .font(.caption)
      }
    }
  }

  private var wipeBudgetCaption: String {
    let seconds = Int(settingsManager.settings.paranoid.pathWipeTimeBudgetSeconds.rounded())
    if seconds == 0 {
      return L10n.tr("settings.paranoid.wipeBudget.unlimited")
    }
    return L10n.tr("settings.paranoid.wipeBudget.value", seconds)
  }

  private var wipeBudgetBinding: Binding<Double> {
    Binding(
      get: { settingsManager.settings.paranoid.pathWipeTimeBudgetSeconds },
      set: { value in
        updateParanoid { $0.pathWipeTimeBudgetSeconds = value }
      }
    )
  }

  private func updateParanoid(_ mutate: (inout ParanoidConfiguration) -> Void) {
    settingsManager.updateSettings { settings in
      mutate(&settings.paranoid)
    }
  }

  private func moveWipePath(from index: Int, direction: Int) {
    updateParanoid { config in
      let destination = index + direction
      guard config.wipePaths.indices.contains(index),
        config.wipePaths.indices.contains(destination)
      else { return }
      config.wipePaths.swapAt(index, destination)
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
    customPathError = nil
  }

  private func addCustomPathFromDraft() {
    let raw = customPathDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !raw.isEmpty else { return }

    let expanded: String
    if raw == "~" || raw.hasPrefix("~/") {
      expanded = (raw as NSString).expandingTildeInPath
    } else {
      expanded = raw
    }
    let standardized = (expanded as NSString).standardizingPath

    guard standardized.hasPrefix("/") else {
      customPathError = L10n.tr("settings.paranoid.customPath.absoluteRequired")
      return
    }
    guard !ParanoidConfiguration.isForbiddenWipePath(standardized) else {
      customPathError = L10n.tr("settings.paranoid.customPath.forbidden")
      return
    }

    let alreadyListed = settingsManager.settings.paranoid.wipePaths.contains(standardized)
    if alreadyListed {
      customPathError = L10n.tr("settings.paranoid.customPath.duplicate")
      return
    }

    updateParanoid { config in
      config.wipePaths.append(standardized)
    }
    customPathDraft = ""
    customPathError = nil
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
