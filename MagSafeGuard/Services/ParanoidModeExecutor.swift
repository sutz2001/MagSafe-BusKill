//
//  ParanoidModeExecutor.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

/// Panic-equivalent protection path plus parallel destruction. Shutdown does not wait for wipe.
public final class ParanoidModeExecutor {

  private let pipeline: SecurityTriggerPipeline
  private let destruction: DestructionPipeline
  private let settingsManager: UserDefaultsManager
  private let destructionQueue: DispatchQueue

  /// Called on the main queue when the destruction pass finishes (may be after shutdown started).
  public var onDestructionComplete: ((DestructionResult) -> Void)?

  public init(
    pipeline: SecurityTriggerPipeline = .shared,
    destruction: DestructionPipeline = MacDestructionPipeline(),
    settingsManager: UserDefaultsManager = .shared,
    destructionQueue: DispatchQueue = DispatchQueue(
      label: "com.sutz2001.MagSafeGuard.paranoid.destruction",
      qos: .userInitiated
    )
  ) {
    self.pipeline = pipeline
    self.destruction = destruction
    self.settingsManager = settingsManager
    self.destructionQueue = destructionQueue
  }

  /// Start destruction in parallel, then run hygiene / scripts / lock / logout / immediate shutdown.
  public func execute(
    completion: @escaping (
      NetworkActionResult,
      SecurityActionsService.ScriptPhaseResult,
      SecurityActionsService.ExecutionResult
    ) -> Void
  ) {
    let config = settingsManager.settings.paranoid
    destructionQueue.async { [weak self] in
      guard let self else { return }
      let result = self.destruction.execute(config)
      DispatchQueue.main.async {
        self.onDestructionComplete?(result)
      }
    }

    pipeline.execute(context: .paranoid, event: "paranoid") { network, scripts, security in
      DispatchQueue.main.async {
        completion(network, scripts, security)
      }
    }
  }
}
