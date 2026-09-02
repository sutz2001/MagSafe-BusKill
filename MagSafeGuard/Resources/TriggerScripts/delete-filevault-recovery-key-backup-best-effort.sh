#!/bin/bash
# MagSafe Guard — bundled trigger script (advanced / paranoid prep)
# Deletes a local FileVault recovery key backup file you configured.
#
# macOS analogue (partial) to Linux LUKS header destruction: without the recovery
# key backup, an attacker cannot unlock FileVault with the escrowed key file.
# This does NOT shred the boot volume header — see docs/features/panic-modes.md.
#
# --- Configure: absolute path to your recovery key backup (PDF, dmg, text export) ---
RECOVERY_KEY_BACKUP_PATH="$HOME/Desktop/FileVaultRecoveryKey.pdf"

if [ -n "$RECOVERY_KEY_BACKUP_PATH" ] && [ -f "$RECOVERY_KEY_BACKUP_PATH" ]; then
  /bin/rm -f "$RECOVERY_KEY_BACKUP_PATH" 2>/dev/null || true
fi

exit 0
