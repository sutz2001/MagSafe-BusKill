# Testing Guide

This guide explains the testing strategy for MagSafe Guard, focusing on achieving high code coverage through proper separation of business logic from system interfaces.

## Testing Philosophy

### Core Principles

1. **Separation of Concerns**: Extract business logic from UI and system interfaces
2. **Protocol-Based Testing**: Use protocols to abstract system dependencies
3. **Mock Everything External**: Mock all external dependencies for unit tests
4. **Manual Acceptance Testing**: Cover system integration through manual tests

### Testing Layers

```text
┌─────────────────────────────────┐
│   Manual Acceptance Tests       │ ← Real system integration
├─────────────────────────────────┤
│   Unit Tests with Mocks         │ ← Business logic (100% coverage target)
├─────────────────────────────────┤
│   Protocol Abstractions         │ ← Interfaces for system dependencies
├─────────────────────────────────┤
│   Business Logic               │ ← Pure, testable code
├─────────────────────────────────┤
│   System Integration Code      │ ← Thin layer, minimal logic
└─────────────────────────────────┘
```

## Architecture Patterns

### Protocol-Based Dependency Injection

#### Example: Security Actions

```swift
// Protocol defining system actions
protocol SystemActionsProtocol {
    func lockScreen() throws
    func playAlarm(volume: Float) throws
    func stopAlarm()
    // ... other system actions
}

// Real implementation
class MacSystemActions: SystemActionsProtocol {
    func lockScreen() throws {
        // Actual system calls
    }
}

// Mock for testing
class MockSystemActions: SystemActionsProtocol {
    var lockScreenCalled = false
    func lockScreen() throws {
        lockScreenCalled = true
    }
}

// Service using the protocol
class SecurityActionsService {
    private let systemActions: SystemActionsProtocol
    
    init(systemActions: SystemActionsProtocol = MacSystemActions()) {
        self.systemActions = systemActions
    }
}
```

#### Example: Authentication Context

```swift
// Protocol for authentication
protocol AuthenticationContextProtocol {
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws
    var biometryType: LABiometryType { get }
}

// Factory pattern for creating contexts
protocol AuthenticationContextFactoryProtocol {
    func createContext() -> AuthenticationContextProtocol
}
```

### Extracting Testable Logic

#### Before (Untestable)

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Crashes in tests
        statusItem = NSStatusBar.system.statusItem(...) // Requires NSApp
        // Business logic mixed with UI
    }
}
```

#### After (Testable)

```swift
// Extract business logic
class AppDelegateCore {
    func createMenu() -> NSMenu { ... }
    func handlePowerStateChange(_ info: PowerInfo) -> Bool { ... }
}

// Thin UI layer
class AppDelegate: NSObject, NSApplicationDelegate {
    let core = AppDelegateCore()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem.menu = core.createMenu()
    }
}
```

## Testing Strategies by Component

### Authentication Service

**Strategy**: Use mock LAContext to test all authentication flows

```swift
// Test setup
let mockContext = MockAuthenticationContext()
let mockFactory = MockAuthenticationContextFactory(mockContext: mockContext)
let service = AuthenticationService(contextFactory: mockFactory)

// Test success path
mockContext.evaluatePolicyShouldSucceed = true
service.authenticate(reason: "Test") { result in
    XCTAssertEqual(result, .success)
}

// Test failure path
mockContext.evaluatePolicyError = LAError(.authenticationFailed)
service.authenticate(reason: "Test") { result in
    XCTAssertEqual(result, .failure(.authenticationFailed))
}
```

### Security Actions Service

**Strategy**: Mock system calls to test action coordination

```swift
// Test setup
let mockSystemActions = MockSystemActions()
let service = SecurityActionsService(systemActions: mockSystemActions)

// Test action execution
service.executeActions { result in
    XCTAssertTrue(mockSystemActions.lockScreenCalled)
    XCTAssertTrue(result.allSucceeded)
}
```

### Power Monitoring

**Strategy**: Extract power state logic from IOKit dependencies

```swift
// Testable core logic
class PowerMonitorCore {
    func processPowerSourceInfo(_ info: [String: Any]) -> PowerInfo { ... }
    func hasPowerStateChanged(newInfo: PowerInfo) -> Bool { ... }
}

