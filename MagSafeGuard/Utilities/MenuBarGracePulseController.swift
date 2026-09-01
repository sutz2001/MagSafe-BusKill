//
//  MenuBarGracePulseController.swift
//  MagSafe Guard
//

import AppKit
import MagSafeGuardCore

/// When grace alerts are off (discreet), pulse the menu bar icon in the final seconds.
enum MenuBarGracePulsePolicy {

  static let normalThresholdSeconds: TimeInterval = 10
  static let panicThresholdSeconds: TimeInterval = 5
  static let pulsePeriodSeconds: TimeInterval = 0.5

  static func shouldPulse(
    isInGracePeriod: Bool,
    showSecurityAlerts: Bool,
    graceRemaining: TimeInterval,
    protectionMode: ProtectionMode
  ) -> Bool {
    guard isInGracePeriod, !showSecurityAlerts, graceRemaining > 0 else { return false }
    return graceRemaining <= threshold(for: protectionMode)
  }

  static func threshold(for protectionMode: ProtectionMode) -> TimeInterval {
    switch protectionMode {
    case .normal:
      return normalThresholdSeconds
    case .panic, .paranoid:
      return panicThresholdSeconds
    }
  }
}

/// Drives subtle opacity pulsing on the status item button.
final class MenuBarGracePulseController {

  private var timer: Timer?
  private weak var button: NSStatusBarButton?
  private var phase: TimeInterval = 0

  func update(button: NSStatusBarButton, shouldPulse: Bool, reducedMotion: Bool) {
    if shouldPulse {
      if reducedMotion {
        stopTimer()
        button.alphaValue = 1.0
        self.button = button
        return
      }

      if self.button !== button {
        stopTimer()
        self.button = button
        phase = 0
      }
      button.alphaValue = 1.0
      startTimerIfNeeded()
      return
    }

    stop(button: button)
  }

  func stop(button: NSStatusBarButton? = nil) {
    stopTimer()
    (button ?? self.button)?.alphaValue = 1.0
    self.button = nil
    phase = 0
  }

  private func startTimerIfNeeded() {
    guard timer == nil else { return }

    let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
      self?.tick()
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  private func tick() {
    guard let button else {
      stop()
      return
    }

    phase += 0.05
    let period = MenuBarGracePulsePolicy.pulsePeriodSeconds
    let cyclePosition = phase.truncatingRemainder(dividingBy: period) / period
    let wave = 0.5 + 0.5 * sin(cyclePosition * 2 * .pi)
    let minAlpha: CGFloat = 0.45
    button.alphaValue = minAlpha + (1.0 - minAlpha) * wave
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }
}
