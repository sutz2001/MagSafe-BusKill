# MagSafe Guard — User Guide (mini)

**Language:** English · [Deutsch (user-guide.de.md)](user-guide.de.md)  
**Version:** fork **0.5.7** (build 16) · September 2026

Short, practical guide for everyday use. Technical details: [operating-modes.md](operating-modes.md) · Panic design: [panic-modes.md](panic-modes.md)

---

## 1. What the app does

MagSafe Guard is a **menu bar dead-man's switch**:

1. You **arm** protection (Touch ID / password).
2. While armed, **unplugging** the power adapter starts a **grace period** (default 30 seconds).
3. When grace ends (or immediately if grace = 0), **security actions** run (lock screen, alarm, logout, shutdown, custom script).
4. Optional **network actions** (webhook, VPN off, SSH agent clear, clipboard clear, Wi‑Fi off) run on the same trigger.

If the system is **disarmed**, unplugging does **nothing**.

The app runs from the **menu bar** by default (**Show in Dock** is off in Settings → General). Enable the Dock icon if you prefer a Dock shortcut. Menu bar icons are **monochrome** by default; enable **Colored Menu Bar Icons** in General or the status menu for subtle state colors.

---

## 2. Operation profiles (settings presets)

**Settings → Security** (top of the tab) offers four **operation profiles** (menu picker). Choosing one applies a bundle of defaults; you can still tweak individual settings afterward.

| Profile | Grace | Security actions | Notifications | Dock | Network actions |
|---------|-------|------------------|---------------|------|-----------------|
| **Beginner** | 30 s | Lock only | On | Your choice | None |
| **Normal** | 30 s | Lock + alarm | On | Your choice | None |
| **Discreet** | 20 s | Lock only | Off (icon only) | Hidden | None |
| **Panic** (preset) | 5 s | Lock + force logout | Off | Hidden | VPN off, SSH clear, clipboard clear |

**Notes:**

- **Beginner** is the default for **new installs** — recommended for the first days (lock only, full cancel window).
- Colored **impact labels** (Safe / Data loss possible / High impact) appear next to actions and presets — informational only; nothing is blocked.
- The picker **stays on the profile you chose** even if you change a single toggle (there is no automatic switch to “Custom”).
- If settings no longer match the preset, use **Reset to [profile] defaults** under the caption.
- **Panic preset ≠ Arm Panic Mode** (see §5). The preset configures normal armed behavior; **Arm Panic Mode** from the menu is a separate high-assurance armed state with **0 s grace** and immediate shutdown.

**Grace period** and **allow cancel during grace** are on the same **Security** tab, below the profile picker (5–30 s slider).

**Notifications:** link **Customize notifications…** to open the Notifications tab, or use the **Discreet** profile for all-off defaults.

---

## 3. Normal mode — daily workflow

### Arm and disarm

| Action | How |
|--------|-----|
| Arm | Menu bar icon → **Arm Protection** (or **⌘A** when menu is open) |
| Disarm | Menu → **Disarm Protection** + Touch ID / password |
| Event log | **⌘L** or menu → **View Event Log** |
| Settings | **⌘,** or menu → **Settings** (opens on **Security** tab) |

### Grace period

- Countdown appears in the **menu bar** (unless notifications/alerts are off — see §4).
- **Reconnect power** during grace → grace is **cancelled**, system stays **armed**.
- **Cancel grace** (if enabled on Security tab) → Touch ID / password required.

### Security actions

**Settings → Security** — enable/disable the five action types, drag to **reorder**.

On a cable trigger (normal armed), lock screen runs **first**, then other enabled actions (protection-first path).

### Network actions

In the app, open **Settings → Security → Network**.

| Action | What it does |
|--------|----------------|
| HTTP Webhook | POST JSON `{event, source, timestamp}`; optional Bearer token |
| Disconnect VPN | Stop active VPN |
| Clear SSH Agent | `ssh-add -D` |
| Clear Clipboard | Empty macOS pasteboard (universal) |
| Disable Wi‑Fi | Turn off Wi‑Fi — **orange warning** (may affect Find My lock/erase/location) |

Wi‑Fi off is **not** enabled by any preset (keeps Find My). Webhooks stay user-specific.

### Custom scripts (optional)

**Settings → Advanced → Custom Scripts** — add paths under `~/.magsafe/scripts/` or `/usr/local/magsafe-scripts/`.  
Examples: [docs/examples/scripts/README.md](../examples/scripts/README.md) (browser quit, Cryptomator/VeraCrypt unmount, eject externals, browsing data best-effort).