// IOKit integration (excluded from coverage)
class PowerMonitorService {
    private let core = PowerMonitorCore()
    // Thin wrapper around IOKit
}
```

## Test Architecture

MagSafe Guard uses **two test layers**. Both are required for confidence; only the SPM layer counts toward Codecov/Sonar metrics.

| Layer | Location | Runner | What it covers |
|-------|----------|--------|----------------|
| **SPM (domain/core)** | `MagSafeGuardLib/Tests/` | `task test` | UseCases, domain models, `SettingsModel`, logging, feature flags |
| **Xcode (app)** | `MagSafeGuardTests/` | `task xcode:test` | `AppController`, security infra, repositories, app services |
| **UI (placeholder)** | `MagSafeGuardUITests/` | `task xcode:test:full` | Launch smoke only — real UI flows are manual |
| **Manual acceptance** | `docs/maintainers/acceptance-tests.md` | Human | Screen lock, real cable, biometrics |

**Support code (not a test target):** `MagSafeGuardLib/Tests/TestInfrastructure/` — mocks, builders, shared assertions.

**Metrics:** SonarCloud and Codecov analyze `MagSafeGuardLib/Sources` only. App-layer tests (`MagSafeGuard/`) improve quality but do not change the 80% coverage gate.

## Test Inventory

### SPM — `MagSafeGuardDomainTests`

| File | Covers |
|------|--------|
| `UseCases/AuthenticationUseCaseImplTests.swift` | Auth flows, rate limiting, cache, history |
| `UseCases/AutoArmUseCaseImplTests.swift` | Auto-arm rules, location/network triggers |
| `UseCases/PowerMonitorUseCaseImplTests.swift` | Power state changes, analyzer integration |
| `UseCases/SecurityActionUseCaseImplTests.swift` | Action execution, config persistence |
| `UseCases/SecurityActionUseCaseTests.swift` | Sequential/parallel execution, validation |
| `UseCases/ProtectedActionUseCaseTests.swift` | Protected actions via policy + repository mocks |
| `DomainProtocolTests.swift` | Domain models, enums, execution strategies |
| `Protocols/ResourceProtectionProtocolsTests.swift` | Protection config structs and metrics |

### SPM — `MagSafeGuardCoreTests`

| File | Covers |
|------|--------|
| `Models/SettingsModelTests.swift` | Defaults, grace period, encoding, validation |
| `Utilities/LoggerTests.swift` | Log levels, categories, concurrency |
| `Utilities/FeatureFlagsTests.swift` | Defaults and environment overrides |
| `Utilities/SentryLoggerTests.swift` | Sentry setup and privacy scrubbing |

### Xcode — `MagSafeGuardTests`

| File | Covers |
|------|--------|
| `Controllers/AppControllerTests.swift` | Arm/disarm, power disconnect → grace → trigger, zero-grace immediate trigger, reconnect cancels grace, auth cancel, menu titles |
| `Repositories/MacSystemActionsRepositoryTests.swift` | Repository + rate limiter + circuit breaker |
| `Services/MacSystemActionsTests.swift` | Script validation, path sanitization |
| `Services/ApplicationStatePersistenceTests.swift` | Armed-state save/load/clear |
| `Security/CircuitBreakerTests.swift` | Circuit breaker state machine |
| `Security/RateLimiterTests.swift` | Token bucket, refill, reset |
| `Security/ResourceProtectorTests.swift` | Combined rate limit + circuit breaker |

### Xcode — `MagSafeGuardUITests`

| File | Covers |
|------|--------|
| `MagSafeGuardUITests.swift` | Template example, launch performance |
| `MagSafeGuardUITestsLaunchTests.swift` | Launch screenshot |

## Recommended Additional Tests

Domain/core logic is well covered. Highest value is in the **app layer**, especially the power-disconnect → grace → trigger path.

| Priority | Area | Status | Tests |
|----------|------|--------|-------|
| ~~**P0**~~ | Power disconnect while armed | Done | `testPowerDisconnectStartsGracePeriod`, `testGracePeriodExpiryExecutesSecurityActions` |
| ~~**P0**~~ | Grace period = 0 | Done | `testZeroGracePeriodExecutesSecurityActionsImmediately` |
| ~~**P0**~~ | Reconnect during grace | Done | `testPowerReconnectDuringGracePeriodCancelsTrigger` |
| ~~**P1**~~ | `PowerMonitorCore` | Done | `PowerMonitorCoreTests.swift` |
| ~~**P1**~~ | `SecurityActionsService` | Done | `SecurityActionsServiceTests.swift` |
| **P2** | `ResourceProtectionPolicyAdapter` | Open | Map protector errors to domain errors |
| ~~**P2**~~ | `AutoArmManager` | Done | `AutoArmManagerTests.swift` |
| **P3** | `AuthenticationService` | Open | App-layer LA wrapper success/failure paths |

**Not worth automating (by design):** raw IOKit, CoreLocation hardware, CloudKit sync, real screen lock/shutdown — see [acceptance-tests.md](acceptance-tests.md).

**Known gap:** One flaky concurrent test is disabled in `SecurityActionUseCaseTests.swift` — re-enable when stabilized.

## Test Organization

### Unit tests (automated)

- **SPM:** `MagSafeGuardLib/Tests/` — run with `task test`
- **Xcode app:** `MagSafeGuardTests/` — run with `task xcode:test`
- **Mocks:** `MagSafeGuardLib/Tests/TestInfrastructure/` and inline mocks in app tests

### Manual acceptance tests

Location: [acceptance-tests.md](acceptance-tests.md)

Cover real system integration that cannot be automated safely:

- Actual biometric authentication
- Real screen locking and alarm
- Hardware power disconnection
- Release smoke on a clean Mac

## Running Tests

### Quick reference

| Goal | Command |
|------|---------|
| Daily dev (fast) | `task test` |
| App-layer unit tests | `task xcode:test` |
| Include UI smoke tests | `task xcode:test:full` |
| Full local QA | `task qa` or `task qa:quick` |
| Before release | `task release` (runs tests internally) |

### SPM — domain and core (`task test`)

```bash
task test                    # all SPM tests + LCOV coverage report
task test:specific           # subset via TEST_FILES env var
```

`task test` writes `coverage.lcov`, `coverage.xml`, and `coverage-report.md` in the repo root.

**Run a single SPM test class or method:**

```bash
cd MagSafeGuardLib
swift test --filter SettingsModelTests
swift test --filter 'SettingsModelTests/testDefaultGracePeriod'
```

**Specific files via Taskfile:**

```bash
TEST_FILES='SettingsModelTests,LoggerTests' task test:specific
```

### Xcode — app layer

**Test plans** live in `MagSafeGuard.xcodeproj/xcshareddata/xctestplans/`:

| Plan | Contents | Default |
|------|----------|---------|
| `MagSafeGuardUnit` | `MagSafeGuardTests` only | Yes (⌘U) |
| `MagSafeGuardFull` | Unit + `MagSafeGuardUITests` | Manual |

```bash
task xcode:test                              # MagSafeGuardUnit plan
task xcode:test:full                         # MagSafeGuardFull plan
task xcode:test:verbose                      # verbose unit plan output
TEST_FILTER='AppControllerTests' task xcode:test:specific
TEST_FILTER='AppControllerTests/testInitialState' task xcode:test:specific
```

**In Xcode:**

1. `open MagSafeGuard.xcodeproj`
2. Scheme **MagSafeGuard** → **Product → Test** (⌘U) — uses `MagSafeGuardUnit` by default
3. Switch plan: **Product → Test Plan → MagSafeGuardFull**
4. Single test: Test navigator (◇) → play button on class or method

### Combined workflow (recommended before push)

```bash
task test && task xcode:test
```

Or use the project QA tasks:

```bash
task qa:quick    # lint + SPM tests + Xcode build/test (slim)
task qa          # full local QA suite
```

### Environment variables

| Variable | Effect |
|----------|--------|
| `CI=true` | CI-oriented behavior in some tests (set automatically in old CI; optional locally) |
| `MAGSAFE_GUARD_TEST_MODE=1` | Set in `MagSafeGuardUnit` test plan for app tests |
| `COVERAGE_THRESHOLD=80` | Minimum coverage check in `task test` (default 80) |
| `SKIP_TESTS=true` | Skip tests in `task release` |
| `TEST_FILES` | Comma-separated SPM test filters for `task test:specific` |
| `TEST_FILTER` | Xcode test class/method for `task xcode:test:specific` |

Examples:

```bash
COVERAGE_THRESHOLD=85 task test
SKIP_TESTS=true task release
```

### Coverage reports

Coverage is generated automatically by `task test` (no separate `task test:coverage` command).

After `task test`, open:

- `coverage-report.md` — summary table
- `coverage.lcov` — for IDEs and Codecov
- `coverage.xml` — SonarCloud format

SonarCloud upload (when token is set): `task sonar:scan` (uses existing `coverage.xml` or runs tests first).

### Manual `swift test` (without Taskfile)

```bash
cd MagSafeGuardLib
swift test --enable-code-coverage --parallel
```

## Writing Effective Tests

### Test Structure

```swift
func testFeatureBehavior() {
    // Arrange: Set up test conditions
    mockService.configureExpectedBehavior()
    
    // Act: Execute the feature
    let result = service.performAction()
    
    // Assert: Verify the outcome
    XCTAssertTrue(result.succeeded)
    XCTAssertTrue(mockService.expectedMethodCalled)
}
```

### Async Testing

```swift
func testAsyncOperation() {
    let expectation = self.expectation(description: "Async operation completes")
    
    service.performAsyncOperation { result in
        XCTAssertNotNil(result)
        expectation.fulfill()
    }
    
    waitForExpectations(timeout: 2)
}
```

### Testing Error Paths

```swift
func testErrorHandling() {
    // Configure mock to fail
    mockService.shouldFail = true
    mockService.errorToThrow = CustomError.networkFailure
    
    // Verify error is handled correctly
    service.performOperation { result in
        switch result {
        case .failure(let error):
            XCTAssertEqual(error as? CustomError, .networkFailure)
        case .success:
            XCTFail("Should have failed")
        }
    }
}
```

## Coverage Exclusions

### Files to Exclude

1. **UI-Dependent Code**
   - `MagSafeGuardApp.swift` - NSApp dependencies
   - `*View.swift` - SwiftUI views (test view models instead)

2. **System Integration Code**
   - `*LAContext.swift` - Direct LAContext usage
   - `Mac*Actions.swift` - Real system implementations
   - `PowerMonitorService.swift` - IOKit integration

3. **Test Infrastructure**
   - `*Tests.swift` - Test files
   - `Mock*.swift` - Mock implementations
   - `runner.swift` - Test runner

### Exclusion Configuration

Configure in multiple places:

1. **Taskfile.yml**:

```yaml
test:coverage:
  cmds:
    - swift test --enable-code-coverage
    - |
      xcrun llvm-cov report ... \
        -ignore-filename-regex=".*Tests\.swift|.*Mocks?\.swift|.*/MagSafeGuardApp\.swift"
