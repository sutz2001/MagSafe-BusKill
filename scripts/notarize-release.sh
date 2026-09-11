#!/usr/bin/env bash
# Notarize and staple a MagSafe Guard .app and/or .dmg with notarytool.
# Requires: Developer ID–signed artifacts + keychain profile (see docs/maintainers/notarization.md).
#
# Usage:
#   bash scripts/notarize-release.sh app [path-to.app]
#   bash scripts/notarize-release.sh dmg [path-to.dmg]
#   bash scripts/notarize-release.sh all   # versioned app + dmg under dist/
#
# Env:
#   NOTARY_PROFILE   keychain profile name (default: MagSafeGuard-notary)
#   DIST_DIR         (default: dist)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DIST_DIR="${DIST_DIR:-dist}"
NOTARY_PROFILE="${NOTARY_PROFILE:-MagSafeGuard-notary}"
MARKETING="$(jq -r .marketingVersion version.json)"
ARTIFACT_BASE="MagSafeGuard-${MARKETING}"
DEFAULT_APP="${DIST_DIR}/${ARTIFACT_BASE}.app"
DEFAULT_DMG="${DIST_DIR}/${ARTIFACT_BASE}.dmg"

log() { echo "$*"; }
die() { echo "❌ $*" >&2; exit 1; }

require_notary_profile() {
  if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    die "Notary keychain profile '$NOTARY_PROFILE' missing.

Create an app-specific password at https://appleid.apple.com → Sign-In and Security → App-Specific Passwords,
then run:

  xcrun notarytool store-credentials \"$NOTARY_PROFILE\" \\
    --apple-id \"YOUR_APPLE_ID@email\" \\
    --team-id \"7FPM58LVXH\" \\
    --password \"xxxx-xxxx-xxxx-xxxx\"

Docs: docs/maintainers/notarization.md"
  fi
}

notarize_zip_submit() {
  local zip_path="$1"
  log "☁️  Submitting to Apple notary service (profile: $NOTARY_PROFILE)…"
  xcrun notarytool submit "$zip_path" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
}

cmd_app() {
  local app_path="${1:-$DEFAULT_APP}"
  [ -d "$app_path" ] || die "App not found: $app_path"
  require_notary_profile

  local zip_path
  zip_path="$(mktemp -t MagSafeGuard-notary).zip"
  log "📦 Zipping for notarization: $app_path"
  ditto -c -k --keepParent "$app_path" "$zip_path"
  notarize_zip_submit "$zip_path"
  rm -f "$zip_path"

  log "📎 Stapling ticket onto app…"
  xcrun stapler staple "$app_path"
  xcrun stapler validate "$app_path"
  log "✅ App notarized and stapled: $app_path"
}

cmd_dmg() {
  local dmg_path="${1:-$DEFAULT_DMG}"
  [ -f "$dmg_path" ] || die "DMG not found: $dmg_path"
  require_notary_profile

  notarize_zip_submit "$dmg_path"

  log "📎 Stapling ticket onto DMG…"
  xcrun stapler staple "$dmg_path"
  xcrun stapler validate "$dmg_path"
  log "✅ DMG notarized and stapled: $dmg_path"
}

cmd_all() {
  cmd_app "$DEFAULT_APP"
  cmd_dmg "$DEFAULT_DMG"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <app|dmg|all> [path]

Env:
  NOTARY_PROFILE=$NOTARY_PROFILE
EOF
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    app) shift; cmd_app "${1:-}" ;;
    dmg) shift; cmd_dmg "${1:-}" ;;
    all) cmd_all ;;
    -h|--help|help|"") usage; exit 1 ;;
    *) die "Unknown command: $cmd" ;;
  esac
}

main "$@"
