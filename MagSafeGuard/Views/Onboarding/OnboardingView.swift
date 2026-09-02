//
//  OnboardingView.swift
//  MagSafe Guard
//

import AppKit
import MagSafeGuardCore
import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @Binding var isPresented: Bool
  @State private var page = 0

  private let pageCount = 5
  private let windowSize = CGSize(width: 440, height: 400)
  private let markCompleteOnDismiss: Bool

  init(isPresented: Binding<Bool>, markCompleteOnDismiss: Bool = true) {
    self._isPresented = isPresented
    self.markCompleteOnDismiss = markCompleteOnDismiss
  }

  var body: some View {
    VStack(spacing: 14) {
      pageIndicator

      Group {
        switch page {
        case 0:
          welcomeOnboardingPage
        case 1:
          dailyModesOnboardingPage
        case 2:
          highAssuranceOnboardingPage
        case 3:
          onboardingPage(
            titleKey: "onboarding.grace.title",
            bodyKey: "onboarding.grace.body",
            symbol: "timer"
          )
        case 4:
          onboardingPage(
            titleKey: "onboarding.permissions.title",
            bodyKey: "onboarding.permissions.body",
            symbol: "bell.badge"
          )
        default:
          EmptyView()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

      HStack {
        if page > 0 {
          Button(L10n.tr("onboarding.back")) {
            page -= 1
          }
        }

        Spacer()

        if page < pageCount - 1 {
          Button(L10n.tr("onboarding.next")) {
            page += 1
          }
          .keyboardShortcut(.defaultAction)
        } else {
          Button(L10n.tr("onboarding.done")) {
            completeOnboarding()
          }
          .keyboardShortcut(.defaultAction)
        }
      }
    }
    .padding(20)
    .frame(width: windowSize.width, height: windowSize.height)
  }

  private var pageIndicator: some View {
    HStack(spacing: 8) {
      ForEach(0..<pageCount, id: \.self) { index in
        Circle()
          .fill(index == page ? Color.accentColor : Color.secondary.opacity(0.35))
          .frame(width: index == page ? 8 : 6, height: index == page ? 8 : 6)
          .accessibilityLabel(
            L10n.tr(
              index == page ? "onboarding.pageIndicator.current" : "onboarding.pageIndicator.other",
              index + 1,
              pageCount
            )
          )
      }
    }
    .padding(.top, 2)
    .accessibilityElement(children: .contain)
    .accessibilityLabel(L10n.tr("onboarding.pageIndicator.label", page + 1, pageCount))
  }

  private var welcomeOnboardingPage: some View {
    VStack(spacing: 10) {
      Image(systemName: "shield.lefthalf.filled")
        .font(.system(size: 36))
        .foregroundColor(.accentColor)

      Text(L10n.tr("onboarding.welcome.title"))
        .font(.title3)
        .fontWeight(.semibold)
        .multilineTextAlignment(.center)

      Text(L10n.tr("onboarding.welcome.body"))
        .font(.callout)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      calloutBox {
        VStack(alignment: .leading, spacing: 6) {
          Label {
            Text(L10n.tr("onboarding.welcome.fileVaultTip"))
              .font(.caption)
              .foregroundColor(.primary)
              .fixedSize(horizontal: false, vertical: true)
          } icon: {
            Image(systemName: "lock.fill")
              .foregroundColor(.accentColor)
          }

          Label {
            Text(L10n.tr("onboarding.welcome.cliTip"))
              .font(.caption)
              .foregroundColor(.primary)
              .fixedSize(horizontal: false, vertical: true)
          } icon: {
            Image(systemName: "terminal")
              .foregroundColor(.accentColor)
          }
        }
      }
    }
    .padding(.horizontal, 4)
  }

  private var dailyModesOnboardingPage: some View {
    VStack(spacing: 10) {
      onboardingPage(
        titleKey: "onboarding.arm.daily.title",
        bodyKey: "onboarding.arm.daily.body",
        symbol: "lock.shield"
      )

      calloutBox {
        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.tr("onboarding.arm.daily.modes.title"))
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)

          modeSummaryRow(symbol: "graduationcap", key: "onboarding.arm.modes.beginner")
          modeSummaryRow(symbol: "shield.checkered", key: "onboarding.arm.modes.normal")
          modeSummaryRow(symbol: "eye.slash", key: "onboarding.arm.modes.discreet")
        }
      }

      Text(L10n.tr("onboarding.arm.beginnerTip"))
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var highAssuranceOnboardingPage: some View {
    VStack(spacing: 10) {
      onboardingPage(
        titleKey: "onboarding.highAssurance.title",
        bodyKey: "onboarding.highAssurance.body",
        symbol: "bolt.shield"
      )

      calloutBox {
        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.tr("onboarding.highAssurance.modes.title"))
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)

          modeSummaryRow(symbol: "flame", key: "onboarding.arm.modes.panicPreset")
          modeSummaryRow(symbol: "bolt.circle", key: "onboarding.arm.modes.panicMenu")
          modeSummaryRow(symbol: "exclamationmark.shield", key: "onboarding.arm.modes.paranoid")
        }
      }

      Text(L10n.tr("onboarding.highAssurance.scriptsTip"))
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func calloutBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(10)
      .background(Color.secondary.opacity(0.08))
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private func modeSummaryRow(symbol: String, key: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: symbol)
        .font(.caption)
        .foregroundColor(.accentColor)
        .frame(width: 14, alignment: .center)
        .padding(.top, 1)

      Text(L10n.tr(key))
        .font(.caption)
        .foregroundColor(.primary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private func onboardingPage(titleKey: String, bodyKey: String, symbol: String) -> some View {
    VStack(spacing: 10) {
      Image(systemName: symbol)
        .font(.system(size: 36))
        .foregroundColor(.accentColor)

      Text(L10n.tr(titleKey))
        .font(.title3)
        .fontWeight(.semibold)
        .multilineTextAlignment(.center)

      Text(L10n.tr(bodyKey))
        .font(.callout)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 4)
  }

  private func completeOnboarding() {
    if markCompleteOnDismiss {
      settingsManager.updateSetting(\.hasCompletedOnboarding, value: true)
    }
    isPresented = false
  }
}

