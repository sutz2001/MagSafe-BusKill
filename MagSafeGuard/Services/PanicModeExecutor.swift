//
//  PanicModeExecutor.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

/// Executes panic-mode response: network actions, protection-first security actions, immediate shutdown.
public final class PanicModeExecutor {

  private let networkActions: NetworkActionsService
  private let securityActions: SecurityActionsService
  private let systemActions: SystemActionsProtocol

  public init(
    networkActions: NetworkActionsService = .shared,
    securityActions: SecurityActionsService = .shared,
    systemActions: SystemActionsProtocol = MacSystemActions()
  ) {
    self.networkActions = networkActions
    self.securityActions = securityActions
    self.systemActions = systemActions
  }

  /// Run panic pipeline on a background queue. Always attempts immediate shutdown after security actions start.
  public func execute(completion: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else {
        DispatchQueue.main.async { completion() }
        return
      }

      _ = self.networkActions.executeActions(event: "panic")

      self.securityActions.executeActions(context: .panic) { _ in
        do {
          try self.systemActions.executeImmediateShutdown()
        } catch {
          Log.error("Immediate shutdown failed during panic", error: error, category: .security)
        }
        DispatchQueue.main.async { completion() }
      }
    }
  }
}