Enable **Custom Script** in Security actions when a path is configured.

### Remote trigger (optional)

If enabled in **Settings → Security → Remote Trigger**:

| URL | Effect |
|-----|--------|
| `magsafeguard://arm?token=YOUR_TOKEN` | Arm without interactive auth (when disarmed) |
| `magsafeguard://trigger?token=YOUR_TOKEN` | Run actions when **normally** armed |
| `magsafeguard://panic?token=YOUR_TOKEN` | Panic response when **panic-armed** (see §5) |
| `magsafeguard://paranoid?token=YOUR_TOKEN` | Paranoid response when **paranoid-armed** (see §6) |

Use from **Shortcuts** on iPhone/Mac. Keep the token secret.

### Command-line CLI (optional)

For **local automation** (scripts, LaunchAgents) on the same Mac — not a replacement for the URL scheme on other devices.

**Requires:** MagSafe Guard **running** in the menu bar.

**Build once** (from a clone of the repo):

```bash
task cli:build
```

Then use the wrapper (or the binary at `MagSafeGuardLib/.build/release/MagSafeGuardCLI`):

```bash
./scripts/magsafeguard-cli status
./scripts/magsafeguard-cli apply-profile beginner
./scripts/magsafeguard-cli arm
./scripts/magsafeguard-cli disarm
```

| Command | Effect |
|---------|--------|
| `status` | Prints JSON from `~/Library/Application Support/MagSafeGuard/cli-status.json` (state, profile, configured risk level, version) |
| `apply-profile <name>` | Sets operation profile: `beginner`, `normal`, `discreet`, or `panic` — no auth |
| `arm` / `disarm` | Same as the menu — **Touch ID / password** prompt in the app |

`arm` does **not** bypass authentication (unlike `magsafeguard://arm?token=…` with remote trigger enabled).

---

## 4. Discreet operation

**Low visibility:** menu bar icon only — no sounds or macOS notifications.

**Fast path:** choose **Discreet** operation profile (Settings → Security).

**Manual path:** **Settings → Notifications** — turn off all three:

| Toggle | When off |
|--------|----------|
| Show status notifications | No arm/disarm toasts |
| Show security alerts | No grace banner; no countdown text in menu bar |
| Play critical alert sound | No beep when grace starts |

Grace still runs; you can still disarm via the menu.

---

## 5. Panic protection mode (v0.5.0)

**Arm Panic Mode…** from the menu is separate from the **Panic** operation profile in Settings.

| | Panic **profile** (Settings) | Panic **protection mode** (menu) |
|---|------------------------------|----------------------------------|
| Purpose | Aggressive defaults for **normal** armed use | Maximum response when cable is pulled |
| Grace on disconnect | 5 s (configurable) | **0 s** — immediate |
| Cancel during response | Per settings | **No** |
| Shutdown | Per your security actions | **Immediate** |
| How to enable | Settings → Security → Panic | Menu → **Arm Panic Mode…** + auth |

When **panic-armed**, unplugging runs the panic pipeline regardless of the profile grace slider.

### How to arm panic protection

1. Menu bar → **Arm Panic Mode…** (shortcut **⌘P** when menu is open).
2. **First time only:** read the short legal notice → **I Understand — Arm Panic**.
3. Authenticate with Touch ID / password.
4. Menu bar icon switches to the **triggered** style while panic-armed.

To leave: menu → **Disarm Protection** (normal disarm flow).

### How to trigger panic (when panic-armed)

| Trigger | What happens |
|---------|----------------|
| **Unplug cable** | Immediate panic pipeline |
| **⌃⌘P** (Control+Command+P) | Same — **globally** while MagSafe Guard is running |
| `magsafeguard://panic?token=…` | Same — remote (Shortcuts, another device) |

**⌃⌘P** only works when **panic-armed**; ignored when disarmed or normal-armed.

### What panic protection does

1. Enabled **network actions** (preset includes VPN, SSH, clipboard — plus any you added)
2. Lock screen **first**, then logout/alarm in parallel
3. **Immediate shutdown** (no 1-minute macOS dialog)

**Does not:** delete files or wipe disks.

### ⚠️ Warnings

- **Unsaved work may be lost.**
- Test only on a machine you can afford to shut down.
- **Work devices:** check employer policy before using panic on a managed Mac.
- Reconnecting power during panic response **does not** cancel shutdown.