enum OnboardingPresenter {
  private static let windowSize = CGSize(width: 440, height: 400)
  private static var onboardingWindow: NSWindow?

  @MainActor
  static func showIfNeeded(settingsManager: UserDefaultsManager) {
    guard !settingsManager.settings.hasCompletedOnboarding else { return }
    present(settingsManager: settingsManager, markCompleteOnDismiss: true)
  }
  @MainActor
  static func present(
    settingsManager: UserDefaultsManager = .shared,
    markCompleteOnDismiss: Bool = false
  ) {
    if let existing = onboardingWindow, existing.isVisible {
      existing.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    let previousShowInDock = settingsManager.settings.showInDock
    var onboardingDockSettings = settingsManager.settings
    onboardingDockSettings.showInDock = true
    SettingsRuntimeApplier.applyDockVisibility(settings: onboardingDockSettings)

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = L10n.tr("onboarding.windowTitle")
    window.isReleasedWhenClosed = false
    window.level = .normal
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    onboardingWindow = window

    var isPresented = true
    let binding = Binding(
      get: { isPresented },
      set: { newValue in
        isPresented = newValue
        if !newValue {
          window.close()
          onboardingWindow = nil
          SettingsRuntimeApplier.applyDockVisibility(settings: settingsManager.settings)
        }
      }
    )

    let view = OnboardingView(isPresented: binding, markCompleteOnDismiss: markCompleteOnDismiss)
      .environmentObject(settingsManager)
    window.contentViewController = NSHostingController(rootView: view)
    window.center()
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    _ = previousShowInDock
  }

  /// Resets onboarding flag so the wizard shows on next launch (debug / support).
  @MainActor
  static func resetForTesting(settingsManager: UserDefaultsManager = .shared) {
    settingsManager.updateSetting(\.hasCompletedOnboarding, value: false)
  }
}
