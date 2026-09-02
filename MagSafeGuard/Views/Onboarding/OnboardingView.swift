//
//  OnboardingView.swift
//  MagSafe Guard
//

import AppKit
import MagSafeGuardCore
import SwiftUI

private enum OnboardingTypography {
  static let title = Font.title2.weight(.semibold)
  static let body = Font.body
  static let sectionHeader = Font.body.weight(.semibold)
  static let heroIconSize: CGFloat = 40
  static let rowIconSize: CGFloat = 15
}

struct OnboardingView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @Binding var isPresented: Bool
  @State private var page = 0

  private let pageCount = 6
  private let windowSize = CGSize(width: 460, height: 430)
  private let markCompleteOnDismiss: Bool

  init(isPresented: Binding<Bool>, markCompleteOnDismiss: Bool = true) {
    self._isPresented = isPresented
    self.markCompleteOnDismiss = markCompleteOnDismiss
  }

  var body: some View {
    VStack(spacing: 16) {
      pageIndicator

      Group {
        switch page {
        case 0:
          welcomeOnboardingPage
        case 1:
          dailyModesOnboardingPage
        case 2:
          panicOnboardingPage
        case 3:
          paranoidOnboardingPage
        case 4:
          onboardingPage(
            titleKey: "onboarding.grace.title",
            bodyKey: "onboarding.grace.body",
            symbol: "timer"
          )
        case 5:
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
    .padding(22)
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
    VStack(spacing: 12) {
      pageHero(symbol: "shield.lefthalf.filled")

      onboardingTitle("onboarding.welcome.title")
      onboardingBody("onboarding.welcome.body", alignment: .center)

      calloutBox {
        VStack(alignment: .leading, spacing: 10) {
          iconLabelRow(symbol: "lock.fill", textKey: "onboarding.welcome.fileVaultTip")
          iconLabelRow(symbol: "terminal", textKey: "onboarding.welcome.cliTip")
        }
      }
    }
    .padding(.horizontal, 4)
  }

  private var dailyModesOnboardingPage: some View {
    VStack(spacing: 12) {
      pageHero(symbol: "lock.shield")
      onboardingTitle("onboarding.arm.daily.title")
      onboardingBody("onboarding.arm.daily.body", alignment: .center)

      calloutBox {
        VStack(alignment: .leading, spacing: 10) {
          sectionHeader("onboarding.arm.daily.modes.title")
          modeSummaryRow(symbol: "graduationcap", key: "onboarding.arm.modes.beginner")
          modeSummaryRow(symbol: "shield.checkered", key: "onboarding.arm.modes.normal")
          modeSummaryRow(symbol: "eye.slash", key: "onboarding.arm.modes.discreet")
        }
      }

      footnote("onboarding.arm.beginnerTip")
    }
  }

  private var panicOnboardingPage: some View {
    VStack(spacing: 12) {
      pageHero(symbol: "bolt.shield")
      onboardingTitle("onboarding.panic.title")
      onboardingBody("onboarding.panic.body", alignment: .center)

      calloutBox {
        VStack(alignment: .leading, spacing: 12) {
          iconLabelRow(symbol: "flame", textKey: "onboarding.panic.preset")
          iconLabelRow(symbol: "bolt.circle", textKey: "onboarding.panic.menu")
        }
      }

      footnote("onboarding.panic.footnote")
    }
  }

  private var paranoidOnboardingPage: some View {
    VStack(spacing: 12) {
      pageHero(symbol: "exclamationmark.shield")
      onboardingTitle("onboarding.paranoid.title")
      onboardingBody("onboarding.paranoid.body", alignment: .center)

      calloutBox {
        VStack(alignment: .leading, spacing: 12) {
          iconLabelRow(symbol: "externaldrive.badge.xmark", textKey: "onboarding.paranoid.feature")
          iconLabelRow(symbol: "doc.text", textKey: "onboarding.paranoid.scripts")
        }
      }

      footnote("onboarding.paranoid.footnote")
    }
  }

  private func onboardingPage(titleKey: String, bodyKey: String, symbol: String) -> some View {
    VStack(spacing: 12) {
      pageHero(symbol: symbol)
      onboardingTitle(titleKey)
      onboardingBody(bodyKey, alignment: .center)
    }
    .padding(.horizontal, 4)
  }

  private func pageHero(symbol: String) -> some View {
    Image(systemName: symbol)
      .font(.system(size: OnboardingTypography.heroIconSize))
      .foregroundColor(.accentColor)
  }

  private func onboardingTitle(_ key: String) -> some View {
    Text(L10n.tr(key))
      .font(OnboardingTypography.title)
      .multilineTextAlignment(.center)
  }

  private func onboardingBody(_ key: String, alignment: TextAlignment) -> some View {
    Text(L10n.tr(key))
      .font(OnboardingTypography.body)
      .foregroundColor(.secondary)
      .multilineTextAlignment(alignment)
      .fixedSize(horizontal: false, vertical: true)
  }

  private func sectionHeader(_ key: String) -> some View {
    Text(L10n.tr(key))
      .font(OnboardingTypography.sectionHeader)
      .foregroundColor(.secondary)
  }

  private func footnote(_ key: String) -> some View {
    Text(L10n.tr(key))
      .font(OnboardingTypography.body)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func iconLabelRow(symbol: String, textKey: String) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: symbol)
        .font(.system(size: OnboardingTypography.rowIconSize, weight: .semibold))
        .foregroundColor(.accentColor)
        .frame(width: 18, alignment: .center)
        .padding(.top, 2)

      Text(L10n.tr(textKey))
        .font(OnboardingTypography.body)
        .foregroundColor(.primary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private func calloutBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(Color.secondary.opacity(0.08))
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private func modeSummaryRow(symbol: String, key: String) -> some View {
    iconLabelRow(symbol: symbol, textKey: key)
  }

  private func completeOnboarding() {
    if markCompleteOnDismiss {
      settingsManager.updateSetting(\.hasCompletedOnboarding, value: true)
    }
    isPresented = false
  }
}

enum OnboardingPresenter {
  private static let windowSize = CGSize(width: 460, height: 430)
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