---

## 6. Paranoid protection mode (v0.6.0)

**Different from the Panic Settings preset.** Paranoid is a separate armed state that **destroys configured data**, then shuts down.

| | Panic **protection** armed | Paranoid **protection** armed |
|---|----------------------------|-------------------------------|
| Data destruction | No | **Yes** (configured paths/volumes) |
| Prerequisites | Short legal notice | FileVault on, wipe targets, full legal, codeword |
| Hotkey | **⌃⌘P** | **⌃⌘⇧P** |
| Remote URL | `…/panic?token=` | `…/paranoid?token=` (optional separate token) |

### How to prepare

1. **Settings → Security → Paranoid Setup Wizard…** (FileVault on + at least one wipe path or APFS volume UUID).
2. **Full Legal Notice…** — scroll, checkbox, accept.
3. **Set Codeword…** (min. 4 characters; stored hashed only).
4. Optionally set wipe order (↑/↓) and wipe time budget.

### How to arm

1. Menu → **Arm Paranoid Mode…**
2. Enter codeword + confirm intent checkbox.
3. Authenticate with Touch ID / password.
4. Menu bar uses **bolt.shield.fill** while paranoid-armed.

### How to trigger (when paranoid-armed)

| Trigger | What happens |
|---------|----------------|
| **Unplug cable** | Wipe (list order, time budget) + lock/hygiene, then hard shutdown |
| **⌃⌘⇧P** | Same |
| `magsafeguard://paranoid?token=…` | Same (remote trigger enabled; token must match) |

### ⚠️ Warnings

- **Irreversible data loss** on configured targets.
- APFS does **not** guarantee secure overwrite (TRIM/snapshots).
- Never target the boot volume.
- **Do not** use on employer/shared Macs unless authorized.
- Test only with disposable paths on a spare Mac / dedicated volume.
- Informed legal self-review (BusKill-aligned): [legal-review-gate.md](../maintainers/legal-review-gate.md). Formal counsel optional before commercial push.

---

## 7. Quick comparison

| | Normal armed | Discreet profile | Panic profile | Panic **protection** | Paranoid **protection** |
|---|--------------|------------------|---------------|----------------------|-------------------------|
| Typical grace | 30 s | 20 s | 5 s | **0 s** | **0 s** |
| Data wipe | No | No | No | No | **Yes** |
| Hotkey | — | — | — | **⌃⌘P** | **⌃⌘⇧P** |

---

## 8. Auto-arm (optional)

In the app, open **Settings → Auto-Arm**.

- Arm automatically when leaving a trusted location or joining an untrusted network.
- Uses `armAutomatically()` — no Touch ID prompt on auto-arm (by design).
- Can be temporarily disabled from the menu.
- Auto-arm uses **normal** armed mode (not panic/paranoid).

---

## 9. Troubleshooting

| Problem | Check |
|---------|--------|
| Unplugging does nothing | System is **disarmed** |
| No menu bar icon | App running? Check menu bar overflow (•••) |
| Can't find app | Settings → General → **Show in Dock** on, or use Spotlight |
| Hotkey ⌃⌘P does nothing | Must be **panic-armed**; app must be running |
| Hotkey ⌃⌘⇧P does nothing | Must be **paranoid-armed**; app must be running |
| Remote URL ignored | Token correct? Remote trigger enabled? Correct host (`panic` vs `paranoid`)? |
| Can't arm Paranoid | Setup + legal + codeword checklist in Settings → Security |
| CLI says “Status unavailable” | Is the app running? Run `status` once after launch so the status file is written |
| CLI `arm` times out | Complete Touch ID / password in the app; allow up to 30 s |
| Build expired after ~7 days | Personal Team — rebuild with `task release` or Xcode |

More: [maintainers/troubleshooting.md](../maintainers/troubleshooting.md)

---

## 10. Further reading

| Document | Audience |
|----------|----------|
| [operating-modes.md](operating-modes.md) | Full state machine & technical flows |
| [panic-modes.md](panic-modes.md) | Panic/Paranoid design & legal notes |
| [examples/scripts/README.md](../examples/scripts/README.md) | Example custom scripts |
| [behavior-gaps.md](behavior-gaps.md) | Resolved vs open UI/runtime items |
| [FORK_CHANGELOG.md](../FORK_CHANGELOG.md) | Release history |
| [README.md](../../README.md) | Build, install, roadmap |
