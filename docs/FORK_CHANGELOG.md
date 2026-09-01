# Fork changelog (sutz2001)

Independent release history for [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).  
Upstream releases (lekman v1.x, archive): [archive/UPSTREAM_CHANGELOG.md](archive/UPSTREAM_CHANGELOG.md).

## [0.5.2] — 2026-09-01

### Added

- **Colored menu bar icons** (optional): monochrome default (macOS style); subtle accent tints per state (armed, grace, triggered)
- Toggle in **Settings → General** and status menu (**Colored Menu Bar Icons**)

### Changed

- Settings window is recreated on each open (avoids stale UI after updates)
- User guides EN/DE note menu bar icon preference

## [0.5.1] — 2026-09-01

### Added

- **Operation profiles** (Normal / Discreet / Panic) on Settings → Security — presets with reset-to-defaults
- **Clear clipboard** network action (`NSPasteboard`); enabled in Panic preset and planned paranoid baseline
- Example custom scripts: [docs/examples/scripts/](examples/scripts/) (browser quit, browsing data, clipboard)
- About panel: clickable repo/license links; copyright via `InfoPlist.strings`

### Changed

- Settings → **Security** tab: operation mode, grace period, security + network actions consolidated
- Default **Show in Dock** off (menu bar first); dock hidden for Discreet/Panic presets and while panic/paranoid armed
- Panic preset network actions: VPN + SSH + clipboard (no Wi‑Fi off — Find My)
- User guides, README EN/DE, and technical docs updated (operation profiles vs panic protection mode)

## [0.5.0] — 2026-08-31

### Added

- **Panic mode:** zero grace, protection-first security actions, immediate shutdown on cable pull
- Menu item **Arm Panic Mode…** with legal notice (EN + DE)
- Global panic hotkey **⌃⌘P** (Control+Command+P) while app is running
- Remote trigger `magsafeguard://panic?token=…` when panic-armed
- Protection-first theft trigger path (GAP-15): lock first, bypass rate limit / circuit breaker on cable trigger

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
