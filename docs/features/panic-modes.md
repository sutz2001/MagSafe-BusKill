# Panic & Paranoid Modes (planned)

Design document for **v0.5.0** (Panic) and **v0.6.0** (Paranoid).  
Companion: [operating-modes.md](operating-modes.md) · [FORK_ROADMAP.md](../FORK_ROADMAP.md)

**Status:** planning only — not implemented in code.

---

## Summary

Two separate high-assurance modes, both triggered with **0 s grace** and **no cancel** on cable disconnect:

| Mode | Goal | Data destruction |
|------|------|------------------|
| **Panic** | Make the Mac unusable immediately (lock, logout, hard shutdown) | **No** |
| **Paranoid** | Panic baseline + fastest possible data destruction, then shutdown | **Yes** (best-effort) |

**Assumption for Paranoid:** User already hardened the Mac (FileVault on, wipe paths/volumes configured). Paranoid is a **setup mode**, not plug-and-play.

---

## Panic mode (v0.5.0)

### Intent

Protect a running session when the cable is pulled — **without** deleting files. Suitable for everyday use (café, travel).

### On cable disconnect (0 s grace)

Execute **in parallel** (fire-and-forget, circuit breaker **off**):

1. Lock screen
2. Force logout (all users)
3. Network actions (if enabled): webhook `panic`, VPN off, SSH agent clear, Wi‑Fi off
4. **Immediate hard shutdown** — no dialog, no 1-minute delay, no auth cancel

Shutdown is the terminal action; do not rely on “quit all apps” alone (macOS may still delay).

### Triggers

- Power cable disconnect (when panic-armed)
- Global hotkey (configurable)
- Remote: `magsafeguard://panic?token=…`

### Arming

