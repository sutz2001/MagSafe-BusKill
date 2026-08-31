//
//  PowerMonitorCoreTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
import XCTest

final class PowerMonitorCoreTests: XCTestCase {

  private var sut: PowerMonitorCore!

  override func setUp() {
    super.setUp()
    sut = PowerMonitorCore(pollingInterval: 0.5)
    sut.reset()
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  func testProcessACPowerSource() {
    let sources: [[String: Any]] = [
      [
        "Power Source State": "AC Power",
        "Current Capacity": 80,
        "Max Capacity": 100,
        "Is Charging": true,
        "AdapterDetails": ["Watts": 67]
      ]
    ]

    let info = sut.processPowerSourceInfo(sources)

    XCTAssertEqual(info?.state, .connected)
    XCTAssertEqual(info?.batteryLevel, 80)
    XCTAssertTrue(info?.isCharging == true)
    XCTAssertEqual(info?.adapterWattage, 67)
  }

  func testProcessBatteryPowerSource() {
    let sources: [[String: Any]] = [
      [
        "Power Source State": "Battery Power",
        "Current Capacity": 42,
        "Max Capacity": 100,
        "Is Charging": false
      ]
    ]

    let info = sut.processPowerSourceInfo(sources)

    XCTAssertEqual(info?.state, .disconnected)
    XCTAssertEqual(info?.batteryLevel, 42)
    XCTAssertFalse(info?.isCharging == true)
  }

  func testHasPowerStateChangedOnFirstReading() {
    let info = PowerMonitorCore.PowerInfo(
      state: .connected,
      batteryLevel: 90,
      isCharging: true,
      adapterWattage: nil,
      timestamp: Date()
    )

    XCTAssertTrue(sut.hasPowerStateChanged(newInfo: info))
    XCTAssertEqual(sut.currentPowerInfo?.state, .connected)
  }

  func testHasPowerStateChangedWhenStateUnchanged() {
    let connected = PowerMonitorCore.PowerInfo(
      state: .connected, batteryLevel: 90, isCharging: true, adapterWattage: nil, timestamp: Date())
    _ = sut.hasPowerStateChanged(newInfo: connected)

    let stillConnected = PowerMonitorCore.PowerInfo(
      state: .connected, batteryLevel: 85, isCharging: false, adapterWattage: 30,
      timestamp: Date())

    XCTAssertFalse(sut.hasPowerStateChanged(newInfo: stillConnected))
    XCTAssertEqual(sut.currentPowerInfo?.batteryLevel, 85)
  }

  func testHasPowerStateChangedOnDisconnect() {
    let connected = PowerMonitorCore.PowerInfo(
      state: .connected, batteryLevel: 90, isCharging: true, adapterWattage: nil, timestamp: Date())
    _ = sut.hasPowerStateChanged(newInfo: connected)

    let disconnected = PowerMonitorCore.PowerInfo(
      state: .disconnected, batteryLevel: 89, isCharging: false, adapterWattage: nil,
      timestamp: Date())

    XCTAssertTrue(sut.hasPowerStateChanged(newInfo: disconnected))
  }

  func testObjectiveCCompatibilityHelpers() {
    let info = PowerMonitorCore.PowerInfo(
      state: .connected, batteryLevel: 55, isCharging: false, adapterWattage: nil,
      timestamp: Date())
    _ = sut.hasPowerStateChanged(newInfo: info)

    XCTAssertEqual(sut.getBatteryLevel(), 55)
    XCTAssertTrue(sut.isPowerConnected())
  }
}
