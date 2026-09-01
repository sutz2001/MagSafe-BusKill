# Stabilization checklist (v0.5.x → daily driver)

**Goal:** Bring MagSafe Guard to a **reliable daily-driver** state on your Mac — without new features (no Paranoid, no LAN web trigger, no companion app).

**Current version:** 0.5.2 (build 11)  
**Companion docs:** [acceptance-tests.md](acceptance-tests.md) · [testing-guide.md](testing-guide.md) · [behavior-gaps.md](../features/behavior-gaps.md)

---

## Out of scope (parked)

| Item | Where tracked |
|------|----------------|
| Paranoid mode (data destruction) | [panic-modes.md](../features/panic-modes.md) · v0.6 |
| LAN / phone web trigger | [future-ideas.md](../features/future-ideas.md) |
| Notarized DMG for others | [FORK_ROADMAP.md](../FORK_ROADMAP.md) · ~v1.0 + Paid Dev |
| Mac App Store | Excluded |

---

## Exit criteria (“good stand”)

Treat stabilization as done when **all** of these are true:

1. **`task test` and `task xcode:test` pass** on a clean machine (or documented env exceptions).
2. **Manual smoke** (§2 below) completed once on your Mac — normal + discreet paths; panic only in a controlled test.
3. **`task release` produces a DMG** you can install to `/Applications` and run for several days.
4. **No P0/P1 bugs** you hit in real use; anything else logged in Issues or behavior-gaps.
5. **Docs match behavior** for features you actually use (user guide, acceptance tests).

Optional stretch: first **GitHub Release** with `.dmg` + `LICENSE` + `NOTICE`.

---

## 1. Automated quality (CI / local)

### P0 — must fix

- [x] **`PowerMonitorUseCaseImplTests` Sendable / data-race errors** — fixed via `AsyncStreamCollector` in TestInfrastructure.
- [x] **`task test` exits 0** with `CI=true SKIP_UI_TESTS=true`.
- [x] **`task xcode:test` exits 0** — app-layer tests (`MagSafeGuardTests/`), including panic/hotkey tests.

### P1 — should fix

- [x] **`task qa:quick` clean** — passes locally (2026-09-01): SwiftLint, YAML (Ruby), Markdown, secrets scan.
- [x] Re-enable or replace **disabled flaky test** in `SecurityActionUseCaseTests.swift` — fixed via `actionDelay` hold window.
- [x] **GitHub Actions on `main`** — **Commit Message Check** green on latest push (`ea242bc`, 0.5.2). **Tests** / **Security Scanning** workflows are **manual only** (`workflow_dispatch`); run locally or trigger in Actions when needed.

### P2 — nice to have

- [x] `ResourceProtectionPolicyAdapter` tests (testing-guide P2).
- [x] `AuthenticationService` app-layer tests (testing-guide P3).
- [x] Coverage stays ≥ 80% (`COVERAGE_THRESHOLD`) — **96.7%** line coverage locally (2026-09-01, `task test`).

### §1a — `task qa:quick` status (2026-09-01)

| Step | Result | Notes |
|------|--------|--------|
| `task test` | ✅ | 268 tests passed |
| Coverage | ✅ | ~96.7% lines (`coverage.lcov`) |
| `swift:lint` | ✅ | 0 violations (file header aligned; `missing_docs` not in quick QA) |
| `yaml:validate` | ✅ | Ruby `YAML.load_file` fallback when npm tools absent |
| `markdown:lint` | ✅ | Ignores `dist/`, `DerivedData`, archive; `MD060` off; doc fixes for `MD036`/`MD040` |
| `security:secrets` | ✅ | Bearer pattern tightened; webhook uses string concat |

**Commands:**

```bash
task setup && task test
task xcode:test
task qa:quick
```

---

## 2. Manual smoke (your Mac)

Use a **test session** or spare user if testing logout/shutdown. Save work first.

### Normal armed mode

- [ ] Arm / disarm via menu + Touch ID.
- [ ] Unplug adapter → grace countdown (or immediate actions if grace = 0).
- [ ] Reconnect during grace → grace cancelled, stays armed.
- [ ] Cancel grace (if enabled) → auth required.
- [ ] Security actions run in expected order (lock at minimum).
- [ ] Event log shows power disconnect + grace / actions.
- [ ] Settings: change action order → survives relaunch and affects trigger.

### Discreet operation (v0.4.3)

