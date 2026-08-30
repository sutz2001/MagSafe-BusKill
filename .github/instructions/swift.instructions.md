---
applyTo: "**/*.swift"
---

# Swift / macOS conventions

- Swift 6, macOS 13+ target; follow existing Clean Architecture layers in `MagSafeGuardLib`
- Use `.defaultConfig` for `ResourceProtectorConfig`, `RateLimiterConfig`, `CircuitBreakerConfig` (not `.default`)
- Security action types: `SecurityActionType` enum only — no ad-hoc shutdown/lock without repository layer
- Tests: Swift Testing in `MagSafeGuardLib/Tests`; mocks in `TestInfrastructure`
- Run `task test` after logic changes; `task swift:lint` for style
- Do not add iCloud entitlements without noting paid Developer Program requirement
