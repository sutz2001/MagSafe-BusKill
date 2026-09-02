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
  public func execute(completion: @escaping () -> Void) {
    pipeline.execute(context: .panic, event: "panic") { _, _ in
      DispatchQueue.main.async { completion() }
    }
  }
}
