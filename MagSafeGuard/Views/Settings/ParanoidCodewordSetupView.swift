//
//  ParanoidCodewordSetupView.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import SwiftUI

/// Set or replace the mandatory paranoid arming codeword (stored as hash only).
struct ParanoidCodewordSetupView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @Binding var isPresented: Bool
  @State private var codeword = ""
  @State private var confirm = ""
  @State private var errorText: String?

  private let minimumLength = 4

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(l10n: "paranoid.codeword.title")
        .font(.title2.weight(.semibold))

      Text(l10n: "paranoid.codeword.caption")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      if settingsManager.settings.paranoid.hasCodeword {
        Text(l10n: "paranoid.codeword.alreadySet")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      SecureField(L10n.tr("paranoid.codeword.placeholder"), text: $codeword)
      SecureField(L10n.tr("paranoid.codeword.confirmPlaceholder"), text: $confirm)

      if let errorText {
        Text(errorText)
          .font(.caption)
          .foregroundColor(.red)
          .fixedSize(horizontal: false, vertical: true)
      }

      HStack {
        Button(L10n.tr("common.cancel")) {
          isPresented = false
        }
        Spacer()
        if settingsManager.settings.paranoid.hasCodeword {
          Button(L10n.tr("paranoid.codeword.clear")) {
            settingsManager.updateSettings { settings in
              settings.paranoid.setCodeword("")
            }
            codeword = ""
            confirm = ""
            errorText = nil
          }
        }
        Button(L10n.tr("paranoid.codeword.save")) {
          save()
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(22)
    .frame(width: 440, height: 300)
  }

  private func save() {
    let trimmed = codeword.trimmingCharacters(in: .whitespacesAndNewlines)
    let confirmTrimmed = confirm.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= minimumLength else {
      errorText = L10n.tr("paranoid.codeword.tooShort", minimumLength)
      return
    }
    guard trimmed == confirmTrimmed else {
      errorText = L10n.tr("paranoid.codeword.mismatch")
      return
    }
    settingsManager.updateSettings { settings in
      settings.paranoid.setCodeword(trimmed)
    }
    isPresented = false
  }
}
