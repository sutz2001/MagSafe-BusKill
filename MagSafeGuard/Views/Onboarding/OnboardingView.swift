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

  private let pageCount = 4

  var body: some View {
    VStack(spacing: 24) {
      TabView(selection: $page) {
        onboardingPage(
          titleKey: "onboarding.welcome.title",
          bodyKey: "onboarding.welcome.body",
          symbol: "shield.lefthalf.filled"
        )
        .tag(0)

        onboardingPage(
          titleKey: "onboarding.arm.title",
          bodyKey: "onboarding.arm.body",
          symbol: "lock.shield"
        )
        .tag(1)

        onboardingPage(
          titleKey: "onboarding.grace.title",
          bodyKey: "onboarding.grace.body",
          symbol: "timer"
        )
        .tag(2)

        onboardingPage(
          titleKey: "onboarding.permissions.title",
          bodyKey: "onboarding.permissions.body",
          symbol: "bell.badge"
        )
        .tag(3)
      }
      .tabViewStyle(.automatic)
      .frame(height: 280)

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
    .padding(32)
    .frame(width: 520, height: 420)
  }

  private func onboardingPage(titleKey: String, bodyKey: String, symbol: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: symbol)
        .font(.system(size: 48))
        .foregroundColor(.accentColor)

      Text(L10n.tr(titleKey))
        .font(.title2)
        .fontWeight(.semibold)
        .multilineTextAlignment(.center)

      Text(L10n.tr(bodyKey))
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal)
  }

  private func completeOnboarding() {
    settingsManager.updateSetting(\.hasCompletedOnboarding, value: true)
    isPresented = false
  }
}

enum OnboardingPresenter {
  @MainActor
  static func showIfNeeded(settingsManager: UserDefaultsManager) {
    guard !settingsManager.settings.hasCompletedOnboarding else { return }

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = L10n.tr("onboarding.windowTitle")
    window.isReleasedWhenClosed = false

    var isPresented = true
    let binding = Binding(
      get: { isPresented },
      set: { newValue in
        isPresented = newValue
        if !newValue {
          window.close()
        }
      }
    )

    let view = OnboardingView(isPresented: binding)
      .environmentObject(settingsManager)
    window.contentViewController = NSHostingController(rootView: view)
    window.center()
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
