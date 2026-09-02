//
//  CLICommandService.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

/// Handles `magsafeguard-cli` commands via distributed notifications and writes status snapshots.
@MainActor
final class CLICommandService {
  static let shared = CLICommandService()

  private weak var appController: AppController?
  private var observer: NSObjectProtocol?

  private init() {}

  func start(appController: AppController) {
    self.appController = appController
    stop()

    observer = DistributedNotificationCenter.default().addObserver(
      forName: CLIIPC.commandNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let self else { return }
      Task { @MainActor in
        self.handleCommand(notification: notification)
      }
    }
  }

  func stop() {
    if let observer {
      DistributedNotificationCenter.default().removeObserver(observer)
      self.observer = nil
    }
  }

  func publishStatus(
    appController: AppController,
    marketingVersion: String
  ) {
    let settings = UserDefaultsManager.shared.settings
    let snapshot = CLIStatusSnapshot(
      appState: appController.currentState.rawValue,
      protectionMode: appController.protectionMode.rawValue,
      operationProfile: settings.operationProfile.selectable.rawValue,
      maxConfiguredRisk: riskToken(TriggerRiskAssessor.maxConfiguredRisk(in: settings)),
      marketingVersion: marketingVersion
    )

    do {
      let directory = CLIIPC.applicationSupportDirectory()
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let data = try JSONEncoder().encode(snapshot)
      try data.write(to: CLIIPC.statusFileURL(), options: .atomic)
    } catch {
      Log.warning("Failed to write CLI status file: \(error.localizedDescription)", category: .general)
    }
  }

  private func handleCommand(notification: Notification) {
    guard let userInfo = notification.userInfo,
      let command = userInfo["command"] as? String
    else {
      postResponse(ok: false, message: "missing command")
      return
    }

    switch command {
    case "status":
      if let controller = appController {
        publishStatus(
          appController: controller,
          marketingVersion: AppVersion.marketing
        )
      }
      postResponse(ok: true, message: "status updated")

    case "arm":
      guard let controller = appController else {
        postResponse(ok: false, message: "app not ready")
        return
      }
      controller.arm { [weak self] result in
        Task { @MainActor in
          switch result {
          case .success:
            self?.postResponse(ok: true, message: "armed")
          case .failure(let error):
            self?.postResponse(ok: false, message: error.localizedDescription)
          }
        }
      }

    case "disarm":
      guard let controller = appController else {
        postResponse(ok: false, message: "app not ready")
        return
      }
      controller.disarm { [weak self] result in
        Task { @MainActor in
          switch result {
          case .success:
            self?.postResponse(ok: true, message: "disarmed")
          case .failure(let error):
            self?.postResponse(ok: false, message: error.localizedDescription)
          }
        }
      }

    case "apply-profile":
      guard let profileRaw = userInfo["profile"] as? String,
        let profile = OperationProfile(rawValue: profileRaw)
      else {
        postResponse(ok: false, message: "unknown profile")
        return
      }
      UserDefaultsManager.shared.applyOperationProfile(profile.selectable)
      postResponse(ok: true, message: "profile applied")

    default:
      postResponse(ok: false, message: "unknown command")
    }
  }

  private func postResponse(ok: Bool, message: String) {
    DistributedNotificationCenter.default().post(
      name: CLIIPC.responseNotification,
      object: nil,
      userInfo: ["ok": ok, "message": message]
    )
  }

  private func riskToken(_ level: TriggerRiskLevel) -> String {
    switch level {
    case .low: return "low"
    case .moderate: return "moderate"
    case .severe: return "severe"
    }
  }
}
