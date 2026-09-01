#!/bin/bash
# MagSafe Guard — example custom script
# Clears the macOS clipboard (pasteboard).
#
# Install: copy to ~/.magsafe/scripts/ and chmod 700 (see README.md in this folder).

set -u

/usr/bin/pbcopy < /dev/null
exit 0
