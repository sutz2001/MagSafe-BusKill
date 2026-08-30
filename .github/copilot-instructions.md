# GitHub Copilot — repository instructions

> **Keep in sync with:** `.cursor/rules/project-conventions.mdc`  
> When you change project conventions, defaults, or agent rules, update **both** files in the same commit.

## Project

**MagSafe Guard** — macOS menu bar security app (dead-man's switch on power disconnect).  
Fork: `sutz2001/MagSafe-BusKill` · Upstream: `lekman/magsafe-buskill`.

User docs: [README.md](../README.md) (EN) · [README.de.md](../README.de.md) (DE) — **always update both** when behavior, defaults, or build steps change.

## Taskfile first

Use `task` for builds, tests, lint, and security scans — not raw `swift test`, `xcodebuild`, or `swiftlint` when a task exists.

```bash
task setup && task build && task test
task qa:quick
open MagSafeGuard.xcodeproj   # ⌘R — menu bar app
```

## Fork-specific (do not revert)

| Setting | Value |
|---------|--------|
| Bundle ID | `com.sutz2001.MagSafeGuard` |
| Upstream team / bundle | Never restore `PW6K4BERFV` or `com.LekmanConsulting.*` |
| Entitlements | No iCloud / Push (Personal Team signing) |
| Grace period default | **30 s** (5–30 s) in `SettingsModel.gracePeriodDuration` |
| Config statics | `.defaultConfig` not `.default` |
| CI Scorecard | Skipped on private repos in `security.yml` |

## Security actions (only these five)

`lockScreen`, `soundAlarm`, `forceLogout`, `shutdown`, `customScript`

Do not implement or document volume unmount, disk wipe, or Find My unless explicitly added in code. Custom scripts only from `~/.magsafe/scripts/` or `/usr/local/magsafe-scripts/`.

## Architecture

- **MagSafeGuard/** — macOS app (UI, services, repositories)
- **MagSafeGuardLib/** — Swift package (Core, Domain, tests)
- Protocol-based DI; business logic in Domain use cases
- Minimize scope; match existing naming and patterns

## Safety

- App triggers real system actions when **armed** — never suggest running `task run` or ⌘R without user intent
- Prefer disarmed / test mode in docs and examples
- Do not commit secrets, provisioning profiles, or `.env` keys

## Version bump checklist

1. `MagSafeGuard.xcodeproj` → `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`
2. `docs/CHANGELOG.md`
3. Git tag `vX.Y.Z`
4. `README.md` + `README.de.md` if user-visible changes

## Commits & PRs

- Conventional commits; blocked in CI: `claude`, `anthropic`, `co-authored`
- PR template: security checklist for auth and permissions changes

## Sync upstream

```bash
git fetch upstream && git merge upstream/main
```

Preserve fork bundle ID, entitlements, and README fork notes when merging.
