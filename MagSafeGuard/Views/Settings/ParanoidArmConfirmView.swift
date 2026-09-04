//
//  ParanoidArmConfirmView.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import SwiftUI

/// Second confirmation step: re-enter codeword before Touch ID / password arming.
struct ParanoidArmConfirmView: View {
  var onCancel: () -> Void
  var onConfirm: (String) -> Void

  @State private var codeword = ""
  @State private var confirmedIntent = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(l10n: "paranoid.arm.title")
        .font(.title2.weight(.semibold))

      Text(l10n: "paranoid.arm.caption")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      SecureField(L10n.tr("paranoid.arm.codewordPlaceholder"), text: $codeword)

      Toggle(isOn: $confirmedIntent) {
        Text(l10n: "paranoid.arm.confirmCheckbox")
          .fixedSize(horizontal: false, vertical: true)
      }
      .toggleStyle(.checkbox)

      HStack {
        Button(L10n.tr("common.cancel")) {
          onCancel()
        }
        Spacer()
        Button(L10n.tr("paranoid.arm.continue")) {
          let trimmed = codeword.trimmingCharacters(in: .whitespacesAndNewlines)
          onConfirm(trimmed)
        }
        .keyboardShortcut(.defaultAction)
        .disabled(!confirmedIntent || codeword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .padding(22)
    .frame(width: 460, height: 280)
  }
}
