# MagSafe Guard — User Guide (mini)

**Language:** English · [Deutsch (user-guide.de.md)](user-guide.de.md)  
**Version:** fork **0.5.0** (build 9) · August 2026

Short, practical guide for everyday use. Technical details: [operating-modes.md](operating-modes.md) · Panic design: [panic-modes.md](panic-modes.md)

---

## 1. What the app does

MagSafe Guard is a **menu bar dead-man's switch**:

1. You **arm** protection (Touch ID / password).
2. While armed, **unplugging** the power adapter starts a **grace period** (default 30 seconds).
3. When grace ends (or immediately if grace = 0), **security actions** run (lock screen, alarm, logout, shutdown, custom script).
4. Optional **network actions** (webhook, VPN off, SSH agent clear, Wi‑Fi off) run on the same trigger.

If the system is **disarmed**, unplugging does **nothing**.

---

## 2. Normal mode — daily workflow

### Arm and disarm

| Action | How |
|--------|-----|
| Arm | Menu bar icon → **Arm Protection** (or **⌘A** when menu is open) |
| Disarm | Menu → **Disarm Protection** + Touch ID / password |
| Event log | **⌘L** or menu → **View Event Log** |
| Settings | **⌘,** or menu → **Settings** |

### Grace period

- Countdown appears in the **menu bar** (unless discreet mode — see §3).
- **Reconnect power** during grace → grace is **cancelled**, system stays **armed**.
- **Cancel grace** (if enabled in Settings → General) → Touch ID / password required.

### Configure actions

**Settings → Security**

- Enable/disable the five action types.
- Drag to **reorder** (normal armed mode uses your order after lock-first optimization on cable trigger).
- **Network** section: webhook, VPN, SSH, Wi‑Fi, remote URL token.

### Remote trigger (optional)

If enabled in **Settings → Security → Remote Trigger**:

| URL | Effect |
|-----|--------|
| `magsafeguard://arm?token=YOUR_TOKEN` | Arm without interactive auth (when disarmed) |
| `magsafeguard://trigger?token=YOUR_TOKEN` | Run actions when **normally** armed |
| `magsafeguard://panic?token=YOUR_TOKEN` | Panic response when **panic-armed** (see §4) |

Use from **Shortcuts** on iPhone/Mac. Keep the token secret.

---

## 3. Discreet operation (v0.4.3)

For low-visibility use (e.g. café, meeting): only the **menu bar icon** changes — no sounds or macOS notifications.

**Settings → Notifications**

| Toggle | When off |
|--------|----------|
| Show status notifications | No arm/disarm toasts |
| Show security alerts | No grace banner; no countdown text in menu bar |
| Play critical alert sound | No beep when grace starts |

**All three off** → discreet operation (icon only). Grace still runs; you can still disarm via menu.

---

## 4. Panic mode (v0.5.0)

**Panic** is a separate, high-assurance profile: **no grace period**, **no cancel** during response, **immediate shutdown** after lock/logout/network actions. **No file deletion.**

### When to use

Travel, high-risk environments, or when you want the Mac unusable instantly if the cable is pulled — without waiting 30 seconds.

### How to arm panic

1. Menu bar → **Arm Panic Mode…** (shortcut **⌘P** when menu is open).
2. **First time only:** read the short legal notice → **I Understand — Arm Panic**.
3. Authenticate with Touch ID / password.
4. Menu bar icon switches to the **triggered** style while panic-armed.

To leave panic mode: menu → **Disarm Protection** (normal disarm flow).

### How to trigger panic (when panic-armed)

| Trigger | What happens |
|---------|----------------|
| **Unplug cable** | Immediate panic pipeline |
| **⌃⌘P** (Control+Command+P) | Same — works **globally** while MagSafe Guard is running |
| `magsafeguard://panic?token=…` | Same — remote (Shortcuts, another device) |

**⌃⌘P** tips:

- **P** = Panic (easy to remember).
- **Control** avoids conflicting with **⌘P** (Print).
- No Accessibility permission required.
- Only works when you are **panic-armed**; ignored in normal/disarmed state.

### What panic does

1. Network actions (if enabled)
2. Lock screen **first**, then logout/alarm in parallel
3. **Immediate shutdown** (no 1-minute macOS dialog)

**Does not:** delete files, wipe disks, or show a cancel dialog.

### ⚠️ Warnings

- **Unsaved work may be lost.**
- Test only on a machine you can afford to shut down.
- **Work devices:** check employer policy before using panic on a managed Mac.
- Reconnecting power during panic response **does not** cancel the shutdown.

---

## 5. Normal vs panic — quick comparison

| | Normal armed | Panic armed |
|---|--------------|-------------|
| Grace period | 5–30 s (default 30) | **0 s** |
| Cancel during grace | Yes (if enabled) | **No** |
| Cable reconnect during response | Cancels grace | **No effect** |
| Shutdown | Scheduled (configurable delay) | **Immediate** |
| Hotkey | — | **⌃⌘P** |
| Data deletion | No | No |

**Paranoid mode** (data destruction) is **not** implemented — planned v0.6.0.

---

## 6. Auto-arm (optional)

**Settings → Auto-Arm**

- Arm automatically when leaving a trusted location or joining an untrusted network.
- Uses `armAutomatically()` — no Touch ID prompt on auto-arm (by design).
- Can be temporarily disabled from the menu.

---

## 7. Troubleshooting

| Problem | Check |
|---------|--------|
| Unplugging does nothing | System is **disarmed** |
| No menu bar icon | App running? Check menu bar overflow (•••) |
| Hotkey ⌃⌘P does nothing | Must be **panic-armed**; app must be running |
| Remote URL ignored | Token correct? Remote trigger enabled in Settings? |
| Build expired after ~7 days | Personal Team — rebuild with `task release` or Xcode |

More: [maintainers/troubleshooting.md](../maintainers/troubleshooting.md)

---

## 8. Further reading

| Document | Audience |
|----------|----------|
| [operating-modes.md](operating-modes.md) | Full state machine & technical flows |
| [panic-modes.md](panic-modes.md) | Panic/Paranoid design & legal notes |
| [behavior-gaps.md](behavior-gaps.md) | Resolved vs open UI/runtime items |
| [FORK_CHANGELOG.md](../FORK_CHANGELOG.md) | Release history |
| [README.md](../../README.md) | Build, install, roadmap |
