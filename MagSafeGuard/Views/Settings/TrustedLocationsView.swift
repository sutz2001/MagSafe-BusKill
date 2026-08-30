//
//  TrustedLocationsView.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  UI for managing trusted locations for auto-arm functionality
//

import CoreLocation
import MapKit
import SwiftUI

/// View for managing trusted locations in auto-arm settings
struct TrustedLocationsView: View {
  @Environment(\.dismiss) var dismiss
  @State private var locations: [TrustedLocation] = []
  @State private var showingAddLocation = false
  @State private var showingLocationPicker = false
  @State private var newLocationName = ""
  @State private var newLocationCoordinate = CLLocationCoordinate2D()
  @State private var newLocationRadius: Double = 100.0
  @State private var showingPermissionAlert = false

  /// Access to the auto-arm manager through AppController
  let autoArmManager: AutoArmManager?

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        if locations.isEmpty {
          emptyStateView
        } else {
          locationsList
        }
      }
      .navigationTitle(L10n.tr("locations.title"))
      .toolbar {
        toolbarContent
      }
    }
    .onAppear {
      loadLocations()
      checkLocationPermission()
    }
    .sheet(isPresented: $showingAddLocation) {
      AddLocationView(
        locationName: $newLocationName,
        coordinate: $newLocationCoordinate,
        radius: $newLocationRadius,
        onSave: addLocation,
        onCancel: { showingAddLocation = false }
      )
    }
    .alert(L10n.tr("locations.permission.title"), isPresented: $showingPermissionAlert) {
      Button(L10n.tr("locations.openSettings")) {
        let urlString =
          "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
        if let url = URL(string: urlString) {
          NSWorkspace.shared.open(url)
        }
      }
      Button(L10n.tr("common.cancel"), role: .cancel) {
        // Cancel action
      }
    } message: {
      Text(l10n: "locations.permission.message")
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "location.slash")
        .font(.system(size: 60))
        .foregroundColor(.secondary)

      Text(l10n: "locations.empty.title")
        .font(.title2)
        .fontWeight(.medium)

      Text(l10n: "locations.empty.caption")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button(L10n.tr("locations.addFirst")) {
        showingAddLocation = true
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button(L10n.tr("locations.done")) {
        dismiss()
      }
    }
    ToolbarItem(placement: .primaryAction) {
      Button {
        showingAddLocation = true
      } label: {
        Image(systemName: "plus")
      }
    }
  }

  private var locationsList: some View {
    List {
      ForEach(locations, id: \.id) { location in
        LocationRow(location: location, onRemove: removeLocationHandler(for: location))
      }
    }
  }

  private func removeLocationHandler(for location: TrustedLocation) -> () -> Void {
    return {
      removeLocation(location)
    }
  }

  private func loadLocations() {
    locations = autoArmManager?.getTrustedLocations() ?? []
  }

  private func checkLocationPermission() {
    // Skip in test environment to avoid permission dialogs
    guard ProcessInfo.processInfo.environment["CI"] == nil else { return }

    let status = CLLocationManager().authorizationStatus
    if status == .denied || status == .restricted {
      showingPermissionAlert = true
    }
  }

  private func addLocation() {
    let location = TrustedLocation(
      name: newLocationName,
      coordinate: newLocationCoordinate,
      radius: newLocationRadius
    )

    autoArmManager?.addTrustedLocation(location)
    locations.append(location)

    // Reset form
    newLocationName = ""
    newLocationRadius = 100.0
    showingAddLocation = false
  }

  private func removeLocation(_ location: TrustedLocation) {
    autoArmManager?.removeTrustedLocation(id: location.id)
    locations.removeAll { $0.id == location.id }
  }
}

/// Row view for displaying a trusted location
struct LocationRow: View {
  let location: TrustedLocation
  let onRemove: () -> Void

  var body: some View {
    HStack {
      locationInfo
      Spacer()
      deleteButton
    }
    .padding(.vertical, 4)
  }

