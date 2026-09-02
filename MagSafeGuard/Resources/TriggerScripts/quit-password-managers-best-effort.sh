#!/bin/bash
# MagSafe Guard — bundled trigger script
# Quit common password managers (best-effort — cannot cover every app).
#
# Covers: 1Password, Bitwarden, KeePassXC, Strongbox, Dashlane, Enpass.
# Extend the list below for your apps.
#
# Install: copy from app bundle TriggerScripts/ to ~/.magsafe/scripts/ (see README.md).

set -u

quit_app() {
  /usr/bin/osascript -e "tell application \"$1\" to quit" 2>/dev/null || true
}

for app in "1Password" "1Password 7" Bitwarden KeePassXC Strongbox Dashlane Enpass; do
  quit_app "$app"
done

/usr/bin/killall "1Password" 2>/dev/null || true
/usr/bin/killall "1Password 7" 2>/dev/null || true
/usr/bin/killall Bitwarden 2>/dev/null || true
/usr/bin/killall keepassxc 2>/dev/null || true
/usr/bin/killall Strongbox 2>/dev/null || true
/usr/bin/killall Dashlane 2>/dev/null || true
/usr/bin/killall Enpass 2>/dev/null || true

exit 0
