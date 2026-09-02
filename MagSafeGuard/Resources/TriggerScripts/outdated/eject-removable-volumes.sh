#!/bin/bash
# MagSafe Guard — example custom script (advanced)
# Eject external physical disks listed by diskutil (USB sticks, SD cards, portable SSDs).
#
# Inspired by BusKill-style “remove external media” hygiene; macOS uses diskutil.
#
# Limits:
#   - Skips the internal boot disk; may still eject other mounted externals you rely on
#   - Network volumes and some DMGs are not "external physical" — usually skipped
#   - Test on your hardware before arming; order scripts before lock/shutdown in Settings
#
# Install: copy to ~/.magsafe/scripts/ and chmod 700 (see README.md in this folder).

set -u

/usr/sbin/diskutil list external physical 2>/dev/null \
  | /usr/bin/grep '^/dev/disk' \
  | /usr/bin/cut -d' ' -f1 \
  | while read -r dev; do
      if [ -n "$dev" ]; then
        /usr/sbin/diskutil eject "$dev" 2>/dev/null || true
      fi
    done

exit 0
