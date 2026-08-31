//
//  AuthenticationServiceTests.swift
//  MagSafe Guard
//

import LocalAuthentication
import XCTest

@testable import MagSafeGuard

final class AuthenticationServiceTests: XCTestCase {

  private var mockContext: MockAuthenticationContext!
  private var sut: AuthenticationService!

  override func setUp() {
    super.setUp()
    mockContext = MockAuthenticationContext()
    sut = AuthenticationService(
      contextFactory: MockAuthenticationContextFactory(mockContext: mockContext)
    )
    sut.resetAuthenticationAttempts()
  }

  override func tearDown() {
    sut = nil
    mockContext = nil
    super.tearDown()
  }

  // MARK: - Availability

  func testIsBiometricAuthenticationAvailableWhenSupported() {
    mockContext.canEvaluatePolicyResult = true

    XCTAssertTrue(sut.isBiometricAuthenticationAvailable())
    XCTAssertTrue(mockContext.canEvaluatePolicyCalled)
  }

  func testIsBiometricAuthenticationAvailableWhenUnsupported() {
    mockContext.canEvaluatePolicyResult = false
    mockContext.canEvaluatePolicyError = LAError(.biometryNotAvailable) as NSError

    XCTAssertFalse(sut.isBiometricAuthenticationAvailable())
  }

  func testBiometryTypeReturnsContextValue() {
    mockContext.mockBiometryType = .faceID

    XCTAssertEqual(sut.biometryType, .faceID)
  }

  // MARK: - Successful authentication

