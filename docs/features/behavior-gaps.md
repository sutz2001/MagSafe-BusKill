# Behavior Gaps & Fix Backlog

Companion to [Operating Modes](operating-modes.md). Tracks UI/runtime mismatches and their resolution status.

**Last resolved batch:** 2026-09-02 (0.5.4: shutdown after screen lock; 0.5.3: grace period + alarm reliability)

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
| GAP-16 | Grace countdown stuck; actions never ran after 30 s | v0.5.3 — GCD grace timer; non-blocking grace sheet (not `runModal()`); alarm volume + optional system-volume boost in Settings; `CI=true` no longer disables system actions |
| GAP-17 | Shutdown did not run after screen lock on cable trigger | v0.5.4 — schedule shutdown before lock; in-app timer (seconds, default 30 s); cancel on disarm/grace cancel; Automation permission for System Events may be required |

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
- [x] Grace countdown ticks in menu bar while alert is visible; actions run when timer expires
- [x] Shutdown schedules before lock; fires after configured delay (default 30 s)
- [x] Panic mode skips grace and runs immediate shutdown pipeline
- [x] Panic hotkey ⌃⌘P triggers response when panic-armed

---

## Open (planned)

| ID | Issue | Target |
|----|-------|--------|
| — | Paranoid mode (data destruction) | v0.6 — see [panic-modes.md](panic-modes.md) |

---

*See [operating-modes.md](operating-modes.md) for current behavior.*
