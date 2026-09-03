//
//  SecurityTriggerPipeline.swift
//  MagSafe Guard
//

import Foundation
import MagSafeGuardCore

/// Orchestrates trigger response: hygiene → scripts → hard stop (lock/logout/shutdown).
public final class SecurityTriggerPipeline {

  public static let shared = SecurityTriggerPipeline()

  private let networkActions: NetworkActionsService
  private let securityActions: SecurityActionsService
  private let settingsManager: UserDefaultsManager

  public init(
    networkActions: NetworkActionsService = .shared,
    securityActions: SecurityActionsService = .shared,
    settingsManager: UserDefaultsManager = .shared
  ) {
    self.networkActions = networkActions
    self.securityActions = securityActions
    self.settingsManager = settingsManager
  }

  /// Runs phase A (network hygiene), phase B (scripts), then phase C (security hard stop).
  public func execute(
    context: SecurityActionExecutionContext,
    event: String,
    completion: @escaping (
      NetworkActionResult,
      SecurityActionsService.ScriptPhaseResult,
      SecurityActionsService.ExecutionResult
    ) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }

      let settings = self.settingsManager.settings
      let networkResult = self.networkActions.executeHygienePhase(event: event)

      let scriptResult: SecurityActionsService.ScriptPhaseResult
      if context.runsTriggerScripts {
        scriptResult = self.securityActions.executeScriptsPhase(
          timeBudget: settings.scriptTimeBudgetSeconds
        )
      } else {
        scriptResult = .empty
      }

      self.securityActions.executeActions(context: context) { securityResult in
        completion(networkResult, scriptResult, securityResult)
      }
    }
  }
}
