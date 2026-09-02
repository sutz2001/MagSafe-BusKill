#!/bin/bash
# MagSafe Guard — bundled trigger script
# Turns Bluetooth off via blueutil (no reliable built-in macOS CLI without it).
#
# Note: Settings → Network → Disable Bluetooth is built in when blueutil is installed.
# Install blueutil: brew install blueutil
#
# Install script: copy from app bundle TriggerScripts/ to ~/.magsafe/scripts/ (see README.md).

set -u

BLUEUTIL=""

if [ -x /opt/homebrew/bin/blueutil ]; then
  BLUEUTIL=/opt/homebrew/bin/blueutil
elif [ -x /usr/local/bin/blueutil ]; then
  BLUEUTIL=/usr/local/bin/blueutil
fi

if [ -n "$BLUEUTIL" ]; then
  "$BLUEUTIL" -p 0 2>/dev/null || true
fi

exit 0
