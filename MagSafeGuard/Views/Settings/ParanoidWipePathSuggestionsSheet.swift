//
//  ParanoidWipePathSuggestionsSheet.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import SwiftUI

/// Explicit opt-in sheet: check existing vault-style folders, then add to wipe paths.
struct ParanoidWipePathSuggestionsSheet: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @Binding var isPresented: Bool
  @State private var selectedIDs: Set<String> = []
  @State private var items: [ParanoidWipePathSuggestions.Item] = []

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(l10n: "settings.paranoid.suggest.title")
        .font(.title3.weight(.semibold))

      Text(l10n: "settings.paranoid.suggest.caption")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      if items.isEmpty {
        Text(l10n: "settings.paranoid.suggest.empty")
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        List {
          ForEach(items) { item in
            Toggle(isOn: binding(for: item.id)) {
              VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr(item.titleKey))
                Text(item.absolutePath)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .textSelection(.enabled)
              }
            }
          }
        }
        .listStyle(.bordered(alternatesRowBackgrounds: true))
      }

      HStack {
        Button(L10n.tr("common.cancel")) {
          isPresented = false
        }
        Spacer()
        Button(L10n.tr("settings.paranoid.suggest.add")) {
          addSelected()
        }
        .keyboardShortcut(.defaultAction)
        .disabled(selectedIDs.isEmpty)
      }
    }
    .padding(20)
    .frame(width: 460, height: 360)
    .onAppear {
      items = ParanoidWipePathSuggestions.available()
      let already = Set(settingsManager.settings.paranoid.wipePaths)
      selectedIDs = Set(items.filter { already.contains($0.absolutePath) }.map(\.id))
    }
  }

  private func binding(for id: String) -> Binding<Bool> {
    Binding(
      get: { selectedIDs.contains(id) },
      set: { on in
        if on {
          selectedIDs.insert(id)
        } else {
          selectedIDs.remove(id)
        }
      }
    )
  }

  private func addSelected() {
    let paths = items.filter { selectedIDs.contains($0.id) }.map(\.absolutePath)
    settingsManager.updateSettings { settings in
      settings.paranoid.wipePaths = ParanoidWipePathSuggestions.merge(
        selectedPaths: paths,
        into: settings.paranoid.wipePaths
      )
    }
    isPresented = false
  }
}
