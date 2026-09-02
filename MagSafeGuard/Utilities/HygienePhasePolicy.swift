//
//  HygienePhasePolicy.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

/// Fixed network-hygiene phase before logout/shutdown on cable or panic triggers.
enum HygienePhasePolicy {
  static let maxDuration: TimeInterval = 2.0
  static let webhookTimeout: TimeInterval = 1.5

  /// Execution order for phase A (only actions enabled in settings run).
  static let orderedActions: [NetworkActionType] = [
    .clearClipboard,
    .ejectRemovableVolumes,
    .unmountCryptomatorVolumes,
    .clearSSHAgent,
    .webhook,
    .disconnectVPN,
    .disableBluetooth,
    .disableWiFi
  ]
}