| Step | Requirement |
|------|-------------|
| Enable | Settings toggle + **one strong confirmation** |
| Legal | **Short impact notice** (EN + DE) — see [Legal notices](#legal-notices) |
| Icon | Distinct menu bar icon when panic-armed |
| Codeword | **Not required** |

### What Panic does *not* do

- No file deletion, keychain wipe, or volume erase
- No grace period, no reconnect cancel, no Touch ID abort

---

## Paranoid mode (v0.6.0)

### Intent

Maximum speed data destruction for users who accept irreversible loss. Targets opportunistic access after theft — **not** a guarantee against dedicated forensic labs.

### Prerequisites (setup wizard)

User must confirm before paranoid can be armed:

- [ ] **FileVault enabled** (verified via `fdesetup status`)
- [ ] At least one **wipe target** configured: folder paths and/or dedicated APFS volume
- [ ] Optional: local FileVault recovery key backup path (if present, delete on trigger)
- [ ] Full paranoid onboarding (EN + DE) with explicit consent

### On cable disconnect (0 s grace)

**Phase 0 — same as Panic (parallel):** lock, logout, network panic actions.

**Phase 1 — destruction pipeline (parallel, do not await):**

| Action | Priority | Notes |
|--------|----------|-------|
| Clipboard clear | immediate | |
| SSH agent clear | immediate | |
| Browser / app session kill | immediate | best-effort |
| Keychain items (configured) | fast | user-selected or preset list |
| `rm -rf` on configured paths | parallel | user-defined only |
| APFS volume erase | parallel | dedicated volume ID only |
| Delete local recovery key backup | if configured | only if path known |
| Custom wipe script | parallel | from allowed paths only |

**Phase 2 — terminal (immediate, do not wait for Phase 1):**

- Hard shutdown / halt (same path as Panic)

**Design rule:** Speed beats completeness — power off quickly; destruction runs until power is gone.

### Triggers

- Power cable disconnect (when paranoid-armed)
- Global hotkey (separate from panic hotkey)
- Remote: `magsafeguard://paranoid?token=…` (separate token scope recommended)

### Arming

| Step | Requirement |
|------|-------------|
| Enable | Paranoid setup wizard completed |
| Confirm | **Double confirmation** |
| Codeword | **Mandatory** codeword to arm |
| Legal | **Full disclaimer** (EN + DE) — see [Legal notices](#legal-notices) |
| Work device | Explicit **employer / work laptop** warning |
| Icon | Distinct menu bar icon (different from panic) |
| Test | **No** destructive test run in production builds (mocks only) |

### Honest limits (must appear in UI)

- APFS does not guarantee secure overwrite; TRIM and snapshots may retain data
- Without FileVault, powered-off disk may still be readable
- Wipe speed depends on path size; shutdown may occur before wipe completes
- Shared / employer machines: user is solely responsible

---

## Legal notices

> Not legal advice. Consult a lawyer before public release in DE/EU.

### Panic — lightweight notice (required)

Panic does **not** delete files, but a **short consent** is still required:

- Immediate shutdown and logout
- **Unsaved work may be lost**
- No grace period; false triggers cannot be cancelled after cable pull
- Caution on **work / employer devices** (disruption, policy violation)
- User acts at own risk

**UI:** One screen at first panic enable + checkbox “I understand” (EN + DE). No codeword.

### Paranoid — full notice (required)

Everything in Panic, plus:

- **Irreversible data destruction** on configured paths/volumes
- FileVault recovery key backup may be deleted
- Explicit work-device prohibition warning
- Double confirmation + mandatory codeword
- Dedicated onboarding chapter (opt-in only)

---

## App states

```
disarmed → armed (normal, grace 5–30 s)
         → panicArmed (0 s, shutdown path)
         → paranoidArmed (0 s, destruction + shutdown)
```

Only one high-assurance mode armed at a time. Normal **armed** and **panic/paranoid armed** are mutually exclusive.

---

## Architecture (planned)

```
PanicModeExecutor
  - executeImmediateShutdown()   // new: no 1-min AppleScript dialog
  - parallel: lock, logout, network, shutdown

ParanoidModeExecutor : PanicModeExecutor
  - DestructionPipeline (protocol)
  - MockDestructionPipeline (CI / unit tests only)

AppController
  - route disconnect to normal | panic | paranoid path
  - skip grace, skip circuit breaker, skip auth cancel
```

### New types (sketch)

- `ProtectionMode`: `.normal` | `.panic` | `.paranoid`
- `ParanoidConfiguration`: wipe paths, volume UUID, recovery key path, keychain targets
- `DestructionPipeline` protocol with `MockDestructionPipeline`

### Shutdown implementation note

Current `scheduleShutdown` uses a **minimum 1-minute** AppleScript path — **not** suitable for Panic/Paranoid.  
New `executeImmediateShutdown()` required (e.g. `shutdown -h now` or non-interactive System Events), with test-mode guard.

---

## Remote URLs

| URL | Mode |
|-----|------|
| `magsafeguard://trigger?token=…` | Normal armed (existing; uses grace + configured actions) |
| `magsafeguard://panic?token=…` | Panic path |
| `magsafeguard://paranoid?token=…` | Paranoid path |

Do not conflate `trigger` with panic or paranoid.

---

## Test strategy

| Area | Approach |
|------|----------|
| State routing, 0 grace, no cancel | Unit tests |
| Panic executor | `MockSystemActions` + `MockPanicExecutor` |
| Paranoid pipeline | `MockDestructionPipeline` — **never** real delete in CI |
| E2E destructive wipe | **Forbidden** in CI and release builds |

---

## Release checklist

### v0.5.0 — Panic

- [x] `PanicModeExecutor` + immediate shutdown path
- [x] Panic arming UI + lightweight legal notice (EN + DE)
- [x] Distinct menu bar icon
- [ ] Hotkey + `magsafeguard://panic` (URL shipped; global hotkey pending)
- [x] `operating-modes.md` updated when shipped
- [x] Unit tests with mocks

### v0.6.0 — Paranoid

- [ ] Setup wizard (FileVault check, wipe targets)
- [ ] `ParanoidModeExecutor` + `DestructionPipeline`
- [ ] Double confirm + codeword + full legal UI
- [ ] `magsafeguard://paranoid`
- [ ] Legal review DE/EU before public beta
- [ ] README EN + DE updated

---

## Response speed — normal armed mode (v0.5)

Panic/Paranoid are not the only modes that must be fast. After grace expires (or at grace = 0), **lock and logout are protection** — they should not wait behind rate limits, circuit breakers, or slow actions like shutdown/scripts.

### Current behavior (gap)

| Factor | Today | Problem on theft trigger |
|--------|-------|---------------------------|
| Execution order | User drag order in Settings | If shutdown/script is first, **lock waits** |
| `executeInParallel` | Default **false** | Actions run one-by-one |
| Rate limit | 5 s minimum between runs | Can block a legitimate re-trigger |
| Circuit breaker | 3 failures → 60 s open | Can block **all** actions including lock |
| `actionDelay` | Configurable | Adds delay before any action |
| Network actions | Before security actions complete | Webhook/VPN may delay lock |

Doc comment claims “screen lock first” — **not implemented**; order follows Settings only.

### Planned: protection-first trigger path (v0.5, with Panic)

On **cable disconnect** and **remote `trigger`** (not manual test buttons):

1. **Tier 1 — immediate (under 500 ms target):** `lockScreen` always first, even if not first in user order
2. **Tier 2 — parallel:** `forceLogout`, `soundAlarm`, network actions (webhook, VPN, SSH, Wi‑Fi)
3. **Tier 3 — after protection:** `shutdown` (respect configured delay only here), `customScript` last

**Policy changes on trigger path:**

| Control | Normal test / settings preview | Theft trigger |
|---------|-------------------------------|---------------|
| Rate limiter | keep | **bypass** (or per-trigger burst) |
| Circuit breaker | keep | **never block** lock/logout |
| Parallel execution | user setting | **force parallel** for Tier 2 |
| `actionDelay` | user setting | **ignore** (0) |

Grace period remains user-configurable (5–30 s). Users who want instant normal protection set **grace = 0** — then Tier 1 runs on cable pull with no countdown.

Panic/Paranoid still differ: **0 grace**, no cancel, hard shutdown / destruction pipeline.

### Acceptance targets (planning)

| Event | Target |
|-------|--------|
| Grace = 0, lock only enabled | Lock within **500 ms** of disconnect |
| Grace = 30, then trigger | Lock within **500 ms** of timer fire |
| Panic cable pull | Lock + shutdown start within **1 s** |

Track as **GAP-15** in [behavior-gaps.md](behavior-gaps.md).

---
