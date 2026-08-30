//
//  AppEvent+Localized.swift
//  MagSafe Guard
//

import Foundation

extension AppEvent {
  var localizedName: String {
    L10n.tr("event.\(rawValue)")
  }
}

extension AppState {
  var localizedName: String {
    L10n.tr("appState.\(rawValue)")
  }
}
