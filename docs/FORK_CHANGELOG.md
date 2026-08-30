# Fork changelog (sutz2001)

Independent release history for [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).  
Upstream releases remain in [CHANGELOG.md](CHANGELOG.md).

## [0.3.0] — 2026-08-31

### Added

- Grace period countdown in the menu bar (seconds beside icon)
- Event log window (search, refresh, clear; Cmd+L)
- First-run onboarding wizard
- Custom script file picker in Advanced settings
- Optional restore armed state on launch (Settings → General)
- Auto-arm inactive reason hints in Settings
- Localized notifications, auth prompts, and event log strings (EN/DE)

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
