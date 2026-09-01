#!/bin/bash
# MagSafe Guard — example custom script
# Closes common browsers. Open tabs/sessions end; saved history is NOT removed.
#
# Install:
#   mkdir -p "$HOME/.magsafe/scripts"
#   cp quit-browsers.sh "$HOME/.magsafe/scripts/"
#   chmod 700 "$HOME/.magsafe/scripts/quit-browsers.sh"
#
# Settings → Advanced → Custom Scripts (add path)
# Settings → Security → enable "Custom Script"

set -u

quit_app() {
  /usr/bin/osascript -e "tell application \"$1\" to quit" 2>/dev/null || true
}

for app in Safari "Google Chrome" Firefox "Brave Browser" "Microsoft Edge" Arc Chromium Orion; do
  quit_app "$app"
done

# Fallback if an app ignored AppleScript quit
/usr/bin/killall Safari 2>/dev/null || true
/usr/bin/killall "Google Chrome" 2>/dev/null || true
/usr/bin/killall firefox 2>/dev/null || true
/usr/bin/killall "Brave Browser" 2>/dev/null || true
/usr/bin/killall "Microsoft Edge" 2>/dev/null || true
/usr/bin/killall Arc 2>/dev/null || true
/usr/bin/killall Chromium 2>/dev/null || true
/usr/bin/killall Orion 2>/dev/null || true

exit 0
