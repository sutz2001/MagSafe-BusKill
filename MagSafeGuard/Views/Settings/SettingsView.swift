//
//  SettingsView.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Main settings window UI using SwiftUI
//

import AppKit
import MagSafeGuardCore
import MagSafeGuardDomain
import SwiftUI
import UniformTypeIdentifiers

/// Main settings view with sidebar navigation interface
public struct SettingsView: View {
  @ObservedObject private var settingsManager = UserDefaultsManager.shared
  @ObservedObject private var languageManager = LanguageManager.shared
  @State private var selectedTab: SettingsTab? = .security

  /// Initializes the settings view with the security tab selected
  public init() {
    _selectedTab = State(initialValue: .security)
  }

  private enum SettingsTab: CaseIterable, Identifiable, Hashable {
    case general
    case security
    case autoArm
    case notifications
    case cloudSync
    case advanced

    var id: String { localizationKey }

    var localizationKey: String {
      switch self {
      case .general: return "settings.tab.general"
      case .security: return "settings.tab.security"
      case .autoArm: return "settings.tab.autoArm"
      case .notifications: return "settings.tab.notifications"
      case .cloudSync: return "settings.tab.cloudSync"
      case .advanced: return "settings.tab.advanced"
      }
    }

    var title: String { L10n.tr(localizationKey) }

    var symbolName: String {
      switch self {
      case .general:
        return "gear"
      case .security:
        return "lock.shield"
      case .autoArm:
        return "location.fill"
      case .notifications:
        return "bell.badge"
      case .cloudSync:
        return "icloud"
      case .advanced:
        return "wrench.and.screwdriver"
      }
    }

    static var visibleCases: [SettingsTab] {
      allCases.filter { tab in
        tab != .cloudSync || CloudSyncUIAvailability.isTabVisible
      }
    }
  }

