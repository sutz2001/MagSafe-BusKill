//
//  PanicModeExecutorTests.swift
//  MagSafe Guard
//

@testable import MagSafeGuard
import XCTest

final class PanicModeExecutorTests: XCTestCase {

  private var mockSystemActions: MockSystemActions!
  private var securityActions: SecurityActionsService!
  private var sut: PanicModeExecutor!

  override func setUp() {
    super.setUp()
    mockSystemActions = MockSystemActions()
    securityActions = SecurityActionsService(systemActions: mockSystemActions)
    securityActions.resetToDefault()
    securityActions.resetProtectionStateForTesting()
    sut = PanicModeExecutor(
      securityActions: securityActions,
      systemActions: mockSystemActions
    )
  }

  override func tearDown() {
    sut = nil
    securityActions = nil
    mockSystemActions = nil
    super.tearDown()
  }

  func testExecuteRunsProtectionFirstActionsAndImmediateShutdown() {
    let expectation = expectation(description: "panic pipeline completes")

    sut.execute {
      expectation.fulfill()
    }

    waitForExpectations(timeout: 3)
    XCTAssertTrue(mockSystemActions.lockScreenCalled)
    XCTAssertTrue(mockSystemActions.executeImmediateShutdownCalled)
  }
}
