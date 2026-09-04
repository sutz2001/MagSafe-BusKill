# Fork changelog (sutz2001)

Independent release history for [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).  
Upstream releases (lekman v1.x, archive): [archive/UPSTREAM_CHANGELOG.md](archive/UPSTREAM_CHANGELOG.md).

## [0.6.2] — 2026-09-04

### Changed

- Paranoid settings moved to dedicated **Settings → Paranoid** sidebar tab (no longer under Security)
- Paranoid codeword minimum length raised from 4 to **6** characters
- Version **0.6.2** (build 22)

## [0.6.1] — 2026-09-04

### Added

- Dedicated menu-bar asset **`MenuBarIconParanoid`** (template 1x/2x) for paranoid-armed status

### Changed

- Version **0.6.1** (build 21)
- **[Legal review gate](maintainers/legal-review-gate.md)** — informed self-review signed off (BusKill-aligned warnings); formal counsel deferred until commercial push

## [0.6.0] — 2026-09-04

### Added

- **Paranoid mode** — opt-in data destruction then hard shutdown when armed
- Setup wizard (FileVault on + wipe targets), full legal notice (EN/DE), mandatory codeword
- Menu **Arm Paranoid Mode…** (codeword + intent + Touch ID/password)
- Sequential path wipe via `/bin/rm -rf` with list priority and time budget
- Optional APFS volume erase (non-boot) and recovery-key backup delete
- Hotkey **⌃⌘⇧P** and remote `magsafeguard://paranoid?token=…` (optional dedicated token)
- Distinct menu-bar SF Symbol (`bolt.shield.fill`) while paranoid-armed
- Maintainer **[legal review gate](maintainers/legal-review-gate.md)** checklist

### Changed

- Version **0.6.0** (build 20)
- Docs: panic-modes, operating-modes, user guides, READMEs, roadmap milestone M1–M6

## [0.5.9] — 2026-09-02

### Added

- **Unmount Cryptomator** — built-in hygiene (auto-detect macFUSE / WebDAV :42427); Panic preset default
- **Disable Bluetooth** — built-in hygiene via `blueutil` (Settings warning if not installed)
- **Bundled trigger scripts** in `MagSafeGuard/Resources/TriggerScripts/` (shipped in .app): browsers, PM quit, VeraCrypt, FileVault recovery key backup, etc.
- **Install bundled scripts** — Settings → Advanced copies to `~/.magsafe/scripts/`, auto-adds paths, enables Custom Script action
- **Per-script event log** entries on trigger (`customScriptExecuted` / `customScriptFailed`)
- **Single-instance enforcement** — new launch terminates other MagSafe Guard processes; `LSMultipleInstancesProhibited`
- **LUKS vs macOS** section in [panic-modes.md](features/panic-modes.md)
- **v0.6 Paranoid milestone** — Phase 2d in [FORK_ROADMAP.md](FORK_ROADMAP.md); GitHub issues [#5–#16](https://github.com/sutz2001/MagSafe-BusKill/milestone/1)

### Changed

- Superseded scripts (clipboard, eject, Cryptomator, Bluetooth) moved to `TriggerScripts/outdated/` — not installed by the app (use built-in network actions)
- Example scripts under `docs/examples/scripts/` are pointers only (canonical copies in app bundle)

## [0.5.8] — 2026-09-02

### Added

- **Eject removable volumes** — built-in network/hygiene action (hard eject via `diskutil`); enabled by default in Panic preset; severe risk badge + orange data-loss warning in Settings
- **Example scripts (BusKill-style, macOS):** `cryptomator-umount-best-effort.sh`, `eject-removable-volumes.sh`, `veracrypt-dismount-best-effort.sh` — see [examples/scripts/](examples/scripts/)

## [0.5.7] — 2026-09-02

### Changed

- **Onboarding** split into five steps: welcome (FileVault + CLI pointer), everyday profiles, panic/paranoid page, grace, permissions — taller window, less clipping
- **User guide** EN/DE: Beginner preset, impact labels, `magsafeguard-cli` section

### Added

- **future-ideas:** Cryptomator unmount and volume eject (BusKill-style custom scripts)

## [0.5.6] — 2026-09-02

### Added

- **Beginner operation preset** — lock screen only, 30 s grace (default for new installs)
- **Impact risk labels** in Settings (safe / data loss possible / high impact) for security actions, network actions, panic menu mode, and custom scripts
- **First-arm advisory** — one-time tip after first manual arm; optional switch to Beginner preset
- **`magsafeguard-cli`** — `status`, `arm`, `disarm`, `apply-profile` (`task cli:build` + `scripts/magsafeguard-cli`)

### Changed

- Operation profile picker uses menu style (Beginner, Normal, Discreet, Panic)
- Settings schema v11 (`hasSeenFirstArmAdvisory`)

## [0.5.5] — 2026-09-02

### Added

- **Trigger pipeline** on cable/panic: phase A hygiene (clipboard → SSH → webhook → VPN, max 2 s), phase B custom scripts (user budget, default **3 s**), phase C lock → logout → immediate shutdown
- **Script time budget** setting (0–30 s) under Settings → Advanced → Custom Scripts

### Changed

- Network hygiene uses fixed priority order, not settings list order, on trigger
- Webhook requests use a timeout during hygiene phase (no indefinite block)
- Panic mode always runs immediate shutdown even when shutdown action is not toggled

### Fixed

- Custom scripts run **before** logout/shutdown (phase B), not after
- Shutdown on theft trigger: logout first, then immediate shutdown (no 30 s delay)

## [0.5.4] — 2026-09-02

### Fixed

- **System shutdown** after cable trigger: schedules shutdown **before** screen lock; uses in-app timer (default 30 s) so shutdown still fires when the session is locked
- Pending shutdown cancelled on disarm or grace cancel

## [0.5.3] — 2026-09-01

### Fixed

- **Grace period:** countdown no longer stuck; security actions run when the timer expires (non-blocking grace sheet instead of `NSAlert.runModal()`; GCD grace timer)
- **Alarm:** bundled `alarm.wav` siren; `CI=true` no longer disables real system actions in local runs
- **Menu bar icons:** colored accent tints render correctly (baked into image, not `contentTintColor`)
- **Settings window:** first open no longer disappears on click (sidebar selection fix; dock policy blocked while settings open)

### Added

- **Alarm settings** (Security tab, when Sound Alarm enabled): volume slider, optional system-volume boost, auto-stop duration (3–30 s or endless)
- **Discreet grace pulse:** subtle menu bar icon pulse in the last 10 s of grace (5 s in panic); respects Reduce Motion
- **iCloud tab** hidden when CloudKit entitlement is absent (Personal Team builds)

### Changed

- Settings schema v9 (`alarmVolume`, `boostSystemVolumeForAlarm`, `alarmDurationSeconds`)

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
