//
//  ParanoidSetupWizardView.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import SwiftUI

/// Guided setup: FileVault check + wipe targets. Does not arm Paranoid or accept the full legal notice.
struct ParanoidSetupWizardView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @Binding var isPresented: Bool
  @State private var page = 0
  @State private var acknowledgedLimits = false
  @State private var fileVaultStatus: FileVaultStatus = .unknown("")
  @State private var completionError: String?

  private let checker: FileVaultStatusChecker
  private let pageCount = 4

  init(
    isPresented: Binding<Bool>,
    checker: FileVaultStatusChecker = FileVaultStatusChecker()
  ) {
    self._isPresented = isPresented
    self.checker = checker
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(l10n: "paranoid.setup.title")
        .font(.title2.weight(.semibold))

      Group {
        switch page {
        case 0: warningsPage
        case 1: fileVaultPage
        case 2: targetsPage
        default: finishPage
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

      HStack {
        Button(L10n.tr("common.cancel")) {
          isPresented = false
        }
        Spacer()
        if page > 0 {
          Button(L10n.tr("onboarding.back")) {
            completionError = nil
            page -= 1
          }
        }
        if page < pageCount - 1 {
          Button(L10n.tr("onboarding.next")) {
            goNext()
          }
          .keyboardShortcut(.defaultAction)
          .disabled(!canAdvance)
        } else {
          Button(L10n.tr("paranoid.setup.complete")) {
            finishSetup()
          }
          .keyboardShortcut(.defaultAction)
          .disabled(!canComplete)
        }
      }
    }
    .padding(22)
    .frame(width: 520, height: 480)
    .onAppear { refreshFileVault() }
  }

  private var canAdvance: Bool {
    switch page {
    case 0: return acknowledgedLimits
    case 1: return fileVaultStatus.isEnabled
    case 2: return settingsManager.settings.paranoid.hasWipeTarget
    default: return true
    }
  }

  private var canComplete: Bool {
    settingsManager.settings.paranoid.canCompleteSetup(fileVaultEnabled: fileVaultStatus.isEnabled)
  }

  private var warningsPage: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(l10n: "paranoid.setup.warnings.body")
        .fixedSize(horizontal: false, vertical: true)
      Text(l10n: "paranoid.setup.warnings.work")
        .foregroundColor(.orange)
        .fixedSize(horizontal: false, vertical: true)
      Text(l10n: "settings.paranoid.limits")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      Toggle(isOn: $acknowledgedLimits) {
        Text(l10n: "paranoid.setup.warnings.ack")
          .fixedSize(horizontal: false, vertical: true)
      }
      Text(l10n: "paranoid.setup.warnings.noArm")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var fileVaultPage: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(l10n: "paranoid.setup.fileVault.body")
        .fixedSize(horizontal: false, vertical: true)
      HStack {
        Image(systemName: fileVaultStatus.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
          .foregroundColor(fileVaultStatus.isEnabled ? .green : .red)
        Text(fileVaultStatusLabel)
      }
      Button(L10n.tr("paranoid.setup.fileVault.refresh")) {
        refreshFileVault()
      }
      if !fileVaultStatus.isEnabled {
        Text(l10n: "paranoid.setup.fileVault.required")
          .font(.caption)
          .foregroundColor(.orange)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var targetsPage: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        Text(l10n: "paranoid.setup.targets.body")
          .fixedSize(horizontal: false, vertical: true)
        ParanoidWipeTargetsEditor()
        if !settingsManager.settings.paranoid.hasWipeTarget {
          Text(l10n: "paranoid.setup.targets.required")
            .font(.caption)
            .foregroundColor(.orange)
        }
      }
    }
  }

  private var finishPage: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(l10n: "paranoid.setup.finish.body")
        .fixedSize(horizontal: false, vertical: true)
      if let completionError {
        Text(completionError)
          .foregroundColor(.red)
          .font(.caption)
      }
    }
  }

  private var fileVaultStatusLabel: String {
    switch fileVaultStatus {
    case .enabled:
      return L10n.tr("paranoid.setup.fileVault.on")
    case .disabled:
      return L10n.tr("paranoid.setup.fileVault.off")
    case .unknown(let detail):
      return L10n.tr("paranoid.setup.fileVault.unknown", detail)
    }
  }

  private func goNext() {
    if page == 0 {
      refreshFileVault()
    }
    page += 1
  }

  private func refreshFileVault() {
    fileVaultStatus = checker.check()
  }

  private func finishSetup() {
    refreshFileVault()
    var succeeded = false
    settingsManager.updateSettings { settings in
      succeeded = settings.paranoid.completeSetup(fileVaultEnabled: fileVaultStatus.isEnabled)
    }
    if succeeded {
      isPresented = false
    } else {
      completionError = L10n.tr("paranoid.setup.finish.blocked")
    }
  }
}