```

1. **sonar-project.properties**:

```properties
sonar.coverage.exclusions=\
  **/MagSafeGuardApp.swift,\
  **/PowerMonitorService.swift,\
  **/PowerMonitorCore.swift,\
  **/*LAContext.swift,\
  **/Mac*Actions.swift,\
  **/*Tests.swift,\
  **/Mock*.swift
```

1. **.codecov.yml**:

```yaml
coverage:
  ignore:
    - "Tests/"
    - "**/Mock*.swift"
    - "**/MagSafeGuardApp.swift"
```

## CI/CD Integration

GitHub Actions runs **lightweight Ubuntu checks** on push/PR (`commit-message-check`, `enforce-clean-history`). **macOS test workflows are manual-only** to save Actions minutes — run `task test` and `task xcode:test` locally before pushing.

When macOS CI is triggered manually (Actions → **Tests** workflow):

```bash
task test    # SPM tests + coverage (used by former CI test job)
```

Codecov/SonarCloud track `MagSafeGuardLib` coverage from `coverage.xml` produced by `task test`.

## Best Practices

### DO

- ✅ Extract business logic into testable classes
- ✅ Use dependency injection with protocols
- ✅ Test all success and failure paths
- ✅ Mock external dependencies
- ✅ Write tests before fixing bugs
- ✅ Keep tests fast and isolated
- ✅ Use proper mocks for automated testing

### DON'T

- ❌ Test implementation details
- ❌ Mock types you own (use real objects)
- ❌ Write tests that depend on timing
- ❌ Test UI layout in unit tests
- ❌ Execute real system actions in tests
- ❌ Hardcode paths in tests

## Troubleshooting

### Common Issues

1. **"Authentication dialog appears during tests"**
   - Ensure you're using mock authentication context
   - Ensure mock authentication context is used
   - Verify mock factory is properly injected

2. **"Tests timeout in CI"**
   - Add explicit timeouts to async tests
   - Mock time-dependent operations
   - Use explicit timeouts in async tests

3. **"Coverage is lower than expected"**
   - Check exclusion patterns in `Taskfile.yml` and `.codecov.yml`
   - Remember: only `MagSafeGuardLib` counts toward Codecov/Sonar
   - Open `coverage-report.md` after `task test`

4. **"Screen locks during test run"**
   - Ensure SecurityActionsService uses mock
   - Check AppDelegateCore initialization
   - Verify test uses dependency injection

### Debugging Tips

```swift
// Add verbose logging in tests
XCTContext.runActivity(named: "Testing authentication") { _ in
    print("Mock state: \(mockContext)")
    // Test code here
}

// Use afterEach to verify mock state
override func tearDown() {
    XCTAssertFalse(mockService.hasUnexpectedCalls)
    super.tearDown()
}

// Tests now work the same locally and in CI
// No special environment checks needed
```

## Future Improvements

1. **`PowerMonitorCore` unit tests** — pure parsing logic, no IOKit
2. **Re-enable flaky concurrent test** in `SecurityActionUseCaseTests.swift`
3. **Test data builders** — expand `TestInfrastructure` for complex app scenarios
4. **Property-based testing** — optional SwiftCheck for state machines
5. **Manual acceptance checklist** — keep in sync with each release
