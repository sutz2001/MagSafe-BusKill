//
//  PanicModeExecutor.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

/// Executes panic-mode response: hygiene, scripts, protection-first security actions, immediate shutdown.
public final class PanicModeExecutor {

  private let pipeline: SecurityTriggerPipeline

  public init(pipeline: SecurityTriggerPipeline = .shared) {
    self.pipeline = pipeline
  }

  /// Run panic pipeline on a background queue.
  public func execute(
    completion: @escaping (
      NetworkActionResult,
      SecurityActionsService.ScriptPhaseResult,
      SecurityActionsService.ExecutionResult
    ) -> Void
  ) {
    pipeline.execute(context: .panic, event: "panic") { network, scripts, security in
      DispatchQueue.main.async {
        completion(network, scripts, security)
      }
    }
  }
}
