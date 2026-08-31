//
//  ResourceProtectionPolicyAdapterTests.swift
//  MagSafe Guard
//
//  Maps ResourceProtector infrastructure errors to domain SecurityActionError.
//

@testable import MagSafeGuard
import MagSafeGuardDomain
import XCTest

final class ResourceProtectionPolicyAdapterTests: XCTestCase {

    private var sut: ResourceProtectionPolicyAdapter!

    override func setUp() {
        super.setUp()

        let rateLimiterConfig = RateLimiterConfig(
            lockScreen: (capacity: 2, refillRate: 0.1),
            playAlarm: (capacity: 2, refillRate: 0.1),
            forceLogout: (capacity: 1, refillRate: 0.1),
            shutdown: (capacity: 1, refillRate: 0.1),
            executeScript: (capacity: 2, refillRate: 0.1)
        )

        let circuitBreakerConfig = CircuitBreakerConfig(
            lockScreen: (failures: 2, successes: 1, timeout: 0.2),
            playAlarm: (failures: 2, successes: 1, timeout: 0.2),
            forceLogout: (failures: 1, successes: 1, timeout: 0.2),
            shutdown: (failures: 1, successes: 1, timeout: 0.2),
            executeScript: (failures: 2, successes: 1, timeout: 0.2)
        )

        sut = ResourceProtectionPolicyAdapter(
            config: ResourceProtectorConfig(
                rateLimiter: rateLimiterConfig,
                circuitBreaker: circuitBreakerConfig,
                enableMetrics: true,
                enableLogging: false
            )
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testValidateActionAllowsInitialRequest() async throws {
        try await sut.validateAction(.lockScreen)
    }

    func testRateLimitedMapsToDomainActionFailed() async {
        _ = try? await sut.validateAction(.forceLogout)

        do {
            try await sut.validateAction(.forceLogout)
            XCTFail("Expected rate limit to block second forceLogout")
        } catch let error as SecurityActionError {
            guard case .actionFailed(let type, let reason) = error else {
                return XCTFail("Expected actionFailed, got \(error)")
            }
            XCTAssertEqual(type, .forceLogout)
            XCTAssertTrue(reason.localizedCaseInsensitiveContains("rate limited"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCircuitOpenMapsToDomainActionFailed() async {
        await sut.recordFailure(.shutdown)

        do {
            try await sut.validateAction(.shutdown)
            XCTFail("Expected circuit breaker to block shutdown")
        } catch let error as SecurityActionError {
            guard case .actionFailed(let type, let reason) = error else {
                return XCTFail("Expected actionFailed, got \(error)")
            }
            XCTAssertEqual(type, .shutdown)
            XCTAssertTrue(reason.localizedCaseInsensitiveContains("temporarily unavailable"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRecordSuccessUpdatesMetrics() async throws {
        try await sut.validateAction(.lockScreen)
        await sut.recordSuccess(.lockScreen)

        let metrics = await sut.getMetrics(for: .lockScreen)
        XCTAssertGreaterThanOrEqual(metrics.totalAttempts, 1)
        XCTAssertGreaterThanOrEqual(metrics.successfulExecutions, 1)
    }

    func testResetClearsProtectionState() async throws {
        _ = try? await sut.validateAction(.forceLogout)

        await sut.reset(action: .forceLogout)

        try await sut.validateAction(.forceLogout)
    }
}
