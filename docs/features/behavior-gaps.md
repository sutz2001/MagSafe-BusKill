# Behavior Gaps & Fix Backlog

Companion to [Operating Modes](operating-modes.md). Tracks UI/runtime mismatches and their resolution status.

**Last resolved batch:** 2026-08-31 (P0 + P1 fixes in 0.4.x)

---

## Resolved (P0 / P1)

| ID | Issue | Resolution |
|----|-------|------------|
| GAP-01 | Settings security actions ≠ `SecurityActionsService` | `SecurityActionsSettingsSync` + `SettingsRuntimeApplier` on every settings save |
| GAP-02 | Auto-arm not started when enabled after launch | `AutoArmManager.updateSettings()` starts/stops monitoring based on `autoArmEnabled` |
| GAP-03 | Critical alerts respected `showStatusNotifications` | `showCriticalAlert` delivers directly with `.critical` interruption level |
| GAP-04 | Advanced `customScripts` unused | Synced to `customScriptPaths`; all paths run when custom script action enabled |
| GAP-05 | `playCriticalAlertSound` unused | Plays system alert sound in `showCriticalAlert` when enabled |
| GAP-06 | `launchAtLogin` / `showInDock` UI only | `SMAppService.mainApp` + `NSApp.setActivationPolicy` via `SettingsRuntimeApplier` |
| GAP-07 | `debugLoggingEnabled` unused | Gates `Log.debug` / `debugSensitive` in Release builds |
| GAP-08 | Stale roadmap / comments | `FORK_ROADMAP.md`, `SettingsModel` comments updated |

---

## Open (P2+)

| ID | Priority | Issue |
|----|----------|-------|
| GAP-09 | P2 | `triggered` state docs said “manual reset” — fixed in operating-modes.md |
| GAP-10 | P2 | Remote `arm` URL not shown in Settings UI |
| GAP-11 | P2 | Network action failures not in event log |
| GAP-12 | P2 | iCloud sync omits network + remote settings |
| GAP-13 | P2 | Dual enums (`SecurityActionType` vs service enum) — bridged, not unified |
| GAP-14 | P2 | Auto-arm still requires interactive auth after 2 s delay |

---

## Verification checklist

- [x] Change security actions in Settings → sync updates `SecurityActionsService.actionOrder`
- [x] Enable auto-arm mid-session → `updateSettings()` starts monitoring
- [x] Disable status notifications → grace critical alert still delivered
- [x] `playCriticalAlertSound` plays audio on grace alert
- [x] Toggle launch at login → `SMAppService` register/unregister
- [x] Toggle show in dock → activation policy updates (when settings closed)
- [x] Toggle debug logging → Release `Log.debug` gated

---

*See [operating-modes.md](operating-modes.md) for current behavior.*
