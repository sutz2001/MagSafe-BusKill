# Fork changelog (sutz2001)

Independent release history for [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).  
Upstream releases (lekman v1.x, archive): [archive/UPSTREAM_CHANGELOG.md](archive/UPSTREAM_CHANGELOG.md).

## [0.4.3] — 2026-08-31

### Added

- Discreet operation: optional status alerts, security alerts, and alert sounds (menu bar icon only)

## [0.4.2] — 2026-08-31

### Added

- Remote `arm` URL example in Settings; network action event log entries
- `armAutomatically()` for auto-arm and remote arm (no interactive auth)
- Documentation policy in `AGENTS.md`; fork independence guide

### Changed

- `SecurityActionsService` uses domain `SecurityActionType` (legacy `screen_lock` decode)
- iCloud sync includes network actions and remote trigger settings
- Removed upstream-only release-please and lekman CODEOWNERS/docs clutter

## [0.4.1] — 2026-08-31

### Fixed

- P0/P1 behavior gaps: settings→runtime sync, critical alerts, login/dock, debug logging
- Grace period race on reconnect; flaky circuit-breaker/resource-protector tests

## [0.4.0] — 2026-08-31

### Added

- Network actions (webhook, VPN, SSH agent, Wi‑Fi off)
- Remote trigger via `magsafeguard://` URL scheme

## [0.3.1] — 2026-08-31

### Fixed

- Reconnect during grace period cancels actions and stays armed

## [0.3.0] — 2026-08-31

### Added

- Grace period countdown in the menu bar (seconds beside icon)
- Event log window (search, refresh, clear; Cmd+L)
- First-run onboarding wizard
- Custom script file picker in Advanced settings
- Optional restore armed state on launch (Settings → General)
- Auto-arm inactive reason hints in Settings
- Localized notifications, auth prompts, and event log strings (EN/DE)
- `task release` — automated Release build, DMG, and SHA256 checksum (`dist/`)

### Changed

- App notifications and errors use `Localizable.strings` instead of hardcoded English

## [0.2.1] — 2026-08-30

### Added

- State-specific menu bar icons (disarmed, armed, grace period, triggered)
- Agent commit policy documentation (`AGENTS.md` canonical rules)

## [0.2.0] — 2026-08-30

### Added

- Fork versioning (`version.json`, `task version:sync`)
- Custom app icon and menu bar template
- EN/DE localization with manual language picker
- Standard macOS About panel with MIT credits and `NOTICE`
- Security settings: remove actions with minus button

## [0.1.0] — 2026-08-30

### Added

- Fork from upstream with Personal Team signing (`com.sutz2001.MagSafeGuard`)
- Grace period default 30 s
- Bilingual README (EN/DE)
- CI fix: skip Security Scorecard on private repos
