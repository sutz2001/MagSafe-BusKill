//
//  ParanoidLegalNoticeView.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import SwiftUI

/// Full paranoid disclaimer (EN/DE via L10n). Separate from panic’s short notice.
struct ParanoidLegalNoticeView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @Binding var isPresented: Bool
  @State private var acknowledged = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(l10n: "paranoid.legal.title")
        .font(.title2.weight(.semibold))

      ScrollView {
        Text(l10n: "paranoid.legal.body")
          .font(.body)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxHeight: 280)

      Toggle(isOn: $acknowledged) {
        Text(l10n: "paranoid.legal.checkbox")
          .fixedSize(horizontal: false, vertical: true)
      }
      .toggleStyle(.checkbox)

      HStack {
        Button(L10n.tr("common.cancel")) {
          isPresented = false
        }
        Spacer()
        Button(L10n.tr("paranoid.legal.accept")) {
          settingsManager.updateSettings { settings in
            settings.paranoid.legalNoticeAccepted = true
          }
          isPresented = false
        }
        .keyboardShortcut(.defaultAction)
        .disabled(!acknowledged)
      }
    }
    .padding(22)
    .frame(width: 520, height: 440)
    .onAppear {
      acknowledged = settingsManager.settings.paranoid.legalNoticeAccepted
    }
  }
}
