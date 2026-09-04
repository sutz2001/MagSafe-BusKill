//
//  ParanoidModeExecutor.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

/// Lock/logout/hygiene in parallel with sequential path wipe; hard shutdown after wipe budget
/// (or when wipe finishes earlier). Path order in settings is wipe priority.
public final class ParanoidModeExecutor {

  private let pipeline: SecurityTriggerPipeline
  private let destruction: DestructionPipeline
  private let settingsManager: UserDefaultsManager
  private let systemActions: SystemActionsProtocol
  private let workQueue: DispatchQueue

  /// Called on the main queue when the destruction pass finishes.
  public var onDestructionComplete: ((DestructionResult) -> Void)?

  public init(
    pipeline: SecurityTriggerPipeline = .shared,
    destruction: DestructionPipeline = MacDestructionPipeline(),
    settingsManager: UserDefaultsManager = .shared,
    systemActions: SystemActionsProtocol = MacSystemActions(),
    workQueue: DispatchQueue = DispatchQueue(
      label: "com.sutz2001.MagSafeGuard.paranoid",
      qos: .userInitiated,
      attributes: .concurrent
    )
  ) {
    self.pipeline = pipeline
    self.destruction = destruction
    self.settingsManager = settingsManager
    self.systemActions = systemActions
    self.workQueue = workQueue
  }

  /// Wipe paths in priority order (budgeted) while running panic-style protection without
  /// shutdown; then hard-shutdown so higher-priority deletes get the time window.
  public func execute(
    completion: @escaping (
      NetworkActionResult,
      SecurityActionsService.ScriptPhaseResult,
      SecurityActionsService.ExecutionResult
    ) -> Void
  ) {
    let config = settingsManager.settings.paranoid
    // Concurrent queue: wipe + protection run in parallel; coordinator must not nest
    // blocking `wait` on a serial queue that also runs the wipe (deadlock).
    workQueue.async { [weak self] in
      guard let self else { return }

      let group = DispatchGroup()
      let resultLock = NSLock()
      var networkResult = NetworkActionResult(executed: [], failed: [])
      var scriptResult = SecurityActionsService.ScriptPhaseResult.empty
      var securityResult = SecurityActionsService.ExecutionResult(
        executedActions: [],
        failedActions: [],
        timestamp: Date()
      )

      group.enter()
      self.workQueue.async {
        let wipe = self.destruction.execute(config)
        DispatchQueue.main.async {
          self.onDestructionComplete?(wipe)
        }
        group.leave()
      }

      group.enter()
      self.pipeline.execute(context: .paranoid, event: "paranoid") { network, scripts, security in
        resultLock.lock()
        networkResult = network
        scriptResult = scripts
        securityResult = security
        resultLock.unlock()
        group.leave()
      }

      group.wait()
      try? self.systemActions.executeImmediateShutdown()

      resultLock.lock()
      let finalNetwork = networkResult
      let finalScripts = scriptResult
      let finalSecurity = securityResult
      resultLock.unlock()

      DispatchQueue.main.async {
        completion(finalNetwork, finalScripts, finalSecurity)
      }
    }
  }
}
