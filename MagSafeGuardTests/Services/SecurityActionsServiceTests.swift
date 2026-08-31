//
//  SecurityActionsServiceTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
import MagSafeGuardDomain
import XCTest

final class SecurityActionsServiceTests: XCTestCase {

  private var sut: SecurityActionsService!
  private var mockSystemActions: MockSystemActions!

  override func setUp() {
    super.setUp()
    mockSystemActions = MockSystemActions()
    sut = SecurityActionsService(systemActions: mockSystemActions)
    sut.resetToDefault()
    sut.resetProtectionStateForTesting()
    sut.configureRateLimitForTesting(minimumInterval: 0, maxExecutions: 100, window: 60)
    sut.configureCircuitBreakerForTesting(maxFailures: 3, openDuration: 60)
  }

  override func tearDown() {
    sut = nil
    mockSystemActions = nil
    super.tearDown()
  }

  func testExecuteActionsRunsLockScreen() {
    let expectation = expectation(description: "actions complete")
    sut.executeActions { result in
      XCTAssertTrue(result.allSucceeded)
      XCTAssertTrue(result.executedActions.contains(.lockScreen))
      expectation.fulfill()
    }
    waitForExpectations(timeout: 2)
    XCTAssertTrue(mockSystemActions.lockScreenCalled)
  }

  func testRateLimitBlocksRapidExecutions() {
    sut.configureRateLimitForTesting(minimumInterval: 10, maxExecutions: 100, window: 60)
    sut.resetProtectionStateForTesting()

    let first = expectation(description: "first execution")
    sut.executeActions { _ in first.fulfill() }
    waitForExpectations(timeout: 2)

    let second = expectation(description: "rate limited")
    sut.executeActions { result in
      XCTAssertFalse(result.allSucceeded)
      XCTAssertEqual(result.failedActions.first?.error as? SecurityActionError, .rateLimitExceeded)
      second.fulfill()
    }
    waitForExpectations(timeout: 2)
    XCTAssertEqual(mockSystemActions.lockScreenCallCount, 1)
  }

  func testCircuitBreakerOpensAfterRepeatedFailures() {
    sut.configureCircuitBreakerForTesting(maxFailures: 2, openDuration: 120)
    mockSystemActions.lockScreenShouldSucceed = false

    runUntilCircuitOpen(attempts: 2)

    mockSystemActions.lockScreenShouldSucceed = true
    let blocked = expectation(description: "circuit open")
    sut.executeActions { result in
      XCTAssertTrue(result.failedActions.isEmpty == false)
      if let error = result.failedActions.first?.error as? SecurityActionError,
        case .systemError = error
      {
        // expected
      } else {
        XCTFail("Expected circuit breaker system error")
      }
      blocked.fulfill()
    }
    waitForExpectations(timeout: 2)
    XCTAssertEqual(mockSystemActions.lockScreenCallCount, 2)
  }

  private func runUntilCircuitOpen(attempts: Int) {
    for index in 0..<attempts {
      let exp = expectation(description: "attempt \(index)")
      sut.executeActions { _ in exp.fulfill() }
      waitForExpectations(timeout: 2)
    }
  }
}
