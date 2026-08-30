//
//  AppDelegate.swift
//  MagSafe Guard
//
//  Created on 2025-07-31.
//

import AppKit
import Combine
import MagSafeGuardCore
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
  var statusItem: NSStatusItem?
  private var settingsWindow: NSWindow?
  private var settingsHostingController: NSViewController?
  private var windowDelegates: [NSWindow: WindowDelegate] = [:]
  private var cancellables = Set<AnyCancellable>()
  let core = AppDelegateCore()

  // MARK: - Constants

  private static var appName: String { L10n.tr("app.name") }

  // MARK: - Application Lifecycle

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Skip normal initialization during tests
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
      || ProcessInfo.processInfo.environment["MAGSAFE_GUARD_TEST_MODE"] != nil {
      Log.info("Running in test environment, skipping normal initialization", category: .general)
      return
    }

    // Initialize logging system including Sentry
    Log.initialize()

    // Check for previous crashes
    checkForPreviousCrashes()

    // Hide dock icon as this is a menu bar app
    NSApp.setActivationPolicy(.accessory)

    if NSApp.applicationIconImage == nil {
      NSApp.applicationIconImage = NSImage(named: "AppIcon")
    }

    // Setup AppController callbacks
    setupAppControllerCallbacks()

    // Only request notification permissions if we have a valid bundle
    if Bundle.main.bundleIdentifier != nil {
      requestNotificationPermissions()
    } else {
      Log.warning("Running without bundle identifier - notifications disabled", category: .ui)
      Log.info("TIP: To see menu bar icon in Xcode:", category: .ui)
      Log.info("  1. Product > Scheme > Edit Scheme", category: .ui)
      Log.info("  2. Run > Options > Launch: Wait for executable to be launched", category: .ui)
      Log.info("  3. Build and Run, then manually launch from build folder", category: .ui)
    }

    // Create the status item - use a strong reference
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    // Ensure the status item is retained
    statusItem?.isVisible = true

    if let button = statusItem?.button {
      // Set a title first to ensure visibility
      button.title = "MG"

      // Then try to set the icon
      updateStatusIcon()
      button.action = #selector(statusItemClicked)
      button.target = self

      // Force the button to be visible
      button.appearsDisabled = false

      // Log status
      Log.debug("Status button created: \(button)", category: .ui)
      Log.debug("Button frame: \(button.frame)", category: .ui)
      Log.debug("Button superview: \(button.superview?.description ?? "nil")", category: .ui)
      Log.debug("Button image: \(button.image?.description ?? "nil")", category: .ui)
      Log.debug("Button title: \(button.title)", category: .ui)
    } else {
      Log.fault("Failed to create status button", category: .ui)
    }

    // Create menu
    setupMenu()

    NotificationCenter.default.addObserver(
      forName: .appLanguageDidChange,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.setupMenu()
      self?.refreshStatusItemAccessibility()
      self?.settingsWindow?.title = L10n.tr("app.settingsWindow")
    }

    // Configure accessibility features
    setupAccessibilityFeatures()

    setupGracePeriodObservation()
    restoreArmedStateIfNeeded()

    Task { @MainActor in
      OnboardingPresenter.showIfNeeded(settingsManager: UserDefaultsManager.shared)
    }

    // AppController now handles power monitoring internally
  }

  private func setupGracePeriodObservation() {
    core.appController.$gracePeriodRemaining
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.updateStatusIcon()
        self?.refreshStatusItemAccessibility()
      }
      .store(in: &cancellables)
  }

  private func restoreArmedStateIfNeeded() {
    let settings = UserDefaultsManager.shared.settings
    guard settings.restoreArmedStateOnLaunch,
      ApplicationStatePersistence.loadWasArmed(),
      core.appController.currentState == .disarmed
    else { return }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.core.appController.arm { result in
        if case .failure(let error) = result {
          Log.warning("Failed to restore armed state: \(error.localizedDescription)", category: .ui)
          ApplicationStatePersistence.clear()
        }
      }
    }
  }

  private func setupMenu() {
    let menu = core.createMenu(for: self)
    statusItem?.menu = menu
  }

  private func setupAccessibilityFeatures() {
    // Configure accessibility manager
    AccessibilityManager.shared.configureVoiceOverSupport()
    AccessibilityManager.shared.configureKeyboardNavigation()

    refreshStatusItemAccessibility()

    Log.info("Accessibility features configured", category: .general)
  }

  private func refreshStatusItemAccessibility() {
    guard let button = statusItem?.button else { return }
    let statusDescription = core.appController.statusDescription
    button.setAccessibilityLabel(L10n.tr("app.name"))
    button.setAccessibilityHelp(L10n.tr("app.accessibility.menuHint", statusDescription))
    button.setAccessibilityRole(.menuButton)
  }

  private func setupAppControllerCallbacks() {
    // Handle state changes
    core.appController.onStateChange = { [weak self] _, _ in
      DispatchQueue.main.async {
        self?.updateStatusIcon()
        self?.setupMenu()
      }
    }

    // Handle notifications
    core.appController.onNotification = { [weak self] title, message in
      self?.showNotification(title: title, message: message)
    }
  }

  private func updateStatusIcon() {
    if let button = statusItem?.button {
      let statusDescription = core.appController.statusDescription
      let imageName = core.statusMenuBarImageName()
      let showGraceCountdown = core.appController.currentState == .gracePeriod

      if let image = NSImage(named: imageName),
        let templateImage = image.copy() as? NSImage
      {
        templateImage.isTemplate = true
        button.image = templateImage
        if showGraceCountdown {
          let seconds = max(0, Int(ceil(core.appController.gracePeriodRemaining)))
          button.title = L10n.tr("menu.graceCountdown", seconds)
        } else {
          button.title = ""
        }
        Log.debug("Menu bar icon updated: \(imageName)", category: .ui)
      } else if let image = NSImage(systemSymbolName: core.statusIconName(), accessibilityDescription: Self.appName) {
        guard let templateImage = image.copy() as? NSImage else { return }
        templateImage.isTemplate = true
        button.image = templateImage
        if showGraceCountdown {
          let seconds = max(0, Int(ceil(core.appController.gracePeriodRemaining)))
          button.title = L10n.tr("menu.graceCountdown", seconds)
        } else {
          button.title = ""
        }
        Log.debug("Menu bar icon updated (SF Symbol fallback): \(core.statusIconName())", category: .ui)
      } else {
        Log.warning("Failed to load menu bar icon, using text fallback", category: .ui)
        button.image = nil
        button.title = core.isArmed ? "MG!" : "MG"
      }

      button.contentTintColor = nil

      button.setAccessibilityLabel(L10n.tr("app.name"))
      button.setAccessibilityValue(statusDescription)
      button.setAccessibilityHelp(
        L10n.tr("app.accessibility.menuHint", statusDescription))

      if AccessibilityManager.shared.isVoiceOverEnabled {
        AccessibilityAnnouncement.announceStateChange(
          component: L10n.tr("app.accessibility.statusComponent"), newState: statusDescription)
      }
    }
  }

  @objc private func statusItemClicked(_ sender: AnyObject?) {
    // Menu will show automatically when clicked
  }

  @objc func toggleArmed() {
    if core.appController.currentState == .disarmed {
      core.appController.arm { [weak self] result in
        switch result {
        case .success:
          // Notifications are handled by AppController callback
          break
        case .failure(let error):
          self?.showNotification(
            title: AppDelegate.appName,
            message: L10n.tr("app.fail.arm", error.localizedDescription)
          )
        }
      }
    } else {
      core.appController.disarm { [weak self] result in
        switch result {
        case .success:
          // Notifications are handled by AppController callback
          break
        case .failure(let error):
          self?.showNotification(
            title: AppDelegate.appName,
            message: L10n.tr("app.fail.disarm", error.localizedDescription)
          )
        }
      }
    }
  }

  @objc func showSettings() {
    Log.info("showSettings called", category: .ui)

    // Safe window management pattern
    if let existingWindow = settingsWindow {
      Log.info("Bringing existing settings window to front", category: .ui)
      existingWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    Log.info("Creating new settings window", category: .ui)

    // Create new window safely
    let settingsView = SettingsView()
      .environmentObject(UserDefaultsManager.shared)

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )

    window.title = L10n.tr("app.settingsWindow")

    // Create and retain the hosting controller
    let hostingController = NSHostingController(rootView: settingsView)
    settingsHostingController = hostingController
    window.contentViewController = hostingController

    window.center()
    // Temporarily disable frame autosave to ensure window appears
    // window.setFrameAutosaveName("SettingsWindow")
    window.animationBehavior = .none
    window.isReleasedWhenClosed = false  // Prevent window from being released

    // Clean up when window closes
    let delegate = WindowDelegate { [weak self] in
      Task { @MainActor in
        self?.windowDelegates.removeValue(forKey: window)
        window.contentViewController = nil
        self?.settingsWindow = nil
        self?.settingsHostingController = nil

        // Return to accessory mode if no windows are open
        if self?.settingsWindow == nil {
          NSApp.setActivationPolicy(.accessory)
        }
      }
    }

    window.delegate = delegate
    windowDelegates[window] = delegate
    settingsWindow = window

    // Temporarily make the app regular so it appears in Dock and Cmd+Tab
    NSApp.setActivationPolicy(.regular)

    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    // Force window to be visible
    window.orderFrontRegardless()
    window.setIsVisible(true)

    Log.info("Settings window created and shown successfully", category: .ui)
    Log.info("Window visible: \(window.isVisible), frame: \(window.frame)", category: .ui)
  }

  @objc func showAbout() {
    Task { @MainActor in
      AboutPresenter.show()
    }
  }

  private func requestNotificationPermissions() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
      if granted {
        Log.info("Notification permissions granted", category: .ui)
      } else if let error = error {
        Log.error("Notification permission error", error: error, category: .ui)
      }
    }
  }

  private func showNotification(title: String, message: String) {
    let (notificationTitle, text, identifier) = core.createNotificationContent(
      title: title, message: message)

    // Check if we can use UNUserNotificationCenter
    guard Bundle.main.bundleIdentifier != nil else {
      // Fallback: Just print to console when running from Xcode
      Log.info("🔔 NOTIFICATION: \(notificationTitle) - \(text)", category: .ui)

      // Alternative: Show an alert window
      DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = notificationTitle
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.tr("common.ok"))
        alert.runModal()
      }
      return
    }

    let content = UNMutableNotificationContent()
    content.title = notificationTitle
    content.body = text
    content.sound = UNNotificationSound.default

    // Trigger immediately
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

    // Add the request to notification center
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        Log.error("Error showing notification", error: error, category: .ui)
      }
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    // Log application termination
    core.appController.logEvent(.applicationTerminating, details: "App terminating")

    // Save any pending state
    saveApplicationState()

    Log.info("Application terminating", category: .ui)
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    // Refresh menu when app becomes active
    setupMenu()

    Log.info("Application became active", category: .ui)
  }

  func applicationDidResignActive(_ notification: Notification) {
    Log.info("Application resigned active", category: .ui)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Menu bar apps should not quit when the last window is closed
    return false
  }

  // MARK: - Crash Reporting

  private func checkForPreviousCrashes() {
    #if DEBUG
      if let crashInfo = UserDefaults.standard.dictionary(forKey: "lastCrashInfo") {
        Log.warning("Previous crash detected:", category: .ui)
        Log.warning("  Exception: \(crashInfo["exception"] ?? "Unknown")", category: .ui)
        Log.warning("  Reason: \(crashInfo["reason"] ?? "Unknown")", category: .ui)
        Log.warning("  Time: \(crashInfo["timestamp"] ?? "Unknown")", category: .ui)

        // Clear the crash info
        UserDefaults.standard.removeObject(forKey: "lastCrashInfo")

        // Show alert if running in development
        if Bundle.main.bundleIdentifier == nil {
          DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = L10n.tr("app.crash.title")
            alert.informativeText = L10n.tr(
              "app.crash.message",
              crashInfo["exception"] as? String ?? "Unknown",
              crashInfo["reason"] as? String ?? "Unknown"
            )
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.tr("common.ok"))
            alert.runModal()
          }
        }
      }
    #endif
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    // Check if we're in a critical state
    if core.appController.currentState == .gracePeriod {
      // Show alert asking user to confirm
      let alert = NSAlert()
      alert.messageText = L10n.tr("app.quit.grace.title")
      alert.informativeText = L10n.tr("app.quit.grace.message")
      alert.alertStyle = .warning
      alert.addButton(withTitle: L10n.tr("app.quit.grace.cancel"))
      alert.addButton(withTitle: L10n.tr("app.quit.grace.confirm"))

      let response = alert.runModal()
      if response == .alertFirstButtonReturn {
        return .terminateCancel
      }
    }

    return .terminateNow
  }

  private func saveApplicationState() {
    let wasArmed = core.appController.currentState == .armed
    if wasArmed {
      ApplicationStatePersistence.saveWasArmed(true)
    } else {
      ApplicationStatePersistence.clear()
    }
    Log.debug("Saved armed persistence: \(wasArmed)", category: .ui)
  }
}

// MARK: - Window Delegate

/// Simple window delegate to handle window close events
class WindowDelegate: NSObject, NSWindowDelegate {
  private let onClose: () -> Void

  init(onClose: @escaping () -> Void) {
    self.onClose = onClose
    super.init()
  }

  func windowWillClose(_ notification: Notification) {
    onClose()
  }
}
