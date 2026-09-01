#!/bin/bash
# MagSafe Guard — example custom script (advanced)
# Best-effort removal of saved browsing history for common browsers.
#
# Limits:
#   - Not all browsers or profiles (Chrome "Profile 1", Firefox containers, etc.)
#   - MagSafe Guard may need Full Disk Access to delete some files
#   - Browsers must be closed first (this script quits them, then waits briefly)
#   - Does NOT clear iCloud-synced Safari data on other devices
#
# Prefer quit-browsers.sh if you only need to close sessions without touching history.
#
# Install: same as quit-browsers.sh (copy to ~/.magsafe/scripts/, chmod 700)

set -u

quit_app() {
  /usr/bin/osascript -e "tell application \"$1\" to quit" 2>/dev/null || true
}

for app in Safari "Google Chrome" Firefox "Brave Browser" "Microsoft Edge" Arc Chromium Orion; do
  quit_app "$app"
done

/usr/bin/killall Safari 2>/dev/null || true
/usr/bin/killall "Google Chrome" 2>/dev/null || true
/usr/bin/killall firefox 2>/dev/null || true
/usr/bin/killall "Brave Browser" 2>/dev/null || true
/usr/bin/killall "Microsoft Edge" 2>/dev/null || true
/usr/bin/killall Arc 2>/dev/null || true
/usr/bin/killall Chromium 2>/dev/null || true
/usr/bin/killall Orion 2>/dev/null || true

/bin/sleep 2

# Safari
/bin/rm -f "$HOME/Library/Safari/History.db" 2>/dev/null || true
/bin/rm -f "$HOME/Library/Safari/History.db-wal" 2>/dev/null || true
/bin/rm -f "$HOME/Library/Safari/History.db-shm" 2>/dev/null || true

# Chromium family (default profile only — extend paths if you use extra profiles)
for base in \
  "$HOME/Library/Application Support/Google/Chrome/Default" \
  "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default" \
  "$HOME/Library/Application Support/Microsoft Edge/Default" \
  "$HOME/Library/Application Support/Arc/User Data/Default" \
  "$HOME/Library/Application Support/Chromium/Default"; do
  /bin/rm -f "$base/History" 2>/dev/null || true
  /bin/rm -f "$base/History-journal" 2>/dev/null || true
done

# Firefox (all profiles under Profiles/)
for places in "$HOME/Library/Application Support/Firefox/Profiles/"*/places.sqlite; do
  if [ -f "$places" ]; then
    /bin/rm -f "$places" 2>/dev/null || true
    /bin/rm -f "${places}-wal" 2>/dev/null || true
    /bin/rm -f "${places}-shm" 2>/dev/null || true
  fi
done

exit 0
