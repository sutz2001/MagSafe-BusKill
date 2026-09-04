//
//  ParanoidSettingsSection.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import SwiftUI

/// Settings → Security: configure paranoid wipe targets (arming ships later in v0.6).
struct ParanoidSettingsSection: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @State private var showingSetupWizard = false

  var body: some View {
    Section(header: Text(l10n: "settings.paranoid.title")) {
      Text(l10n: "settings.paranoid.caption")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Text(l10n: "settings.paranoid.notArmedYet")
        .font(.caption)
        .foregroundColor(.orange)
        .fixedSize(horizontal: false, vertical: true)

      Text(setupStatusText)
        .font(.caption)
        .foregroundColor(settingsManager.settings.paranoid.setupCompleted ? .secondary : .orange)
        .fixedSize(horizontal: false, vertical: true)

      Text(l10n: "settings.paranoid.limits")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Button(L10n.tr("settings.paranoid.openSetup")) {
        showingSetupWizard = true
      }

      ParanoidWipeTargetsEditor()
    }
    .sheet(isPresented: $showingSetupWizard) {
      ParanoidSetupWizardView(isPresented: $showingSetupWizard)
        .environmentObject(settingsManager)
    }
  }

  private var setupStatusText: String {
    if settingsManager.settings.paranoid.setupCompleted {
      return L10n.tr("settings.paranoid.setup.done")
    }
    return L10n.tr("settings.paranoid.setup.needed")
  }
}