  private var locationInfo: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(location.name)
        .font(.body)
      locationDetails
    }
  }

  private var locationDetails: some View {
    HStack(spacing: 4) {
      Image(systemName: "location.fill")
        .font(.caption)
        .foregroundColor(.secondary)

      Text(L10n.tr("locations.radiusRow", Int(location.radius)))
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var deleteButton: some View {
    Button(action: onRemove) {
      Image(systemName: "minus.circle.fill")
        .foregroundColor(.red)
    }
    .buttonStyle(.plain)
  }
}

/// View for adding a new trusted location
struct AddLocationView: View {
  @Binding var locationName: String
  @Binding var coordinate: CLLocationCoordinate2D
  @Binding var radius: Double
  let onSave: () -> Void
  let onCancel: () -> Void

  @State private var useCurrentLocation = true
  @State private var manualLatitude = ""
  @State private var manualLongitude = ""
  @State private var isLoadingLocation = false

  private let locationManager = CLLocationManager()

  var body: some View {
    NavigationView {
      Form {
        locationDetailsSection
        trustRadiusSection
      }
      .navigationTitle(L10n.tr("locations.add.title"))
      .toolbar {
        addLocationToolbar
      }
    }
    .frame(width: 500, height: 400)
  }

  private var locationDetailsSection: some View {
    Section(header: Text(l10n: "locations.details")) {
      TextField(L10n.tr("locations.nameField"), text: $locationName)
      locationSourcePicker

      if !useCurrentLocation {
        manualLocationFields
      }
    }
  }

  private var locationSourcePicker: some View {
    Picker(L10n.tr("locations.sourcePicker"), selection: $useCurrentLocation) {
      Text(l10n: "locations.currentLocation").tag(true)
      Text(l10n: "locations.manualEntry").tag(false)
    }
    .pickerStyle(.segmented)
  }

  private var trustRadiusSection: some View {
    Section(header: Text(l10n: "locations.trustRadius")) {
      trustRadiusContent
    }
  }

  private func getCurrentLocationAndSave() {
    isLoadingLocation = true

    // Skip location request in CI environment
    if ProcessInfo.processInfo.environment["CI"] != nil {
      // Use Apple Park as default for CI
      coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
      isLoadingLocation = false
      onSave()
      return
    }

    // Request current location
    locationManager.requestLocation()

    // For simplicity, we'll use a default location
    // In a real app, you'd implement CLLocationManagerDelegate
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      // Use Apple Park as default for demo
      coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
      isLoadingLocation = false
      onSave()
    }
  }

  private func saveWithManualCoordinates() {
    guard let lat = Double(manualLatitude),
      let lon = Double(manualLongitude)
    else {
      return
    }

    coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    onSave()
  }

  private var manualLocationFields: some View {
    HStack {
      TextField(L10n.tr("locations.latitude"), text: $manualLatitude)
        .textFieldStyle(.roundedBorder)
      TextField(L10n.tr("locations.longitude"), text: $manualLongitude)
        .textFieldStyle(.roundedBorder)
    }
  }

  private var trustRadiusContent: some View {
    VStack(alignment: .leading) {
      Text(L10n.tr("locations.radiusMeters", Int(radius)))
        .font(.headline)

      Slider(value: $radius, in: 50...1000, step: 50)

      Text(l10n: "locations.radiusCaption")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  @ToolbarContentBuilder
  private var addLocationToolbar: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button(L10n.tr("common.cancel"), action: onCancel)
    }
    ToolbarItem(placement: .confirmationAction) {
      Button(L10n.tr("locations.save")) {
        if useCurrentLocation {
          getCurrentLocationAndSave()
        } else {
          saveWithManualCoordinates()
        }
      }
      .disabled(locationName.isEmpty || isLoadingLocation)
    }
  }
}

// MARK: - Preview

#if DEBUG
  struct TrustedLocationsView_Previews: PreviewProvider {
    static var previews: some View {
      TrustedLocationsView(autoArmManager: nil)
        .environmentObject(UserDefaultsManager())
        .frame(width: 600, height: 400)
    }
  }
#endif
