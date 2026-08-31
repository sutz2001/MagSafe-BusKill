//
//  RemoteTriggerService.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

/// Handles inbound `magsafeguard://` URLs for remote trigger.
public final class RemoteTriggerService {

  public static let scheme = "magsafeguard"

  private let appController: AppController
  private let settingsManager: UserDefaultsManager

  public init(
    appController: AppController,
    settingsManager: UserDefaultsManager = .shared
  ) {
    self.appController = appController
    self.settingsManager = settingsManager
  }

  @discardableResult
  public func handle(url: URL) -> Bool {
    guard url.scheme?.lowercased() == Self.scheme else { return false }

    let settings = settingsManager.settings.remoteTrigger
    guard settings.isEnabled else {
      Log.warning("Remote trigger URL ignored — feature disabled", category: .security)
      return true
    }

    guard validateToken(in: url, expected: settings.token) else {
      Log.warning("Remote trigger rejected — invalid token", category: .security)
      return true
    }

    let host = (url.host ?? "").lowercased()
    switch host {
    case "trigger":
      appController.triggerRemoteSecurityResponse()
      return true
    case "arm":
      armIfDisarmed()
      return true
    case "panic":
      appController.triggerRemotePanicResponse()
      return true
    default:
      Log.warning("Unknown remote trigger host: \(host)", category: .security)
      return true
    }
  }

  private func validateToken(in url: URL, expected: String) -> Bool {
    guard !expected.isEmpty else { return false }
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let token = components.queryItems?.first(where: { $0.name == "token" })?.value
    else { return false }
    return token == expected
  }

  private func armIfDisarmed() {
    guard appController.currentState == .disarmed else { return }
    appController.armAutomatically(details: L10n.tr("logDetail.remoteArm")) { result in
      if case .failure(let error) = result {
        Log.error("Remote arm failed", error: error, category: .security)
      }
    }
  }
}
