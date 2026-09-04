//
//  ParanoidSettingsSection.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import SwiftUI

/// Settings → Security: wipe targets, legal notice, codeword (arm from menu when ready).
struct ParanoidSettingsSection: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @State private var showingSetupWizard = false
  @State private var showingLegal = false
  @State private var showingCodeword = false

  var body: some View {
    Section(header: Text(l10n: "settings.paranoid.title")) {
      Text(l10n: "settings.paranoid.caption")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Text(readinessText)
        .font(.caption)
        .foregroundColor(settingsManager.settings.paranoid.isReadyToArm ? .secondary : .orange)
        .fixedSize(horizontal: false, vertical: true)

      readinessChecklist

      Text(l10n: "settings.paranoid.limits")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Button(L10n.tr("settings.paranoid.openSetup")) {
        showingSetupWizard = true
      }

      Button(L10n.tr("settings.paranoid.openLegal")) {
        showingLegal = true
      }

      Button(
        settingsManager.settings.paranoid.hasCodeword
          ? L10n.tr("settings.paranoid.changeCodeword")
          : L10n.tr("settings.paranoid.setCodeword")
      ) {
        showingCodeword = true
      }

      ParanoidWipeTargetsEditor()
    }
    .sheet(isPresented: $showingSetupWizard) {
      ParanoidSetupWizardView(isPresented: $showingSetupWizard)
        .environmentObject(settingsManager)
    }
    .sheet(isPresented: $showingLegal) {
      ParanoidLegalNoticeView(isPresented: $showingLegal)
        .environmentObject(settingsManager)
    }
    .sheet(isPresented: $showingCodeword) {
      ParanoidCodewordSetupView(isPresented: $showingCodeword)
        .environmentObject(settingsManager)
    }
  }

  private var readinessText: String {
    if settingsManager.settings.paranoid.isReadyToArm {
      return L10n.tr("settings.paranoid.readyToArm")
    }
    return L10n.tr("settings.paranoid.notReady")
  }

  @ViewBuilder
  private var readinessChecklist: some View {
    VStack(alignment: .leading, spacing: 4) {
      checklistRow(
        done: settingsManager.settings.paranoid.setupCompleted,
        text: L10n.tr("settings.paranoid.check.setup")
      )
      checklistRow(
        done: settingsManager.settings.paranoid.hasWipeTarget,
        text: L10n.tr("settings.paranoid.check.targets")
      )
      checklistRow(
        done: settingsManager.settings.paranoid.legalNoticeAccepted,
        text: L10n.tr("settings.paranoid.check.legal")
      )
      checklistRow(
        done: settingsManager.settings.paranoid.hasCodeword,
        text: L10n.tr("settings.paranoid.check.codeword")
      )
    }
  }

  private func checklistRow(done: Bool, text: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: done ? "checkmark.circle.fill" : "circle")
        .foregroundColor(done ? .green : .secondary)
        .font(.caption)
      Text(text)
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
}
