# Trigger scripts (shipped with MagSafe Guard)

These shell scripts ship inside **MagSafe Guard.app** (`.sh` files under `Contents/Resources/`, plus `outdated/` for superseded examples).

In the repository they live at `MagSafeGuard/Resources/TriggerScripts/`.

Use them as **custom scripts** (`Settings → Advanced → Custom Scripts`) or copy to `~/.magsafe/scripts/`. **Install bundled scripts…** copies only script-only actions (not duplicates of built-in network toggles).

Only `.sh` files in `~/.magsafe/scripts/` or `/usr/local/magsafe-scripts/` can run from the app. Scripts are content-validated (no `sudo`, `curl`, etc.) — these examples pass validation.

## Install from the app

**Settings → Advanced → Install bundled scripts…** copies installable scripts to `~/.magsafe/scripts/`, adds them to your script list, and enables the Custom Script security action.

Manual copy (git checkout):

```bash
mkdir -p "$HOME/.magsafe/scripts"
cp MagSafeGuard/Resources/TriggerScripts/*.sh "$HOME/.magsafe/scripts/"
chmod 700 "$HOME/.magsafe/scripts/"*.sh
```

(Do not copy `outdated/` unless you need a legacy fallback.)

## Built-in network actions (prefer these)

| Action | Settings → Network |
| --- | --- |
| Clear clipboard | Clear Clipboard |
| Eject removable volumes | Eject Removable Volumes |
| Unmount Cryptomator | Unmount Cryptomator |
| Disable Bluetooth | Disable Bluetooth (needs `blueutil`) |

Superseded script copies live in [`outdated/OUTDATED.md`](outdated/OUTDATED.md) — not installed by the app.

## Installable scripts (custom script only)

| Script | Purpose |
| --- | --- |
| `quit-browsers.sh` | Quit Safari, Chrome, Firefox, Brave, Edge, Arc, … |
| `quit-password-managers-best-effort.sh` | Quit 1Password, Bitwarden, KeePassXC, … |
| `veracrypt-dismount-best-effort.sh` | `veracrypt -d` when installed |
| `clear-browsing-data-best-effort.sh` | Quit browsers, delete common history DBs |
| `delete-filevault-recovery-key-backup-best-effort.sh` | Delete configured recovery key **backup file** (edit path) |

**Suggested trigger order:** built-in clipboard/eject/Cryptomator/Bluetooth → VeraCrypt script → browsers → password managers → optional history / recovery-key script.

See [panic-modes.md](../../../docs/features/panic-modes.md) and [operating-modes.md](../../../docs/features/operating-modes.md).

## Deutsch

**Mitgelieferte Skripte installieren…** kopiert nur die fünf Skripte ohne eingebaute Entsprechung. Duplikate liegen in `outdated/` (Referenz, keine Auto-Installation). Netzwerk-Aktionen (Zwischenablage, Auswerfen, Cryptomator, Bluetooth) in **Einstellungen → Sicherheit → Netzwerk** nutzen.