  /// The main view body containing the sidebar navigation interface
  public var body: some View {
    NavigationSplitView {
      List(SettingsTab.visibleCases, selection: $selectedTab) { tab in
        Label(tab.title, systemImage: tab.symbolName)
          .tag(tab)
      }
      .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
      .listStyle(SidebarListStyle())
    } detail: {
      // Detail view
      if let tab = selectedTab {
        switch tab {
        case .general:
          GeneralSettingsView()
            .environmentObject(settingsManager)
            .navigationTitle(tab.title)
        case .security:
          SecuritySettingsView(onOpenNotifications: { selectedTab = .notifications })
            .environmentObject(settingsManager)
            .navigationTitle(tab.title)
        case .autoArm:
          AutoArmSettingsView()
            .environmentObject(settingsManager)
            .navigationTitle(tab.title)
        case .notifications:
          NotificationSettingsView()
            .environmentObject(settingsManager)
            .navigationTitle(tab.title)
        case .cloudSync:
          CloudSyncSettingsView()
            .environmentObject(settingsManager)
            .navigationTitle(tab.title)
        case .advanced:
          AdvancedSettingsView()
            .environmentObject(settingsManager)
            .navigationTitle(tab.title)
        }
      } else {
        Text(l10n: "settings.selectCategory")
          .font(.title2)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .navigationSplitViewStyle(.balanced)
    .frame(minWidth: 800, minHeight: 500)
    .id(languageManager.preference)
    .onAppear {
      if let selectedTab, !SettingsTab.visibleCases.contains(selectedTab) {
        self.selectedTab = .security
      }
    }
  }
}

// MARK: - General Settings Tab

struct GeneralSettingsView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @ObservedObject private var languageManager = LanguageManager.shared

  var body: some View {
    Form {
      Section {
        generalSettingsContent
      }
    }
    .formStyle(.grouped)
  }

  private var generalSettingsContent: some View {
    VStack(alignment: .leading, spacing: 16) {
      languageSection

      Divider()

      restoreArmedStateToggle

      Divider()

      menuBarIconAppearancePicker

      Divider()

      launchAtLoginToggle

      showInDockToggle
    }
    .padding()
  }

  private var languageSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(l10n: "settings.language.title")
        .font(.headline)

      Picker(selection: languageBinding) {
        ForEach(AppLanguage.allCases) { language in
          Text(L10n.tr(language.displayNameKey)).tag(language)
        }
      } label: {
        EmptyView()
      }
      .labelsHidden()
      .pickerStyle(.segmented)

      Text(l10n: "settings.language.caption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var languageBinding: Binding<AppLanguage> {
    Binding(
      get: { languageManager.preference },
      set: { languageManager.setPreference($0) }
    )
  }

  private var restoreArmedStateToggle: some View {
    Toggle(
      isOn: Binding(
        get: { settingsManager.settings.restoreArmedStateOnLaunch },
        set: { settingsManager.updateSetting(\.restoreArmedStateOnLaunch, value: $0) }
      )
    ) {
      VStack(alignment: .leading, spacing: 4) {
        Text(l10n: "settings.general.restoreArmed.title")
        Text(l10n: "settings.general.restoreArmed.caption")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }

  private var launchAtLoginToggle: some View {
    Toggle(
      isOn: Binding(
        get: { settingsManager.settings.launchAtLogin },
        set: { settingsManager.updateSetting(\.launchAtLogin, value: $0) }
      )
    ) {
      VStack(alignment: .leading, spacing: 4) {
        Text(l10n: "settings.general.launchAtLogin.title")
        Text(l10n: "settings.general.launchAtLogin.caption")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }

  private var menuBarIconAppearancePicker: some View {
    Toggle(
      isOn: Binding(
        get: { settingsManager.settings.menuBarIconAppearance == .accent },
        set: { enabled in
          settingsManager.updateSetting(
            \.menuBarIconAppearance,
            value: enabled ? .accent : .monochrome
          )
        }
      )
    ) {
      VStack(alignment: .leading, spacing: 4) {
        Text(l10n: "settings.general.menuBarIcons.title")
        Text(l10n: "settings.general.menuBarIcons.caption")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }

  private var showInDockToggle: some View {
    Toggle(
      isOn: Binding(
        get: { settingsManager.settings.showInDock },
        set: { settingsManager.updateSetting(\.showInDock, value: $0) }
      )
    ) {
      VStack(alignment: .leading, spacing: 4) {
        Text(l10n: "settings.general.showInDock.title")
        Text(showInDockCaption)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .disabled(forcesHiddenDockWhileArmed)
  }

  private var forcesHiddenDockWhileArmed: Bool {
    guard let appDelegate = NSApp.delegate as? AppDelegate else { return false }
    let controller = appDelegate.core.appController
    return controller.protectionMode.forcesHiddenDock && controller.currentState != .disarmed
  }

  private var showInDockCaption: String {
    if forcesHiddenDockWhileArmed {
      return L10n.tr("settings.general.showInDock.caption.panicArmed")
    }
    return L10n.tr("settings.general.showInDock.caption")
  }
}

// MARK: - Protection Mode & Grace (Security tab)

struct ProtectionModeSettingsSections: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  var onOpenNotifications: () -> Void = {}

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      operationProfileSection

      Divider()

      notificationsLinkSection

      Divider()

      gracePeriodSection

      Divider()

      allowCancellationToggle
    }
    .padding(.vertical, 4)
  }

  private var notificationsLinkSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(l10n: "settings.security.notifications.title")
        .font(.headline)

      Text(notificationsSummary)
        .font(.caption)
        .foregroundColor(.secondary)

      Button(L10n.tr("settings.security.openNotifications")) {
        onOpenNotifications()
      }
      .buttonStyle(.link)
      .font(.caption)
    }
  }

  private var notificationsSummary: String {
    if settingsManager.settings.isDiscreetOperation {
      return L10n.tr("settings.security.notifications.summary.off")
    }
    return L10n.tr("settings.security.notifications.summary.on")
  }

  private var operationProfileSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(l10n: "settings.general.operationProfile.title")
        .font(.headline)

      Picker(selection: operationProfileBinding) {
        ForEach(OperationProfile.selectableCases, id: \.self) { profile in
          Text(operationProfileTitle(profile)).tag(profile)
        }
      } label: {
        Text(l10n: "settings.general.operationProfile.title")
      }
      .pickerStyle(.menu)

      HStack(alignment: .top, spacing: 8) {
        TriggerRiskBadge(level: settingsManager.settings.operationProfile.selectable.presetRiskLevel, compact: true)
        Text(operationProfileCaption)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      panicRuntimeRiskNotice

      if !profileUsesDefaults {
        Button(L10n.tr(
          "settings.general.operationProfile.reset",
          operationProfileTitle(settingsManager.settings.operationProfile.selectable)
        )) {
          settingsManager.resetCurrentOperationProfile()
        }
        .buttonStyle(.link)
        .font(.caption)
      }
    }
  }

  private var profileUsesDefaults: Bool {
    OperationProfilePresets.isUsingDefaults(
      for: settingsManager.settings.operationProfile,
      settings: settingsManager.settings
    )
  }

  private var operationProfileBinding: Binding<OperationProfile> {
    Binding(
      get: { settingsManager.settings.operationProfile.selectable },
      set: { settingsManager.applyOperationProfile($0) }
    )
  }

  private var panicRuntimeRiskNotice: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .top, spacing: 8) {
        TriggerRiskBadge(level: .severe, compact: true)
        Text(l10n: "risk.panicMenu.caption")
          .font(.caption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(10)
    .background(Color.red.opacity(0.06))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private func operationProfileTitle(_ profile: OperationProfile) -> String {
    switch profile {
    case .beginner: return L10n.tr("settings.general.operationProfile.beginner")
    case .normal: return L10n.tr("settings.general.operationProfile.normal")
    case .discreet: return L10n.tr("settings.general.operationProfile.discreet")
    case .panic: return L10n.tr("settings.general.operationProfile.panic")
    case .custom: return L10n.tr("settings.general.operationProfile.custom")
    }
  }

  private var operationProfileCaption: String {
    let key: String
    switch settingsManager.settings.operationProfile.selectable {
    case .beginner: key = "settings.general.operationProfile.beginner.caption"
    case .normal: key = "settings.general.operationProfile.normal.caption"
    case .discreet: key = "settings.general.operationProfile.discreet.caption"
    case .panic: key = "settings.general.operationProfile.panic.caption"
    case .custom: key = "settings.general.operationProfile.normal.caption"
    }
    return L10n.tr(key)
  }

  private var gracePeriodSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(l10n: "settings.general.gracePeriod.title")
        .font(.headline)

      gracePeriodSlider

      Text(l10n: "settings.general.gracePeriod.caption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var gracePeriodSlider: some View {
    HStack {
      Text(l10n: "settings.general.gracePeriod.min")
        .font(.caption)
        .foregroundColor(.secondary)

      Slider(
        value: Binding(
          get: { settingsManager.settings.gracePeriodDuration },
          set: { settingsManager.updateSetting(\.gracePeriodDuration, value: $0) }
        ),
        in: 5...30,
        step: 1
      )

      Text(l10n: "settings.general.gracePeriod.max")
        .font(.caption)
        .foregroundColor(.secondary)

      Text(L10n.tr("settings.general.gracePeriod.value", Int(settingsManager.settings.gracePeriodDuration)))
        .font(.system(.body, design: .monospaced))
        .frame(width: 40, alignment: .trailing)
    }
  }

  private var allowCancellationToggle: some View {
    Toggle(
      isOn: Binding(
        get: { settingsManager.settings.allowGracePeriodCancellation },
        set: { settingsManager.updateSetting(\.allowGracePeriodCancellation, value: $0) }
      )
    ) {
      VStack(alignment: .leading, spacing: 4) {
        Text(l10n: "settings.general.cancelGrace.title")
        Text(l10n: "settings.general.cancelGrace.caption1")
          .font(.caption)
          .foregroundColor(.secondary)
        Text(l10n: "settings.general.cancelGrace.caption2")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
}

// MARK: - Security Settings Tab

struct SecuritySettingsView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  var onOpenNotifications: () -> Void = {}

  var body: some View {
    Form {
      Section {
        ProtectionModeSettingsSections(onOpenNotifications: onOpenNotifications)
          .environmentObject(settingsManager)
      }

      Section(header: securityActionsHeaderText) {
        TriggerRiskLegendView()
        enabledActionsSection
      }

      Section(header: Text(l10n: "settings.security.availableActions")) {
        ForEach(availableActions, id: \.self) { action in
          availableActionRow(for: action)
        }
      }

      Section {
        securityActionsFooter
      }

      if settingsManager.settings.securityActions.contains(.soundAlarm) {
        alarmVolumeSection
      }

      networkActionsSection
      remoteTriggerSection
      ParanoidSettingsSection()
        .environmentObject(settingsManager)
    }
    .formStyle(.grouped)
  }

  private var networkActionsSection: some View {
    Section(header: Text(l10n: "settings.network.title")) {
      Text(l10n: "settings.network.caption")
        .font(.caption)
        .foregroundColor(.secondary)

      ForEach(NetworkActionType.allCases, id: \.self) { action in
        VStack(alignment: .leading, spacing: 4) {
          Toggle(isOn: networkActionBinding(action)) {
            HStack(spacing: 8) {
              Label(action.localizedName, systemImage: action.symbolName)
              Spacer(minLength: 4)
              TriggerRiskBadge(level: action.triggerRiskLevel, compact: true)
            }
          }
          Text(networkActionRiskCaption(action))
            .font(.caption)
            .foregroundColor(.secondary)
          if action == .disableWiFi, settingsManager.settings.enabledNetworkActions.contains(.disableWiFi) {
            Text(l10n: "settings.network.disableWiFi.warning")
              .font(.caption)
              .foregroundColor(.orange)
          }
          if action == .ejectRemovableVolumes,
            settingsManager.settings.enabledNetworkActions.contains(.ejectRemovableVolumes) {
            Text(l10n: "settings.network.ejectRemovableVolumes.warning")
              .font(.caption)
              .foregroundColor(.orange)
          }
          if action == .disableBluetooth,
            settingsManager.settings.enabledNetworkActions.contains(.disableBluetooth) {
            Text(l10n: "settings.network.disableBluetooth.warning")
              .font(.caption)
              .foregroundColor(.orange)
          }
        }
      }

      if settingsManager.settings.enabledNetworkActions.contains(.webhook) {
        TextField(L10n.tr("settings.network.webhookURL"), text: webhookURLBinding)
        SecureField(L10n.tr("settings.network.webhookToken"), text: webhookTokenBinding)
      }
    }
  }

  private var remoteTriggerSection: some View {
    Section(header: Text(l10n: "settings.network.remote.title")) {
      Toggle(isOn: remoteTriggerEnabledBinding) {
        Text(l10n: "settings.network.remote.enabled")
      }
      Text(l10n: "settings.network.remote.hint")
        .font(.caption)
        .foregroundColor(.secondary)

      if settingsManager.settings.remoteTrigger.isEnabled {
        SecureField(L10n.tr("settings.network.remote.token"), text: remoteTokenBinding)
        SecureField(
          L10n.tr("settings.network.remote.paranoidToken"),
          text: remoteParanoidTokenBinding
        )
        Text(l10n: "settings.network.remote.paranoidToken.hint")
          .font(.caption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        Text(L10n.tr("settings.network.remote.triggerExample", exampleRemoteURL))
          .font(.caption)
          .foregroundColor(.secondary)
          .textSelection(.enabled)
        Text(L10n.tr("settings.network.remote.armExample", exampleRemoteArmURL))
          .font(.caption)
          .foregroundColor(.secondary)
          .textSelection(.enabled)
        Text(L10n.tr("settings.network.remote.panicExample", exampleRemotePanicURL))
          .font(.caption)
          .foregroundColor(.secondary)
          .textSelection(.enabled)
        Text(L10n.tr("settings.network.remote.paranoidExample", exampleRemoteParanoidURL))
          .font(.caption)
          .foregroundColor(.secondary)
          .textSelection(.enabled)
      }
    }
  }

  private var exampleRemoteURL: String {
    let token = settingsManager.settings.remoteTrigger.token.isEmpty
      ? "YOUR_TOKEN" : settingsManager.settings.remoteTrigger.token
    return "magsafeguard://trigger?token=\(token)"
  }

  private var exampleRemoteArmURL: String {
    let token = settingsManager.settings.remoteTrigger.token.isEmpty
      ? "YOUR_TOKEN" : settingsManager.settings.remoteTrigger.token
    return "magsafeguard://arm?token=\(token)"
  }

  private var exampleRemotePanicURL: String {
    let token = settingsManager.settings.remoteTrigger.token.isEmpty
      ? "YOUR_TOKEN" : settingsManager.settings.remoteTrigger.token
    return "magsafeguard://panic?token=\(token)"
  }

  private var exampleRemoteParanoidURL: String {
    let remote = settingsManager.settings.remoteTrigger
    let token = remote.effectiveParanoidToken.isEmpty
      ? "YOUR_TOKEN" : remote.effectiveParanoidToken
    return "magsafeguard://paranoid?token=\(token)"
  }

  private func networkActionRiskCaption(_ action: NetworkActionType) -> String {
    action.localizedRiskCaption
  }

  private func networkActionBinding(_ action: NetworkActionType) -> Binding<Bool> {
    Binding(
      get: { settingsManager.settings.enabledNetworkActions.contains(action) },
      set: { enabled in
        var actions = settingsManager.settings.enabledNetworkActions
        if enabled {
          if !actions.contains(action) { actions.append(action) }
        } else {
          actions.removeAll { $0 == action }
        }
        settingsManager.updateSetting(\.enabledNetworkActions, value: actions)
      }
    )
  }

  private var webhookURLBinding: Binding<String> {
    Binding(
      get: { settingsManager.settings.webhookURL },
      set: { settingsManager.updateSetting(\.webhookURL, value: $0) }
    )
  }

  private var webhookTokenBinding: Binding<String> {
    Binding(
      get: { NetworkActionsService.shared.loadWebhookToken() },
      set: { NetworkActionsService.shared.saveWebhookToken($0) }
    )
  }

  private var remoteTriggerEnabledBinding: Binding<Bool> {
    Binding(
      get: { settingsManager.settings.remoteTrigger.isEnabled },
      set: { enabled in
        var remote = settingsManager.settings.remoteTrigger
        remote.isEnabled = enabled
        settingsManager.updateSetting(\.remoteTrigger, value: remote)
      }
    )
  }

  private var remoteTokenBinding: Binding<String> {
    Binding(
      get: { settingsManager.settings.remoteTrigger.token },
      set: { token in
        var remote = settingsManager.settings.remoteTrigger
        remote.token = token
        settingsManager.updateSetting(\.remoteTrigger, value: remote)
      }
    )
  }

  private var remoteParanoidTokenBinding: Binding<String> {
    Binding(
      get: { settingsManager.settings.remoteTrigger.paranoidToken },
      set: { token in
        var remote = settingsManager.settings.remoteTrigger
        remote.paranoidToken = token
        settingsManager.updateSetting(\.remoteTrigger, value: remote)
      }
    )
  }

  private var securityActionsHeaderText: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(l10n: "settings.security.activeActions")
      Text(l10n: "settings.security.activeActions.hint")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var securityActionsHeader: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(l10n: "settings.security.actionsTitle")
        .font(.headline)
      Text(l10n: "settings.security.actionsCaption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
  }

  private var enabledActionsSection: some View {
    ForEach(settingsManager.settings.securityActions, id: \.self) { action in
      SecurityActionRow(
        action: action,
        isEnabled: true,
        canRemove: settingsManager.settings.securityActions.count > 1,
        onRemove: { removeSecurityAction(action) }
      )
    }
    .onMove(perform: moveSecurityActions)
  }

  private var availableActionsSection: some View {
    Section(header: Text(l10n: "settings.security.availableActions")) {
      ForEach(availableActions, id: \.self) { action in
        availableActionRow(for: action)
      }
    }
  }

  @ViewBuilder
  private func availableActionRow(for action: SecurityActionType) -> some View {
    SecurityActionRow(action: action, isEnabled: false)
      .onTapGesture {
        addSecurityAction(action)
      }
  }

  private var securityActionsFooter: some View {
    HStack {
      Text(L10n.tr("settings.security.actionsSelected", settingsManager.settings.securityActions.count))
        .font(.caption)
        .foregroundColor(.secondary)

      Spacer()

      Button(L10n.tr("settings.security.resetDefaults")) {
        settingsManager.updateSetting(\.securityActions, value: [.lockScreen, .soundAlarm])
      }
      .buttonStyle(.link)
    }
  }

  private var alarmVolumeSection: some View {
    Section(header: Text(l10n: "settings.security.alarm.title")) {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(l10n: "settings.security.alarm.volume.min")
          Slider(
            value: alarmVolumeBinding,
            in: 0.1...1.0,
            step: 0.05
          )
          Text(l10n: "settings.security.alarm.volume.max")
        }
        Text(L10n.tr("settings.security.alarm.volume.value", Int(settingsManager.settings.alarmVolume * 100)))
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Toggle(isOn: boostSystemVolumeBinding) {
        VStack(alignment: .leading, spacing: 2) {
          Text(l10n: "settings.security.alarm.boost.title")
          Text(l10n: "settings.security.alarm.boost.caption")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(l10n: "settings.security.alarm.duration.min")
          Slider(
            value: alarmDurationSliderBinding,
            in: 3...31,
            step: 1
          )
          Text(l10n: "settings.security.alarm.duration.max")
        }
        Text(alarmDurationLabel)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }

  private var alarmDurationLabel: String {
    let duration = settingsManager.settings.alarmDurationSeconds
    if duration <= 0 {
      return L10n.tr("settings.security.alarm.duration.endless")
    }
    return L10n.tr("settings.security.alarm.duration.value", Int(duration))
  }

  private var alarmDurationSliderBinding: Binding<Double> {
    Binding(
      get: {
        let duration = settingsManager.settings.alarmDurationSeconds
        return duration <= 0 ? 31 : duration
      },
      set: { newValue in
        if newValue >= 31 {
          settingsManager.updateSetting(\.alarmDurationSeconds, value: 0)
        } else {
          settingsManager.updateSetting(\.alarmDurationSeconds, value: newValue)
        }
      }
    )
  }

  private var alarmVolumeBinding: Binding<Double> {
    Binding(
      get: { Double(settingsManager.settings.alarmVolume) },
      set: { settingsManager.updateSetting(\.alarmVolume, value: Float($0)) }
    )
  }

  private var boostSystemVolumeBinding: Binding<Bool> {
    Binding(
      get: { settingsManager.settings.boostSystemVolumeForAlarm },
      set: { settingsManager.updateSetting(\.boostSystemVolumeForAlarm, value: $0) }
    )
  }

  private var availableActions: [SecurityActionType] {
    SecurityActionType.allCases.filter { action in
      !settingsManager.settings.securityActions.contains(action)
    }
  }

  private func moveSecurityActions(from source: IndexSet, to destination: Int) {
    var actions = settingsManager.settings.securityActions
    actions.move(
      fromOffsets: source,
      toOffset: destination
    )
    settingsManager.updateSetting(\.securityActions, value: actions)
  }

  private func addSecurityAction(_ action: SecurityActionType) {
    withAnimation {
      var actions = settingsManager.settings.securityActions
      actions.append(action)
      settingsManager.updateSetting(\.securityActions, value: actions)
    }
  }

  private func removeSecurityAction(_ action: SecurityActionType) {
    guard settingsManager.settings.securityActions.count > 1 else { return }

    withAnimation {
      var actions = settingsManager.settings.securityActions
      actions.removeAll { $0 == action }
      settingsManager.updateSetting(\.securityActions, value: actions)
    }
  }
}

struct SecurityActionRow: View {
  let action: SecurityActionType
  let isEnabled: Bool
  var canRemove: Bool = false
  var onRemove: (() -> Void)?

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: action.symbolName)
        .font(.title3)
        .foregroundColor(isEnabled ? .accentColor : .secondary)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 8) {
          Text(action.localizedName)
            .font(.body)
            .foregroundColor(isEnabled ? .primary : .secondary)
          TriggerRiskBadge(level: action.triggerRiskLevel, compact: true)
        }

        Text(action.localizedDescription)
          .font(.caption)
          .foregroundColor(.secondary)

        Text(action.localizedRiskCaption)
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      Spacer()

      if isEnabled {
        HStack(spacing: 8) {
          if canRemove, let onRemove {
            Button(action: onRemove) {
              Image(systemName: "minus.circle.fill")
                .font(.body)
                .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help(L10n.tr("settings.security.removeAction"))
          }

          Image(systemName: "line.3.horizontal")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      } else {
        Image(systemName: "plus.circle")
          .font(.body)
          .foregroundColor(.accentColor)
      }
    }
    .padding(.vertical, 4)
    .contentShape(Rectangle())
  }
}

// MARK: - Auto-Arm Settings Tab

struct AutoArmSettingsView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @State private var newNetwork = ""
  @State private var showingLocationManager = false
  @State private var showingAutoArmInfo = false

  var body: some View {
    Form {
      autoArmToggleSection
      autoArmTriggersSection
      trustedLocationsSection
      trustedNetworksSection
      autoArmStatusSection
    }
    .formStyle(.grouped)
    .sheet(isPresented: $showingLocationManager) {
      if let autoArmManager = getAutoArmManager() {
        TrustedLocationsView(autoArmManager: autoArmManager)
      }
    }
  }

  private var autoArmToggleSection: some View {
    Section {
      Toggle(
        isOn: Binding(
          get: { settingsManager.settings.autoArmEnabled },
          set: { settingsManager.updateSetting(\.autoArmEnabled, value: $0) }
        )
      ) {
        autoArmToggleLabel
      }
      .padding(.vertical, 4)
    }
  }

  private var autoArmTriggersSection: some View {
    Section(header: Text(l10n: "settings.autoArm.triggers")) {
      Toggle(
        isOn: Binding(
          get: { settingsManager.settings.autoArmByLocation },
          set: { settingsManager.updateSetting(\.autoArmByLocation, value: $0) }
        )
      ) {
        locationBasedToggleLabel
      }
      .disabled(!settingsManager.settings.autoArmEnabled)

      Toggle(
        isOn: Binding(
          get: { settingsManager.settings.autoArmOnUntrustedNetwork },
          set: { settingsManager.updateSetting(\.autoArmOnUntrustedNetwork, value: $0) }
        )
      ) {
        untrustedNetworkToggleLabel
      }
      .disabled(!settingsManager.settings.autoArmEnabled)
    }
  }

  private var trustedLocationsSection: some View {
    Section(header: Text(l10n: "settings.autoArm.trustedLocations")) {
      Button {
        showingLocationManager = true
      } label: {
        trustedLocationsButtonLabel
      }
      .disabled(
        !settingsManager.settings.autoArmEnabled || !settingsManager.settings.autoArmByLocation)
    }
  }

  private var trustedLocationsButtonLabel: some View {
    HStack {
      Image(systemName: "location.circle")
        .foregroundColor(.accentColor)
      Text(l10n: "settings.autoArm.manageLocations")
      Spacer()
      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
        .font(.caption)
    }
  }

  private var trustedNetworksSection: some View {
    Section(header: Text(l10n: "settings.autoArm.trustedNetworks")) {
      trustedNetworksContent
      addNetworkRow
    }
    .disabled(!settingsManager.settings.autoArmEnabled)
  }

  // MARK: - Computed Properties

  private var autoArmToggleLabel: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(l10n: "settings.autoArm.enable.title")
      Text(l10n: "settings.autoArm.enable.caption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var locationBasedToggleLabel: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(l10n: "settings.autoArm.location.title")
      Text(l10n: "settings.autoArm.location.caption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var untrustedNetworkToggleLabel: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(l10n: "settings.autoArm.network.title")
      Text(l10n: "settings.autoArm.network.caption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  @ViewBuilder
  private var trustedNetworksContent: some View {
    if settingsManager.settings.trustedNetworks.isEmpty {
      Text(l10n: "settings.autoArm.noNetworks")
        .foregroundColor(.secondary)
        .italic()
    } else {
      trustedNetworksList
    }
  }

  private var addNetworkRow: some View {
    HStack {
      TextField(L10n.tr("settings.autoArm.networkSSID"), text: $newNetwork)
        .textFieldStyle(.roundedBorder)

      Button(L10n.tr("settings.autoArm.add")) {
        addTrustedNetwork()
      }
      .disabled(newNetwork.isEmpty)
    }
  }

  private func addTrustedNetwork() {
    if !newNetwork.isEmpty {
      var networks = settingsManager.settings.trustedNetworks
      networks.append(newNetwork)
      settingsManager.updateSetting(\.trustedNetworks, value: networks)
      newNetwork = ""
    }
  }

  private var trustedNetworksList: some View {
    ForEach(settingsManager.settings.trustedNetworks, id: \.self) { network in
      trustedNetworkRow(for: network)
    }
  }

  @ViewBuilder
  private func trustedNetworkRow(for network: String) -> some View {
    HStack {
      Image(systemName: "wifi")
        .foregroundColor(.secondary)
      Text(network)
      Spacer()
      Button(
        action: {
          removeTrustedNetwork(network)
        },
        label: {
          Image(systemName: "minus.circle.fill")
            .foregroundColor(.red)
        }
      )
      .buttonStyle(.plain)
    }
  }

  private func removeTrustedNetwork(_ network: String) {
    var networks = settingsManager.settings.trustedNetworks
    networks.removeAll { $0 == network }
    settingsManager.updateSetting(\.trustedNetworks, value: networks)
  }

  private var autoArmStatusSection: some View {
    Section(header: Text(l10n: "settings.autoArm.status")) {
      autoArmStatusContent
    }
    .disabled(!settingsManager.settings.autoArmEnabled)
  }

  @ViewBuilder
  private var autoArmStatusContent: some View {
    if let autoArmManager = getAutoArmManager() {
      VStack(alignment: .leading, spacing: 8) {
        autoArmStatusRow(autoArmManager)
        if let reason = autoArmManager.inactiveReason {
          Text(reason)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        autoArmActionButton(autoArmManager)
      }
      .padding(.vertical, 4)
    } else {
      Text(l10n: "settings.autoArm.unavailable")
        .foregroundColor(.secondary)
    }
  }

  private func autoArmStatusRow(_ autoArmManager: AutoArmManager) -> some View {
    HStack {
      Image(
        systemName: autoArmManager.isAutoArmConditionMet
          ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
      )
      .foregroundColor(autoArmManager.isAutoArmConditionMet ? .orange : .green)
      Text(autoArmManager.statusSummary)
        .font(.body)
    }
  }

  @ViewBuilder
  private func autoArmActionButton(_ autoArmManager: AutoArmManager) -> some View {
    if autoArmManager.isTemporarilyDisabled {
      Button(L10n.tr("settings.autoArm.cancelTempDisable")) {
        autoArmManager.cancelTemporaryDisable()
      }
      .buttonStyle(.link)
    } else if settingsManager.settings.autoArmEnabled {
      Button(L10n.tr("settings.autoArm.tempDisable")) {
        autoArmManager.temporarilyDisable(for: 3600)
      }
      .buttonStyle(.link)
    }
  }

  private func getAutoArmManager() -> AutoArmManager? {
    // Get the AppController instance from the app delegate
    if let appDelegate = NSApp.delegate as? AppDelegate {
      return appDelegate.core.appController.getAutoArmManager()
    }
    return nil
  }
}

// MARK: - Notification Settings Tab

struct NotificationSettingsView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager

  var body: some View {
    Form {
      statusNotificationsSection
      alertSettingsSection
      systemSettingsSection
    }
    .formStyle(.grouped)
  }

  private var statusNotificationsSection: some View {
    Section(header: Text(l10n: "settings.notifications.status")) {
      Toggle(
        isOn: Binding(
          get: { settingsManager.settings.showStatusNotifications },
          set: { settingsManager.updateSetting(\.showStatusNotifications, value: $0) }
        )
      ) {
        statusNotificationToggleLabel
      }
    }
  }

  private var alertSettingsSection: some View {
    Section {
      securityAlertsToggle
      alertSoundToggle
    } header: {
      Text(l10n: "settings.notifications.alerts")
    } footer: {
      Text(l10n: "settings.notifications.discreet.footer")
    }
  }

  private var securityAlertsToggle: some View {
    Toggle(
      isOn: Binding(
        get: { settingsManager.settings.showSecurityAlerts },
        set: { settingsManager.updateSetting(\.showSecurityAlerts, value: $0) }
      )
    ) {
      securityAlertsToggleLabel
    }
  }

  private var alertSoundToggle: some View {
    Toggle(
      isOn: Binding(
        get: { settingsManager.settings.playCriticalAlertSound },
        set: { settingsManager.updateSetting(\.playCriticalAlertSound, value: $0) }
      )
    ) {
      alertSoundToggleLabel
    }
  }

  private var securityAlertsToggleLabel: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(l10n: "settings.notifications.showSecurityAlerts.title")
      Text(l10n: "settings.notifications.showSecurityAlerts.caption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var systemSettingsSection: some View {
    Section {
      systemSettingsContent
        .padding(.vertical, 4)
    }
  }

  private var statusNotificationToggleLabel: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(l10n: "settings.notifications.showStatus.title")
      Text(l10n: "settings.notifications.showStatus.caption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var alertSoundToggleLabel: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(l10n: "settings.notifications.playSound.title")
      Text(l10n: "settings.notifications.playSound.caption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var systemSettingsContent: some View {
    VStack(alignment: .leading, spacing: 12) {
      notificationPermissionsInfo

      Button(L10n.tr("settings.notifications.openSystemSettings")) {
        openSystemNotificationSettings()
      }
    }
  }

  private var notificationPermissionsInfo: some View {
    HStack {
      Image(systemName: "info.circle")
        .foregroundColor(.blue)
      Text(l10n: "settings.notifications.systemHint")
        .font(.caption)
    }
  }

  private func openSystemNotificationSettings() {
    let prefsURL = "x-apple.systempreferences:com.apple.preference.notifications"
    if let url = URL(string: prefsURL) {
      NSWorkspace.shared.open(url)
    }
  }
}

// MARK: - Advanced Settings Tab

struct AdvancedSettingsView: View {
  @EnvironmentObject var settingsManager: UserDefaultsManager
  @State private var showingExportSuccess = false
  @State private var showingImportDialog = false

  var body: some View {
    Form {
      customScriptsSection
      debugSection
      settingsManagementSection
    }
    .formStyle(.grouped)
    .alert(
      L10n.tr("settings.advanced.exported.title"), isPresented: $showingExportSuccess,
      actions: {
        Button(L10n.tr("common.ok"), role: .cancel) {
          // No action needed - SwiftUI automatically dismisses the alert
          // when a button with .cancel role is tapped
        }
      },
      message: {
        Text(l10n: "settings.advanced.exported.message")
      }
    )
    .fileImporter(
      isPresented: $showingImportDialog,
      allowedContentTypes: [.json],
      allowsMultipleSelection: false,
      onCompletion: { result in
        handleImport(result)
      }
    )
  }

  private func exportSettings() {
    do {
      let data = try settingsManager.exportSettings()
      let panel = NSSavePanel()
      panel.nameFieldStringValue = "MagSafeGuard-Settings.json"
      panel.allowedContentTypes = [.json]

      panel.begin { response in
        handleSavePanelResponse(
          response: response,
          data: data,
          panel: panel
        )
      }
    } catch {
      Log.error("Export failed", error: error, category: .settings)
    }
  }

  // MARK: - Computed Properties

  private var customScriptsSection: some View {
    Section(header: Text(l10n: "settings.advanced.customScripts")) {
      HStack(alignment: .top, spacing: 8) {
        TriggerRiskBadge(level: .severe, compact: true)
        Text(l10n: "risk.customScripts.caption")
          .font(.caption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      customScriptsContent

      scriptTimeBudgetSection

      if !BundledTriggerScripts.bundledScriptURLs().isEmpty {
        Button(L10n.tr("settings.advanced.installBundledScripts")) {
          installBundledScripts()
        }
      }

      Button(L10n.tr("settings.advanced.addScript")) {
        addCustomScript()
      }
    }
  }

  private var scriptTimeBudgetSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(l10n: "settings.advanced.scriptBudget.min")
        Slider(
          value: scriptTimeBudgetBinding,
          in: 0...30,
          step: 1
        )
        Text(l10n: "settings.advanced.scriptBudget.max")
      }
      Text(scriptTimeBudgetLabel)
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var scriptTimeBudgetLabel: String {
    let seconds = Int(settingsManager.settings.scriptTimeBudgetSeconds)
    if seconds <= 0 {
      return L10n.tr("settings.advanced.scriptBudget.skip")
    }
    return L10n.tr("settings.advanced.scriptBudget.value", seconds)
  }

  private var scriptTimeBudgetBinding: Binding<Double> {
    Binding(
      get: { settingsManager.settings.scriptTimeBudgetSeconds },
      set: { settingsManager.updateSetting(\.scriptTimeBudgetSeconds, value: $0) }
    )
  }

  private var debugSection: some View {
    Section(header: Text(l10n: "settings.advanced.debug")) {
      Toggle(
        isOn: Binding(
          get: { settingsManager.settings.debugLoggingEnabled },
          set: { settingsManager.updateSetting(\.debugLoggingEnabled, value: $0) }
        )
      ) {
        debugLoggingToggleLabel
      }
    }
  }

  private var settingsManagementSection: some View {
    Section(header: Text(l10n: "settings.advanced.management")) {
      settingsManagementButtons
    }
  }

  @ViewBuilder
  private var customScriptsContent: some View {
    if settingsManager.settings.customScripts.isEmpty {
      Text(l10n: "settings.advanced.noScripts")
        .foregroundColor(.secondary)
        .italic()
    } else {
      customScriptsList
    }
  }

  private var debugLoggingToggleLabel: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(l10n: "settings.advanced.debugLogging.title")
      Text(l10n: "settings.advanced.debugLogging.caption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var settingsManagementButtons: some View {
    HStack {
      Button(L10n.tr("settings.advanced.export")) {
        exportSettings()
      }

      Button(L10n.tr("settings.advanced.import")) {
        showingImportDialog = true
      }

      Spacer()

      Button(L10n.tr("settings.advanced.resetAll")) {
        settingsManager.resetToDefaults()
      }
      .foregroundColor(.red)
    }
  }

  private func installBundledScripts() {
    do {
      let result = try BundledTriggerScripts.installToUserScriptsDirectory()
      BundledTriggerScripts.registerInstalledPathsInSettings(result.installedPaths)
      let alert = NSAlert()
      alert.messageText = L10n.tr("settings.advanced.installBundledScripts.success.title")
      alert.informativeText = L10n.tr(
        "settings.advanced.installBundledScripts.success.message",
        result.copiedCount,
        result.destinationDirectory,
        settingsManager.settings.customScripts.count
      )
      alert.alertStyle = .informational
      alert.runModal()
    } catch {
      let alert = NSAlert()
      alert.messageText = L10n.tr("settings.advanced.installBundledScripts.failure.title")
      alert.informativeText = error.localizedDescription
      alert.alertStyle = .warning
      alert.runModal()
    }
  }

  private func addCustomScript() {
    let scriptsDir = BundledTriggerScripts.userScriptsDirectoryURL()
    try? FileManager.default.createDirectory(at: scriptsDir, withIntermediateDirectories: true)

    let panel = NSOpenPanel()
    panel.directoryURL = scriptsDir
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = [.shellScript, .unixExecutable, .plainText]
    panel.message = L10n.tr("settings.advanced.scriptPicker.message")

    guard panel.runModal() == .OK, let url = panel.url else { return }

    let path = url.path
    let allowedPrefixes = [
      "/usr/local/magsafe-scripts/",
      NSHomeDirectory() + "/.magsafe/scripts/"
    ]
    guard allowedPrefixes.contains(where: { path.hasPrefix($0) }) else {
      let alert = NSAlert()
      alert.messageText = L10n.tr("settings.advanced.scriptPicker.invalid.title")
      alert.informativeText = L10n.tr("settings.advanced.scriptPicker.invalid.message")
      alert.alertStyle = .warning
      alert.runModal()
      return
    }

    var scripts = settingsManager.settings.customScripts
    guard !scripts.contains(path) else { return }
    scripts.append(path)
    settingsManager.updateSetting(\.customScripts, value: scripts)
  }

  private var customScriptsList: some View {
    ForEach(settingsManager.settings.customScripts, id: \.self) { script in
      customScriptRow(for: script)
    }
  }

  @ViewBuilder
  private func customScriptRow(for script: String) -> some View {
    HStack {
      Image(systemName: "doc.text")
        .foregroundColor(.secondary)
      Text(script)
        .lineLimit(1)
        .truncationMode(.middle)
      Spacer()
      Button(
        action: {
          removeCustomScript(script)
        },
        label: {
          Image(systemName: "minus.circle.fill")
            .foregroundColor(.red)
        }
      )
      .buttonStyle(.plain)
    }
  }

  private func removeCustomScript(_ script: String) {
    var scripts = settingsManager.settings.customScripts
    scripts.removeAll { $0 == script }
    settingsManager.updateSetting(\.customScripts, value: scripts)
  }

  private func handleSavePanelResponse(
    response: NSApplication.ModalResponse,
    data: Data,
    panel: NSSavePanel
  ) {
    if response == .OK, let url = panel.url {
      do {
        try data.write(to: url)
        showingExportSuccess = true
      } catch {
        Log.error("Export failed", error: error, category: .settings)
      }
    }
  }

  private func handleImport(_ result: Result<[URL], Error>) {
    switch result {
    case .success(let urls):
      guard let url = urls.first else { return }
      do {
        let data = try Data(contentsOf: url)
        try settingsManager.importSettings(from: data)
      } catch {
        Log.error("Import failed", error: error, category: .settings)
      }
    case .failure(let error):
      Log.info("Import cancelled: \(error)", category: .settings)
    }
  }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
