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
      settingsManager: .shared
    )
  }

  override func tearDown() {
    sut = nil
    mockDestruction = nil
    securityActions = nil
    mockSystemActions = nil
    super.tearDown()
  }

  func testExecuteRunsShutdownAndStartsDestruction() {
    let pipelineDone = expectation(description: "paranoid pipeline completes")
    let destructionStarted = expectation(description: "destruction started")
    mockDestruction.onExecute = { _ in
      destructionStarted.fulfill()
    }

    sut.execute { _, _, _ in
      pipelineDone.fulfill()
    }

    wait(for: [pipelineDone, destructionStarted], timeout: 3)
    XCTAssertTrue(mockSystemActions.lockScreenCalled)
    XCTAssertTrue(mockSystemActions.executeImmediateShutdownCalled)
    XCTAssertEqual(mockDestruction.executeCallCount, 1)
  }

  func testPipelineDoesNotWaitForSlowDestruction() {
    let slow = SlowDestructionPipeline(sleepSeconds: 2)
    let pipeline = SecurityTriggerPipeline(
      networkActions: NetworkActionsService(settingsManager: .shared),
      securityActions: securityActions,
      settingsManager: .shared
    )
    sut = ParanoidModeExecutor(
      pipeline: pipeline,
      destruction: slow,
      settingsManager: .shared
    )

    let pipelineDone = expectation(description: "pipeline finished without waiting for wipe")
    let started = Date()
    sut.execute { _, _, _ in
      pipelineDone.fulfill()
    }

    wait(for: [pipelineDone], timeout: 1.5)
    XCTAssertLessThan(Date().timeIntervalSince(started), 1.5)
    XCTAssertTrue(mockSystemActions.executeImmediateShutdownCalled)
  }

  func testParanoidContextBypassesRateLimitAndShutsDown() {
    securityActions.configureRateLimitForTesting(minimumInterval: 10, maxExecutions: 1, window: 60)
    let first = expectation(description: "standard run")
    securityActions.executeActions { _ in first.fulfill() }
    wait(for: [first], timeout: 2)

    let paranoid = expectation(description: "paranoid bypass")
    securityActions.executeActions(context: .paranoid) { result in
      XCTAssertTrue(result.executedActions.contains(.lockScreen))
      XCTAssertTrue(result.executedActions.contains(.shutdown))
      paranoid.fulfill()
    }
    wait(for: [paranoid], timeout: 2)
    XCTAssertTrue(mockSystemActions.executeImmediateShutdownCalled)
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
