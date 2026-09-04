//
//  ParanoidHotkeyService.swift
//  MagSafe Guard
//

import Carbon
import Foundation
import MagSafeGuardCore

/// Global paranoid trigger hotkey (active while the app is running).
///
/// Default: **⌃⌘⇧P** (Control+Command+Shift+P). Distinct from panic **⌃⌘P**.
public final class ParanoidHotkeyService {

  public static let shared = ParanoidHotkeyService()

  /// Virtual key code for `P` (`kVK_ANSI_P`).
  public static let keyCode = UInt32(kVK_ANSI_P)

  /// Control + Command + Shift — “P for Paranoid”, does not collide with panic ⌃⌘P.
  public static let modifiers = UInt32(controlKey | cmdKey | shiftKey)

  /// Localized shortcut label for UI (e.g. menu hints).
  public static var displayShortcut: String { L10n.tr("paranoid.hotkey.shortcut") }

  private let signature: OSType = 0x4D_47_50_52  // "MGPR"
  private let hotKeyIDValue: UInt32 = 1

  private var hotKeyRef: EventHotKeyRef?
  private var eventHandler: EventHandlerRef?
  private var onTrigger: (() -> Void)?

  private init() {}

  /// Registers the global hotkey. Replaces any previous registration.
  public func start(onTrigger: @escaping () -> Void) {
    stop()
    self.onTrigger = onTrigger
    installHandler()
    registerHotKey()
  }

  /// Unregisters the global hotkey.
  public func stop() {
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
      self.hotKeyRef = nil
    }
    if let eventHandler {
      RemoveEventHandler(eventHandler)
      self.eventHandler = nil
    }
    onTrigger = nil
  }

  private func installHandler() {
    var eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed)
    )

    let status = InstallEventHandler(
      GetApplicationEventTarget(),
      { _, event, userData -> OSStatus in
        guard let userData, let event else { return OSStatus(eventNotHandledErr) }
        let service = Unmanaged<ParanoidHotkeyService>.fromOpaque(userData).takeUnretainedValue()
        return service.handleHotKeyEvent(event)
      },
      1,
      &eventType,
      Unmanaged.passUnretained(self).toOpaque(),
      &eventHandler
    )

    if status != noErr {
      Log.error("Failed to install paranoid hotkey handler: \(status)", category: .security)
    }
  }

  private func registerHotKey() {
    let hotKeyID = EventHotKeyID(signature: signature, id: hotKeyIDValue)
    var mutableID = hotKeyID
    let status = RegisterEventHotKey(
      Self.keyCode,
      Self.modifiers,
      mutableID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )

    if status != noErr {
      Log.error("Failed to register paranoid hotkey (⌃⌘⇧P): \(status)", category: .security)
      hotKeyRef = nil
    } else {
      Log.info("Paranoid hotkey registered: \(Self.displayShortcut)", category: .security)
    }
  }

  private func handleHotKeyEvent(_ event: EventRef?) -> OSStatus {
    guard let event else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
      event,
      EventParamName(kEventParamDirectObject),
      EventParamType(typeEventHotKeyID),
      nil,
      MemoryLayout<EventHotKeyID>.size,
      nil,
      &hotKeyID
    )

    guard status == noErr,
      hotKeyID.signature == signature,
      hotKeyID.id == hotKeyIDValue
    else {
      return OSStatus(eventNotHandledErr)
    }

    DispatchQueue.main.async { [weak self] in
      self?.onTrigger?()
    }
    return noErr
  }
}
