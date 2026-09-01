# Example custom scripts

MagSafe Guard can run **shell scripts** as a security action (`Settings → Security → Custom Script`).  
Scripts must live in:

- `~/.magsafe/scripts/`
- `/usr/local/magsafe-scripts/`

Only `.sh`, `.zsh`, and `.bash` files are accepted. The app validates script content (no `sudo`, `curl`, `rm -rf /`, etc.) — these examples are written to pass that validation.

## Quick install

```bash
mkdir -p "$HOME/.magsafe/scripts"
cp docs/examples/scripts/*.sh "$HOME/.magsafe/scripts/"
chmod 700 "$HOME/.magsafe/scripts/"*.sh
```

Then in the app:

1. **Settings → Advanced → Custom Scripts** — add the full path, e.g. `~/.magsafe/scripts/quit-browsers.sh` (use your home path, not `~`).
2. **Settings → Security** — enable **Custom Script** and order actions as needed.

Test with **Test security actions** (or a dry run in Terminal) before arming.

## Scripts

| Script | Purpose | Risk |
| --- | --- | --- |
| [`quit-browsers.sh`](quit-browsers.sh) | Quit Safari, Chrome, Firefox, Brave, Edge, Arc, … | Low — closes sessions only |
| [`clear-browsing-data-best-effort.sh`](clear-browsing-data-best-effort.sh) | Quit browsers, then delete common history DB files | Medium — irreversible, incomplete, may need **Full Disk Access** |
| [`clear-clipboard.sh`](clear-clipboard.sh) | Empty the pasteboard | Low — **also built in** under Settings → Network → Clear Clipboard |

### Why not a built-in “clear browser history” toggle?

Each browser stores data in different paths; profiles multiply the problem. A single reliable switch is not possible without false promises. **Custom scripts** let you choose what fits your machine (one browser, your profile paths, your risk tolerance).

For **HTTP webhooks**, use **Settings → Network → HTTP Webhook** instead of a script (`curl` is blocked in scripts).

## Customize

- Copy a script and edit paths (e.g. Chrome `Profile 1` instead of `Default`).
- Combine with lock screen / logout in **Security** action order.
- Do **not** enable destructive scripts on a work Mac without policy approval.

## Deutsch

**Installation:** Skripte nach `~/.magsafe/scripts/` kopieren, `chmod 700` setzen, Pfad unter **Einstellungen → Erweitert → Eigene Skripte** eintragen, unter **Sicherheit** „Eigenes Skript“ aktivieren.

- **`quit-browsers.sh`** — Browser beenden (Tabs weg, Verlauf bleibt).
- **`clear-browsing-data-best-effort.sh`** — Verlauf best-effort löschen (unvollständig, ggf. Vollzugriff auf Festplatte nötig).
- **`clear-clipboard.sh`** — Zwischenablage leeren.

Siehe auch [operating-modes.md](../../features/operating-modes.md) (Custom Script) und [panic-modes.md](../../features/panic-modes.md) (geplante Session-Kill-Aktionen).
