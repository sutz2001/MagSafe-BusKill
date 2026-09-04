//
//  ParanoidModeExecutorTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
@testable import MagSafeGuardCore
import XCTest

final class ParanoidModeExecutorTests: XCTestCase {

  private var mockSystemActions: MockSystemActions!
  private var securityActions: SecurityActionsService!
  private var mockDestruction: MockDestructionPipeline!
  private var sut: ParanoidModeExecutor!

  override func setUp() {
    super.setUp()
    mockSystemActions = MockSystemActions()
    securityActions = SecurityActionsService(systemActions: mockSystemActions)
    securityActions.resetToDefault()
    securityActions.resetProtectionStateForTesting()
    mockDestruction = MockDestructionPipeline()
    let pipeline = SecurityTriggerPipeline(
      networkActions: NetworkActionsService(settingsManager: .shared),
      securityActions: securityActions,
      settingsManager: .shared
    )
    sut = ParanoidModeExecutor(
      pipeline: pipeline,
      destruction: mockDestruction,
      settingsManager: .shared,
      systemActions: mockSystemActions
    )
  }

  override func tearDown() {
    sut = nil
    mockDestruction = nil
    securityActions = nil
    mockSystemActions = nil
    super.tearDown()
  }

  func testExecuteRunsDestructionThenShutdown() {
    let done = expectation(description: "paranoid completes")
    mockDestruction.onExecute = { _ in }

    sut.execute { _, _, _ in
      done.fulfill()
    }

    wait(for: [done], timeout: 3)
    XCTAssertTrue(mockSystemActions.lockScreenCalled)
    XCTAssertTrue(mockSystemActions.executeImmediateShutdownCalled)
    XCTAssertEqual(mockDestruction.executeCallCount, 1)
  }

  func testShutdownWaitsForDestructionToFinish() {
    let slow = SlowDestructionPipeline(sleepSeconds: 0.4)
    let pipeline = SecurityTriggerPipeline(
      networkActions: NetworkActionsService(settingsManager: .shared),
      securityActions: securityActions,
      settingsManager: .shared
    )
    sut = ParanoidModeExecutor(
      pipeline: pipeline,
      destruction: slow,
      settingsManager: .shared,
      systemActions: mockSystemActions
    )

    let done = expectation(description: "finished after wipe")
    let started = Date()
    sut.execute { _, _, _ in
      done.fulfill()
    }

    wait(for: [done], timeout: 3)
    XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(started), 0.35)
    XCTAssertTrue(mockSystemActions.executeImmediateShutdownCalled)
  }

  func testParanoidContextBypassesRateLimitWithoutInlineShutdown() {
    securityActions.configureRateLimitForTesting(minimumInterval: 10, maxExecutions: 1, window: 60)
    let first = expectation(description: "standard run")
    securityActions.executeActions { _ in first.fulfill() }
    wait(for: [first], timeout: 2)

    let paranoid = expectation(description: "paranoid bypass")
    securityActions.executeActions(context: .paranoid) { result in
      XCTAssertTrue(result.executedActions.contains(.lockScreen))
      XCTAssertFalse(result.executedActions.contains(.shutdown))
      paranoid.fulfill()
    }
    wait(for: [paranoid], timeout: 2)
  }
}

private final class SlowDestructionPipeline: DestructionPipeline, @unchecked Sendable {
  let sleepSeconds: TimeInterval

  init(sleepSeconds: TimeInterval) {
    self.sleepSeconds = sleepSeconds
  }

  func execute(_ config: ParanoidConfiguration) -> DestructionResult {
    Thread.sleep(forTimeInterval: sleepSeconds)
    return .empty
  }
}