  func testAuthenticateSuccess() {
    let expectation = expectation(description: "auth success")
    mockContext.evaluatePolicyShouldSucceed = true

    sut.authenticate(reason: "Arm protection") { result in
      self.assertSuccess(result)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
    XCTAssertTrue(mockContext.evaluatePolicyCalled)
    XCTAssertEqual(mockContext.evaluatePolicyReason, "Arm protection")
  }

  // MARK: - Failures and cancellation

  func testAuthenticateFailureMapsLAError() {
    let expectation = expectation(description: "auth failure")
    mockContext.evaluatePolicyShouldSucceed = false
    mockContext.evaluatePolicyError = LAError(.authenticationFailed)

    sut.authenticate(reason: "Disarm protection") { result in
      guard case .failure(let error) = result,
        let authError = error as? AuthenticationService.AuthenticationError
      else {
        return XCTFail("Expected authentication failure")
      }
      XCTAssertEqual(authError, .authenticationFailed)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testAuthenticateUserCancelReturnsCancelled() {
    let expectation = expectation(description: "auth cancelled")
    mockContext.evaluatePolicyShouldSucceed = false
    mockContext.evaluatePolicyError = LAError(.userCancel)

    sut.authenticate(reason: "Cancel test") { result in
      self.assertCancelled(result)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testAuthenticateRejectsEmptyReason() {
    let expectation = expectation(description: "empty reason")

    sut.authenticate(reason: "   ") { result in
      guard case .failure(let error) = result,
        let authError = error as? AuthenticationService.AuthenticationError
      else {
        return XCTFail("Expected validation failure")
      }
      XCTAssertEqual(authError, .authenticationFailed)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
    XCTAssertFalse(mockContext.evaluatePolicyCalled)
  }

  func testAuthenticateWhenPolicyUnavailable() {
    let expectation = expectation(description: "policy unavailable")
    mockContext.canEvaluatePolicyResult = false
    mockContext.canEvaluatePolicyError = LAError(.passcodeNotSet) as NSError

    sut.authenticate(reason: "Arm protection") { result in
      guard case .failure(let error) = result,
        let authError = error as? AuthenticationService.AuthenticationError
      else {
        return XCTFail("Expected passcodeNotSet failure")
      }
      XCTAssertEqual(authError, .passcodeNotSet)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
    XCTAssertFalse(mockContext.evaluatePolicyCalled)
  }

  // MARK: - Rate limiting

  func testAuthenticateRateLimitedAfterRepeatedFailures() {
    mockContext.evaluatePolicyShouldSucceed = false
    mockContext.evaluatePolicyError = LAError(.authenticationFailed)

    for _ in 0..<3 {
      let attempt = expectation(description: "failed attempt")
      sut.authenticate(reason: "Arm protection") { _ in attempt.fulfill() }
      waitForExpectations(timeout: 2)
    }

    let rateLimited = expectation(description: "rate limited")
    mockContext.reset()
    sut.authenticate(reason: "Arm protection") { result in
      guard case .failure(let error) = result,
        let authError = error as? AuthenticationService.AuthenticationError
      else {
        return XCTFail("Expected rate limit failure")
      }
      XCTAssertEqual(authError, .biometryLockout)
      rateLimited.fulfill()
    }

    waitForExpectations(timeout: 2)
    XCTAssertFalse(mockContext.evaluatePolicyCalled)
  }

  // MARK: - Cache and invalidation

  func testAuthenticateUsesRecentAuthenticationCache() {
    let firstAuth = expectation(description: "first auth")
    mockContext.evaluatePolicyShouldSucceed = true

    sut.authenticate(reason: "Arm protection") { result in
      self.assertSuccess(result)
      firstAuth.fulfill()
    }
    waitForExpectations(timeout: 2)

    mockContext.reset()
    let cachedAuth = expectation(description: "cached auth")

    sut.authenticate(
      reason: "Arm protection",
      policy: [.allowPasswordFallback, .requireRecentAuthentication]
    ) { result in
      self.assertSuccess(result)
      cachedAuth.fulfill()
    }
    waitForExpectations(timeout: 2)

    XCTAssertFalse(mockContext.evaluatePolicyCalled)
  }

  func testInvalidateAuthenticationClearsCache() {
    let auth = expectation(description: "auth")
    mockContext.evaluatePolicyShouldSucceed = true

    sut.authenticate(reason: "Arm protection") { result in
      self.assertSuccess(result)
      auth.fulfill()
    }
    waitForExpectations(timeout: 2)

    sut.invalidateAuthentication()

    mockContext.reset()
    mockContext.evaluatePolicyShouldSucceed = true
    let freshAuth = expectation(description: "fresh auth")

    sut.authenticate(
      reason: "Arm protection",
      policy: [.allowPasswordFallback, .requireRecentAuthentication]
    ) { result in
      self.assertSuccess(result)
      freshAuth.fulfill()
    }
    waitForExpectations(timeout: 2)

    XCTAssertTrue(mockContext.evaluatePolicyCalled)
  }

  func testClearAuthenticationCacheForcesReauthentication() {
    let auth = expectation(description: "auth")
    mockContext.evaluatePolicyShouldSucceed = true

    sut.authenticate(reason: "Arm protection") { result in
      self.assertSuccess(result)
      auth.fulfill()
    }
    waitForExpectations(timeout: 2)

    sut.clearAuthenticationCache()

    mockContext.reset()
    mockContext.evaluatePolicyShouldSucceed = true
    let freshAuth = expectation(description: "fresh auth")

    sut.authenticate(
      reason: "Arm protection",
      policy: [.allowPasswordFallback, .requireRecentAuthentication]
    ) { result in
      self.assertSuccess(result)
      freshAuth.fulfill()
    }
    waitForExpectations(timeout: 2)

    XCTAssertTrue(mockContext.evaluatePolicyCalled)
  }

  private func assertSuccess(_ result: AuthenticationService.AuthenticationResult, file: StaticString = #file, line: UInt = #line) {
    guard case .success = result else {
      XCTFail("Expected success, got \(result)", file: file, line: line)
      return
    }
  }

  private func assertCancelled(_ result: AuthenticationService.AuthenticationResult, file: StaticString = #file, line: UInt = #line) {
    guard case .cancelled = result else {
      XCTFail("Expected cancelled, got \(result)", file: file, line: line)
      return
    }
  }
}
