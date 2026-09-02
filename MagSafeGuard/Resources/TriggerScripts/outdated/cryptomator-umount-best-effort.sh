#!/bin/bash
# MagSafe Guard — bundled trigger script (advanced)
# Auto-detect Cryptomator mounts (BusKill trigger_cryptomator_umount style).
#
# Detects macFUSE (device name contains Cryptomator) and WebDAV (:42427/).
# Also quits the Cryptomator app.
#
# Note: Settings → Network → Unmount Cryptomator is built in (same logic).
# Use this script only if you need it in the custom-script phase or without the toggle.
#
# Install: copy from app bundle TriggerScripts/ to ~/.magsafe/scripts/ (see README.md).

set -u

/usr/bin/osascript -e "tell application \"Cryptomator\" to quit" 2>/dev/null || true
/usr/bin/killall Cryptomator 2>/dev/null || true

/bin/sleep 1

/sbin/mount 2>/dev/null \
  | /usr/bin/grep -Ei 'cryptomator|:42427/' \
  | /usr/bin/awk '/ on \/Volumes\// {
      split($0, parts, " on ")
      split(parts[2], mp, " (")
      print mp[1]
    }' \
  | while read -r mount_point; do
      if [ -n "$mount_point" ] && [ -d "$mount_point" ]; then
        /usr/sbin/diskutil unmount force "$mount_point" 2>/dev/null || true
      fi
    done

exit 0
