#!/bin/bash
# MagSafe Guard — example custom script (advanced)
# Best-effort dismount of all VeraCrypt volumes (macOS).
#
# BusKill documents VeraCrypt auto-dismount on app quit; this script calls
# veracrypt -d explicitly when the CLI is installed.
#
# Limits:
#   - Requires VeraCrypt with CLI on PATH or in standard install locations
#   - Mounted volumes may need no extra prompt; behavior depends on VeraCrypt settings
#   - Does NOT wipe headers (see BusKill LUKS trigger on Linux for that pattern)
#
# Install: copy to ~/.magsafe/scripts/ and chmod 700 (see README.md in this folder).

set -u

VERACRYPT_BIN=""

if [ -x /usr/local/bin/veracrypt ]; then
  VERACRYPT_BIN=/usr/local/bin/veracrypt
elif [ -x /opt/homebrew/bin/veracrypt ]; then
  VERACRYPT_BIN=/opt/homebrew/bin/veracrypt
elif [ -x /Applications/VeraCrypt.app/Contents/MacOS/VeraCrypt ]; then
  VERACRYPT_BIN=/Applications/VeraCrypt.app/Contents/MacOS/VeraCrypt
fi

if [ -n "$VERACRYPT_BIN" ]; then
  "$VERACRYPT_BIN" -d 2>/dev/null || true
fi

/usr/bin/osascript -e "tell application \"VeraCrypt\" to quit" 2>/dev/null || true
/usr/bin/killall VeraCrypt 2>/dev/null || true

exit 0
