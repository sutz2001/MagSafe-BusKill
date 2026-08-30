# MagSafe Guard

**Language:** English · [Deutsch (README.de.md)](README.de.md)

A macOS menu bar app that turns your power cable into a dead-man's switch: when **armed**, unplugging the adapter starts a grace period, then runs configurable security actions (screen lock, alarm, logout, shutdown, or a custom script).

Inspired by [BusKill](https://github.com/BusKill/buskill-app). Upstream: [lekman/magsafe-buskill](https://github.com/lekman/magsafe-buskill). This fork: [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).

![Demo](docs/assets/magsafe-guard.gif)

---

## What it does today

| Area | Status | Notes |
|------|--------|--------|
| Power disconnect detection | ✅ Works | MagSafe, USB-C, third-party adapters |
| Arm / disarm with Touch ID or password | ✅ Works | Required before monitoring is active |
| Grace period (default **30 s**, range 5–30 s) | ✅ Works | Cancel during countdown with auth (if enabled) |
| Menu bar UI & settings | ✅ Works | Icon in menu bar, not a normal window |
| Security actions (see below) | ✅ Works | Configurable order in Settings |
| Notifications | ✅ Works | macOS permission on first launch |
| Auto-arm (location / network) | ✅ Works | Optional; needs Location permission |
| Rate limiting & circuit breaker | ✅ Works | Prevents action storms |
| iCloud / CloudKit sync | ⚠️ Partial | **Requires paid Apple Developer account**; disabled in this fork's entitlements for Personal Team |
| Push notifications capability | ⚠️ Partial | Same as iCloud — not available on free Personal Team |
| Mac App Store release | ❌ Not yet | Upstream lists as "coming soon" |
| Volume unmount / disk wipe | ❌ Not implemented | Only via custom script if you write one |
| Network actions (remote triggers) | ❌ Not implemented | Planned upstream |
| Evidence collection / log viewer UI | 🔄 In progress upstream | Partial code exists |

**Important:** While **disarmed**, unplugging power does **nothing**. The app only monitors when you explicitly **arm** it.

---

## Security actions

All actions are defined in `SecurityActionType` (`MagSafeGuardLib/.../SecurityActionProtocols.swift`).

| Action | Implemented | What it does |
|--------|-------------|--------------|
| **Lock Screen** | ✅ | Locks display (`pmset displaysleepnow` + system notification) |
| **Sound Alarm** | ✅ | Plays `alarm.wav` or system beeps in a loop |
| **Force Logout** | ✅ | Logs out all users via AppleScript |
| **System Shutdown** | ✅ | Schedules shutdown (default **30 s** delay, configurable) |
| **Custom Script** | ✅ | Runs `.sh` / `.zsh` / `.bash` from allowed directories only |

**Default actions:** Lock Screen + Sound Alarm. In **Settings → Security**, add actions with **+**, remove with **−** (at least one must stay active), drag to reorder.

**Custom script paths (enforced in code):**

- `~/.magsafe/scripts/`
- `/usr/local/magsafe-scripts/`

Scripts are validated (path traversal blocked, dangerous commands rejected, must be executable).

**Not available as built-in actions:** volume eject/unmount, remote wipe, Find My activation — use a custom script if needed.

---

## How it works

```text
disarmed → armed → grace period (30 s default) → security actions
              ↑              ↓
              └── auth (disarm / cancel grace)
```

1. Arm from the menu bar (authentication required).
2. Work normally with the adapter connected.
3. If the cable is pulled, grace period starts.
4. Optionally cancel with Touch ID / password during grace period.
5. When grace period ends, enabled actions run in order.

---

## Build & run (this fork)

### Requirements

- macOS **13+** (Ventura)
- **Xcode 15+** (tested with Xcode 26)
- [Task](https://taskfile.dev): `brew install go-task/tap/go-task`

### First-time setup

```bash
git clone https://github.com/sutz2001/MagSafe-BusKill.git
cd MagSafe-BusKill
task setup
open MagSafeGuard.xcodeproj
```

In Xcode:

1. Target **MagSafeGuard** → **Signing & Capabilities**
2. **Team:** your Apple ID (**Personal Team** is fine for local dev)
3. **Bundle ID:** `com.sutz2001.MagSafeGuard` (already set in this fork)
4. **Do not** add iCloud or Push Notifications on a free account — they are removed from entitlements here
5. **⌘R** to run — app appears in the **menu bar**

### Command line

```bash
task build          # SPM + lib build
task test           # run tests
task run            # run menu bar app (preferred for dev)
```

Stop the app: quit from menu bar, or **⌘.** in Xcode, or Activity Monitor.

---

## Apple signing: free vs paid account

| Topic | Personal Team (free Apple ID) | Paid Developer Program ($99/year) |
|-------|------------------------------|-----------------------------------|
| Build & run on **your** Mac | ✅ Yes | ✅ Yes |
| iCloud / CloudKit in app | ❌ No | ✅ Yes |
| Push Notifications capability | ❌ No | ✅ Yes |
| Distribute to others / notarize | ❌ No | ✅ Yes (Developer ID) |
| TestFlight / Mac App Store | ❌ No | ✅ Yes |

### Does the app “expire”?

- **No time limit on the source code** — you can rebuild anytime.
- **Development builds** are signed with a **provisioning profile** that expires (typically after **~7 days** on Personal Team).
- When expired, the app may **refuse to open** until you **build again from Xcode** (⌘R). Xcode renews the profile automatically.
- Paid accounts use longer-lived certificates (~1 year); same idea — rebuild or re-sign before expiry if needed.
- This is **not** a trial of MagSafe Guard; it is standard Apple code signing.

---

## Fork-specific changes (vs upstream)

| Item | This fork |
|------|-----------|
| Bundle ID | `com.sutz2001.MagSafeGuard` |
| Development team | Your Personal Team (not upstream author's) |
| Entitlements | iCloud / push removed for Personal Team signing |
| Grace period default | **30 seconds** |
| CI: OSSF Scorecard | Skipped on private repos |
| Security action defaults | `.defaultConfig` naming (upstream rename) |

To sync with upstream:

```bash
git fetch upstream
git merge upstream/main
```

---

## Versioning

**Single source of truth:** [`version.json`](version.json)

| Field | Current (fork) | Purpose |
|-------|----------------|---------|
| `marketingVersion` | **0.2.0** | Semver shown to users |
| `buildNumber` | **1** | Integer build (Xcode `CURRENT_PROJECT_VERSION`) |

```bash
task version:show          # print current version
task version:sync          # sync to AppVersion.swift + Xcode project
task version:bump:patch    # 0.2.0 → 0.2.1
task version:bump:minor    # 0.2.0 → 0.3.0
```

Fork versioning is **independent** from upstream (`1.11.0`). Swift constant: `AppVersion.marketing` in `MagSafeGuardCore`.

When bumping: update `version.json`, run `task version:sync`, add `docs/CHANGELOG.md` entry, tag `vX.Y.Z` on release.

---

## Testing & quality

```bash
task test              # unit tests
task qa:quick          # fast checks
task qa                # full local QA
```

CI runs on GitHub Actions (tests, security scans). See [docs/devops/ci-cd-workflows.md](docs/devops/ci-cd-workflows.md).

---

## Documentation

| Doc | Audience |
|-----|----------|
| [README.de.md](README.de.md) | German version of this file |
| [AGENTS.md](AGENTS.md) | AI agent index (Cursor + Copilot — keep in sync) |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | GitHub Copilot repository rules |
| [.cursor/rules/project-conventions.mdc](.cursor/rules/project-conventions.mdc) | Cursor rules |
| [docs/README.md](docs/README.md) | Full upstream documentation index |
| [docs/maintainers/building-and-running.md](docs/maintainers/building-and-running.md) | Detailed build guide |
| [docs/maintainers/code-signing.md](docs/maintainers/code-signing.md) | Signing & distribution |
| [docs/architecture/architecture-overview.md](docs/architecture/architecture-overview.md) | Architecture |

---

## License & credits

MIT License — see [LICENSE](LICENSE) and [NOTICE](NOTICE).

- Original concept: [BusKill](https://github.com/BusKill/buskill-app)
- Upstream maintainer: [Tobias Lekman / lekman/magsafe-buskill](https://github.com/lekman/magsafe-buskill)
- This fork: [Marc Seitz / sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill) (fork modifications © 2025–2026 Marc Seitz)