- [ ] All three notification toggles off → no toasts, no grace banner, no countdown text; icon still changes.
- [ ] Re-enable one toggle at a time → expected feedback returns.

### Network & remote (if you use them)

- [ ] Webhook / VPN / SSH / Wi‑Fi actions on trigger (as configured).
- [ ] `magsafeguard://arm?token=…` arms when disarmed.
- [ ] `magsafeguard://trigger?token=…` runs actions when normally armed.

### Panic mode (controlled test only)

⚠️ **Real shutdown.** Use a machine you can power back on; close apps.

- [ ] Menu → **Arm Panic Mode…** → legal notice (first time) → auth → distinct menu icon.
- [ ] **⌃⌘P** while panic-armed → panic pipeline (lock + shutdown path).
- [ ] Unplug while panic-armed → same (no grace).
- [ ] `magsafeguard://panic?token=…` while panic-armed → same.
- [ ] Hotkey / URL **ignored** when not panic-armed or disarmed.
- [ ] Disarm panic → back to normal icon and behavior.

### Menu bar & settings

- [ ] Icon visible (light/dark); overflow menu (•••) if crowded.
- [ ] **Colored menu bar icons** toggle (General + status menu): monochrome default; accent shows state colors.
- [ ] Launch at login + show in dock toggles work.
- [ ] EN/DE strings sane in menus and panic legal alert.
- [ ] iCloud sync (if enabled): settings round-trip on second device or fresh profile.

### Regression spot-checks

- [ ] Auto-arm (if enabled): arms without Touch ID after rules fire.
- [ ] App survives sleep/wake while armed.
- [ ] Quit during grace → warning if still in progress.

Full manual checklist: [acceptance-tests.md](acceptance-tests.md) (includes discreet + panic sections as of v0.5.0).

---

## 3. Release & install

- [x] `task version:show` matches [version.json](../../version.json) and About box.
- [x] `task release` completes (xattr cleanup added to `package-release.sh` for codesign).
- [x] `task release:install` → app in `/Applications`, menu bar app runs.
- [ ] Personal Team **~7-day signing** noted — calendar reminder to rebuild.
- [ ] **Daily driver trial:** run armed (normal mode) for **≥ 3–7 days** without blocker bugs.

### First public binary (optional)

- [ ] GitHub Release tag `v0.5.2` (or next `v0.5.x` patch).
- [ ] Attach `.dmg` + `SHA256SUMS` from `dist/`.
- [ ] Release notes from [FORK_CHANGELOG.md](../FORK_CHANGELOG.md).
- [ ] `LICENSE` + `NOTICE` inside or alongside DMG.

---

## 4. Documentation hygiene

- [x] [user-guide.md](../features/user-guide.md) / [user-guide.de.md](../features/user-guide.de.md) — operation profiles, panic vs preset (0.5.1).
- [x] [acceptance-tests.md](acceptance-tests.md) — panic + discreet sections; removed stale “Run Demo” menu item.
- [x] [behavior-gaps.md](../features/behavior-gaps.md) — only Paranoid open; 0.5.1 batch noted.
- [x] README EN/DE roadmap — 0.5.1 row, network actions table, doc links.

---

## 5. Bug triage template

When something fails during stabilization, capture:

| Field | Example |
|-------|---------|
| **Mode** | Normal armed / panic / disarmed |
| **Trigger** | Cable / hotkey / remote URL / auto-arm |
| **Expected** | Grace 30s then lock |
| **Actual** | No grace, no action |
| **Settings** | Grace 30s, lock only, discreet off |
| **Logs** | Event log entry or `Log` with debug on |

File GitHub Issue or add row to behavior-gaps **Open** until fixed.

---

## Suggested order of work

```text
1. Fix task test (PowerMonitor Sendable)     → CI trust
2. task xcode:test + qa:quick                → app layer
3. Manual smoke §2 (normal + discreet)       → daily driver
4. task release + install                    → real binary
5. One controlled panic test                 → high-assurance path
6. Daily use 1 week                          → exit criteria
7. Patch releases (0.5.1, …) only for fixes  → no new features
```

---

## After stabilization

| Next milestone | When |
|----------------|------|
| **0.5.x patches** | Bugs from daily use only |
| **1.0.0** | Stable + optional notarized DMG |
| **0.6.0 Paranoid** | Only after explicit decision + legal review |

---

*Last updated: 2026-09-01 (fork 0.5.1 — QA status + doc hygiene).*
