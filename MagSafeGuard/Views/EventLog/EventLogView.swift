//
//  EventLogView.swift
//  MagSafe Guard
//

import AppKit
import MagSafeGuardCore
import SwiftUI

struct EventLogView: View {
  @ObservedObject private var viewModel: EventLogViewModel

  init(appController: AppController) {
    viewModel = EventLogViewModel(appController: appController)
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        TextField(L10n.tr("eventLog.search"), text: $viewModel.searchText)
          .textFieldStyle(.roundedBorder)

        Button(L10n.tr("eventLog.refresh")) {
          viewModel.refresh()
        }

        Button(L10n.tr("eventLog.clear")) {
          viewModel.clearLog()
        }
        .disabled(viewModel.entries.isEmpty)
      }
      .padding()

      if viewModel.filteredEntries.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "list.bullet.rectangle")
            .font(.largeTitle)
            .foregroundColor(.secondary)
          Text(l10n: "eventLog.empty.title")
            .font(.headline)
          Text(l10n: "eventLog.empty.description")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(viewModel.filteredEntries) { entry in
          EventLogRowView(entry: entry)
        }
      }
    }
    .frame(minWidth: 640, minHeight: 400)
    .onAppear { viewModel.startAutoRefresh() }
    .onDisappear { viewModel.stopAutoRefresh() }
  }
}

@MainActor
final class EventLogViewModel: ObservableObject {
  @Published var entries: [EventLogEntry] = []
  @Published var searchText = ""

  private weak var appController: AppController?
  private var refreshTimer: Timer?

  init(appController: AppController) {
    self.appController = appController
    refresh()
  }

  var filteredEntries: [EventLogEntry] {
    guard !searchText.isEmpty else { return entries }
    let query = searchText.lowercased()
    return entries.filter { entry in
      entry.event.localizedName.lowercased().contains(query)
        || (entry.details?.lowercased().contains(query) ?? false)
        || entry.state.localizedName.lowercased().contains(query)
    }
  }

  func refresh() {
    entries = appController?.getEventLog(limit: 500) ?? []
  }

  func clearLog() {
    appController?.clearEventLog()
    refresh()
  }

  func startAutoRefresh() {
    refreshTimer?.invalidate()
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.refresh()
      }
    }
  }

  func stopAutoRefresh() {
    refreshTimer?.invalidate()
    refreshTimer = nil
  }
}

extension EventLogEntry: Identifiable {
  public var id: String {
    "\(timestamp.timeIntervalSince1970)-\(event.rawValue)-\(details ?? "")"
  }
}

private struct EventLogRowView: View {
  let entry: EventLogEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(entry.event.localizedName)
          .font(.headline)
        Spacer()
        Text(entry.timestamp, style: .time)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      HStack(spacing: 8) {
        Text(entry.state.localizedName)
          .font(.caption)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Color.secondary.opacity(0.15))
          .cornerRadius(4)

        if let details = entry.details, !details.isEmpty {
          Text(details)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
      }
    }
    .padding(.vertical, 2)
  }
}

enum EventLogWindowController {
  private static var window: NSWindow?

  @MainActor
  static func show(appController: AppController) {
    if let window, window.isVisible {
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    let view = EventLogView(appController: appController)
    let hosting = NSHostingController(rootView: view)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 720, height: 480),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = L10n.tr("eventLog.windowTitle")
    window.contentViewController = hosting
    window.center()
    window.setFrameAutosaveName("EventLogWindow")
    window.isReleasedWhenClosed = false
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    self.window = window
  }
}
