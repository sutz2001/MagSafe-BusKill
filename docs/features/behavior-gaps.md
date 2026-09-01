# Behavior Gaps & Fix Backlog

Companion to [Operating Modes](operating-modes.md). Tracks UI/runtime mismatches and their resolution status.

**Last resolved batch:** 2026-09-01 (0.5.2: colored menu bar icons; 0.5.1: operation profiles, clipboard network action)

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

## Resolved (P2)

| ID | Issue | Resolution |
|----|-------|------------|
| GAP-09 | `triggered` state docs said “manual reset” | Clarified in `operating-modes.md` — returns to **armed** automatically |
| GAP-10 | Remote `arm` URL not shown in Settings UI | `magsafeguard://arm?token=…` example in Security → Remote Trigger |
| GAP-11 | Network action failures not in event log | `networkActionExecuted` / `networkActionFailed` events with localized details |
| GAP-12 | iCloud sync omits network + remote settings | `SyncServiceSettings` syncs `enabledNetworkActions`, `webhookURL`, `remoteTrigger` |
| GAP-13 | Dual enums (`SecurityActionType` vs service enum) | `SecurityActionsService` uses domain `SecurityActionType`; legacy `screen_lock` decode |
| GAP-14 | Auto-arm required interactive auth | `armAutomatically()` for auto-arm and remote `arm` URL (opt-in flows) |
| GAP-15 | Theft trigger used user action order; lock not prioritized; rate limit / circuit breaker could block lock | v0.5 — `SecurityActionExecutionContext.theftTrigger` / `.panic` protection-first path; rate limit and breaker only for `.standard` |

---

## Verification checklist

- [x] Change security actions in Settings → sync updates `SecurityActionsService.actionOrder`
- [x] Enable auto-arm mid-session → `updateSettings()` starts monitoring
- [x] Disable status notifications → grace critical alert still delivered
- [x] `playCriticalAlertSound` plays audio on grace alert
- [x] Toggle launch at login → `SMAppService` register/unregister
- [x] Toggle show in dock → activation policy updates (when settings closed)
- [x] Toggle debug logging → `Log.debug` gated
- [x] Remote trigger settings show trigger + arm URL examples
- [x] Network action success/failure appears in event log
- [x] iCloud sync includes network actions and remote trigger settings
- [x] Auto-arm arms without Touch ID prompt after notification delay
- [x] Cable disconnect in normal armed mode uses protection-first path (lock first, no rate limit)
- [x] Panic mode skips grace and runs immediate shutdown pipeline
- [x] Panic hotkey ⌃⌘P triggers response when panic-armed

---

## Open (planned)

| ID | Issue | Target |
|----|-------|--------|
| — | Paranoid mode (data destruction) | v0.6 — see [panic-modes.md](panic-modes.md) |

---

*See [operating-modes.md](operating-modes.md) for current behavior.*
