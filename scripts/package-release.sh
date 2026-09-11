#!/usr/bin/env bash
# Build a signed Release .app, optional DMG, checksum, and optional notarization.
# Used by: task release, task release:build, task release:dmg, …
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_PATH="${PROJECT_PATH:-MagSafeGuard.xcodeproj}"
SCHEME="${SCHEME:-MagSafeGuard}"
CONFIGURATION="${CONFIGURATION:-Release}"
DESTINATION="${DESTINATION:-platform=macOS}"
DIST_DIR="${DIST_DIR:-dist}"
DERIVED_DATA="${DERIVED_DATA:-$DIST_DIR/DerivedData}"
# auto | adhoc | unsigned | developerid
SIGN_MODE="${SIGN_MODE:-auto}"
NOTARY_PROFILE="${NOTARY_PROFILE:-MagSafeGuard-notary}"
DEVELOPER_ID_ENTITLEMENTS="${DEVELOPER_ID_ENTITLEMENTS:-$ROOT/MagSafeGuard/MagSafeGuard.developerid.entitlements}"
# After developerid build: also notarize app+dmg when NOTARIZE=1 (default for developerid).
NOTARIZE="${NOTARIZE:-}"

if ! command -v jq &>/dev/null; then
  echo "❌ jq is required (brew install jq)"
  exit 1
fi

MARKETING="$(jq -r .marketingVersion version.json)"
BUILD_NUM="$(jq -r .buildNumber version.json)"
ARTIFACT_BASE="MagSafeGuard-${MARKETING}"
STAGED_APP="${DIST_DIR}/${ARTIFACT_BASE}.app"
# User-facing .app name inside DMG / Applications (no version in the name).
APP_BUNDLE_NAME="MagSafe Guard.app"
PRODUCTS_DIR="${DERIVED_DATA}/Build/Products/${CONFIGURATION}"
BUILT_APP="${PRODUCTS_DIR}/MagSafeGuard.app"
DMG_PATH="${DIST_DIR}/${ARTIFACT_BASE}.dmg"
CHECKSUMS_FILE="${DIST_DIR}/SHA256SUMS"
FRIENDLY_APP="${DIST_DIR}/${APP_BUNDLE_NAME}"

log() { echo "$*"; }
die() { echo "❌ $*" >&2; exit 1; }

read_version() {
  MARKETING="$(jq -r .marketingVersion version.json)"
  BUILD_NUM="$(jq -r .buildNumber version.json)"
  ARTIFACT_BASE="MagSafeGuard-${MARKETING}"
  STAGED_APP="${DIST_DIR}/${ARTIFACT_BASE}.app"
  APP_BUNDLE_NAME="MagSafe Guard.app"
  FRIENDLY_APP="${DIST_DIR}/${APP_BUNDLE_NAME}"
  DMG_PATH="${DIST_DIR}/${ARTIFACT_BASE}.dmg"
}

find_developer_id_identity() {
  local id
  id="$(security find-identity -v -p codesigning 2>/dev/null | grep -F 'Developer ID Application' | head -1 | awk '{print $2}')"
  [ -n "$id" ] || die "No 'Developer ID Application' certificate in Keychain.

Create one (Account Holder):
  Xcode → Settings → Accounts → your Apple ID → Manage Certificates… → + → Developer ID Application

Team ID expected: 7FPM58LVXH
Docs: docs/maintainers/notarization.md"
  echo "$id"
}

sign_settings() {
  case "$SIGN_MODE" in
    auto)
      SIGN_SETTINGS=""
      ;;
    adhoc)
      SIGN_SETTINGS='CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES'
      ;;
    unsigned|developerid)
      # Build unsigned (avoids Xcode codesign failures on com.apple.provenance),
      # then re-sign below for developerid.
      SIGN_SETTINGS='CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO'
      ;;
    *)
      die "Unknown SIGN_MODE=$SIGN_MODE (use auto, adhoc, unsigned, or developerid)"
      ;;
  esac
}

strip_xattrs_tree() {
  local root="$1"
  [ -d "$root" ] || return 0
  # Rewrite files that carry sticky provenance; then clear remaining xattrs.
  while IFS= read -r -d '' file; do
    if xattr -l "$file" 2>/dev/null | grep -q .; then
      python3 -c "from pathlib import Path; p=Path(r'''$file'''); p.write_bytes(p.read_bytes())" 2>/dev/null || true
    fi
  done < <(find "$root" -type f -print0 2>/dev/null)
  xattr -cr "$root" 2>/dev/null || true
}

run_xcodebuild() {
  if command -v xcbeautify &>/dev/null; then
  # shellcheck disable=SC2086
    xcodebuild build \
      -project "$PROJECT_PATH" \
      -scheme "$SCHEME" \
      -configuration "$CONFIGURATION" \
      -destination "$DESTINATION" \
      -derivedDataPath "$DERIVED_DATA" \
      $SIGN_SETTINGS \
      2>&1 | xcbeautify --quiet --is-ci
  else
    log "⚠️  xcbeautify not found — plain xcodebuild output"
  # shellcheck disable=SC2086
    xcodebuild build \
      -project "$PROJECT_PATH" \
      -scheme "$SCHEME" \
      -configuration "$CONFIGURATION" \
      -destination "$DESTINATION" \
      -derivedDataPath "$DERIVED_DATA" \
      $SIGN_SETTINGS
  fi
}

codesign_developer_id_app() {
  local app_path="$1"
  local identity
  identity="$(find_developer_id_identity)"
  [ -f "$DEVELOPER_ID_ENTITLEMENTS" ] || die "Missing entitlements: $DEVELOPER_ID_ENTITLEMENTS"

  log "🔏 Developer ID signing: $identity"

  # Fresh copy without resource forks / AppleDouble (codesign rejects them).
  local clean
  clean="$(mktemp -d)/MagSafeGuard-sign.app"
  rm -rf "$clean"
  ditto --norsrc "$app_path" "$clean"
  find "$clean" \( -name '._*' -o -name '.DS_Store' \) -delete
  dot_clean -m "$clean" 2>/dev/null || true
  xattr -cr "$clean" 2>/dev/null || true

  # Sign nested frameworks inside-out (avoid --deep).
  if [ -d "$clean/Contents/Frameworks" ]; then
    local fw
    while IFS= read -r -d '' fw; do
      codesign --force --options runtime --timestamp --sign "$identity" "$fw"
    done < <(find "$clean/Contents/Frameworks" -maxdepth 1 -name '*.framework' -print0)
  fi

  codesign --force --options runtime --timestamp \
    --entitlements "$DEVELOPER_ID_ENTITLEMENTS" \
    --sign "$identity" \
    "$clean"

  codesign --verify --deep --strict --verbose=2 "$clean"

  rm -rf "$app_path"
  ditto --norsrc "$clean" "$app_path"
  rm -rf "$(dirname "$clean")"
  log "✅ Developer ID signature verified"
}

cmd_build() {
  read_version
  sign_settings

  if ! command -v xcodebuild &>/dev/null; then
    die "xcodebuild not found — install Xcode"
  fi

  mkdir -p "$DIST_DIR"

  # Extended attributes (e.g. com.apple.provenance on bundled assets) break Release codesign.
  strip_bundled_resource_xattrs() {
    local resources="$ROOT/MagSafeGuard/Resources"
    local assets="$ROOT/MagSafeGuard/Assets.xcassets"
    for dir in "$resources" "$assets"; do
      [ -d "$dir" ] || continue
      while IFS= read -r -d '' file; do
        if xattr -l "$file" 2>/dev/null | grep -q .; then
          local tmp="${file}.xattrstrip"
          ditto --norsrc "$file" "$tmp"
          mv "$tmp" "$file"
        fi
      done < <(find "$dir" -type f -print0)
    done
  }
  strip_bundled_resource_xattrs
  strip_xattrs_tree "$ROOT/MagSafeGuard"
  strip_xattrs_tree "$ROOT/MagSafeGuardTests"

  if [ "$SIGN_MODE" = "developerid" ]; then
    # Fail early if cert missing.
    find_developer_id_identity >/dev/null
    if [ -z "${NOTARIZE}" ]; then
      NOTARIZE=1
    fi
  fi

  log "📦 Release build — MagSafe Guard ${MARKETING} (build ${BUILD_NUM})"
  log "   Sign mode: ${SIGN_MODE}"
  log "   Output:    ${STAGED_APP}"
  echo ""

  run_xcodebuild

  [ -d "$BUILT_APP" ] || die "Built app not found at $BUILT_APP"

  rm -rf "$STAGED_APP" "$FRIENDLY_APP"
  # Clean copy without resource forks.
  ditto --norsrc "$BUILT_APP" "$STAGED_APP"
  strip_xattrs_tree "$STAGED_APP"

  if [ "$SIGN_MODE" = "developerid" ]; then
    codesign_developer_id_app "$STAGED_APP"
  elif [ "$SIGN_MODE" != "unsigned" ]; then
    if codesign --verify --deep --verbose=2 "$STAGED_APP" >/dev/null 2>&1; then
      log "✅ Code signature verified"
    else
      log "⚠️  Code signature verification failed (app may still run locally)"
    fi
  fi

  ditto --norsrc "$STAGED_APP" "$FRIENDLY_APP"
  if [ "$SIGN_MODE" = "developerid" ]; then
    # Keep friendly copy identically signed (re-sign after copy).
    codesign_developer_id_app "$FRIENDLY_APP"
  fi

  log ""
  log "✅ Staged app: $STAGED_APP"
  log "✅ Friendly app: $FRIENDLY_APP"
}

cmd_dmg() {
  read_version
  [ -d "$STAGED_APP" ] || die "Staged app missing — run: task release:build"

  STAGING="${DIST_DIR}/.dmg-staging"
  rm -rf "$STAGING" "$DMG_PATH"
  mkdir -p "$STAGING"
  # Drag-install name must not include the version (Finder / Applications convention).
  ditto --norsrc "$STAGED_APP" "${STAGING}/${APP_BUNDLE_NAME}"
  ln -s /Applications "$STAGING/Applications"

  log "💿 Creating DMG: $DMG_PATH"
  # HFS+ so Finder reliably shows MagSafe Guard.app (default APFS images often look empty).
  hdiutil create \
    -volname "MagSafe Guard ${MARKETING}" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "$DMG_PATH" >/dev/null

  rm -rf "$STAGING"

  # Optionally sign the DMG with Developer ID (helps Gatekeeper on the disk image).
  if [ "$SIGN_MODE" = "developerid" ]; then
    local identity
    identity="$(find_developer_id_identity)"
    codesign --force --timestamp --sign "$identity" "$DMG_PATH" || \
      log "⚠️  DMG codesign skipped/failed (app inside is still signed)"
  fi

  log "✅ DMG: $DMG_PATH (contains ${APP_BUNDLE_NAME})"
}

cmd_checksum() {
  read_version
  mkdir -p "$DIST_DIR"
  : >"$CHECKSUMS_FILE"

  if [ -f "$DMG_PATH" ]; then
    shasum -a 256 "$DMG_PATH" >>"$CHECKSUMS_FILE"
  elif [ -d "$STAGED_APP" ]; then
    ZIP_PATH="${DIST_DIR}/${ARTIFACT_BASE}.zip"
    ditto -c -k --keepParent "$STAGED_APP" "$ZIP_PATH"
    shasum -a 256 "$ZIP_PATH" >>"$CHECKSUMS_FILE"
  fi

  [ -s "$CHECKSUMS_FILE" ] || die "No artifacts to checksum"
  log "✅ Checksums: $CHECKSUMS_FILE"
  cat "$CHECKSUMS_FILE"
}

cmd_notarize() {
  read_version
  bash "$ROOT/scripts/notarize-release.sh" all
}

cmd_install() {
  read_version
  [ -d "$STAGED_APP" ] || die "Staged app missing — run: task release"

  TARGET="/Applications/${APP_BUNDLE_NAME}"
  log "📲 Installing to $TARGET"
  # Remove prior versioned install names from older packaging.
  rm -rf "$TARGET" /Applications/MagSafeGuard-*.app
  ditto --norsrc "$STAGED_APP" "$TARGET"
  log "✅ Installed — launch from Applications or Spotlight"
}

cmd_open() {
  read_version
  if [ -f "$DMG_PATH" ]; then
    open "$DMG_PATH"
  elif [ -d "$STAGED_APP" ]; then
    open "$STAGED_APP"
  else
    die "No release artifacts — run: task release"
  fi
}

cmd_show() {
  read_version
  log "Version:  ${MARKETING} (build ${BUILD_NUM})"
  log "App:      ${STAGED_APP}"
  log "Friendly: ${FRIENDLY_APP}"
  log "DMG:      ${DMG_PATH}"
  log "Checksum: ${CHECKSUMS_FILE}"
  log "Sign mode:${SIGN_MODE}"
}

cmd_all() {
  cmd_build
  cmd_dmg
  if [ "${NOTARIZE:-0}" = "1" ] || [ "${NOTARIZE:-}" = "true" ]; then
    cmd_notarize
  fi
  cmd_checksum
  echo ""
  cmd_show
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  build      Release xcodebuild → dist/MagSafeGuard-<version>.app
  dmg        Create DMG containing "MagSafe Guard.app" (no version in app name)
  notarize   Notarize + staple staged app and DMG (notarytool)
  checksum   Write dist/SHA256SUMS
  install    Copy staged app to /Applications/MagSafe Guard.app
  open       Open DMG or .app
  show       Print artifact paths
  all        build + dmg (+ notarize if NOTARIZE=1) + checksum

Environment:
  SIGN_MODE=auto|adhoc|unsigned|developerid
      default: auto — Xcode automatic signing
      developerid — unsigned xcodebuild, then Developer ID + hardened runtime
  NOTARIZE=1                 notarize after dmg (default on for SIGN_MODE=developerid)
  NOTARY_PROFILE=name        notarytool keychain profile (default: MagSafeGuard-notary)
  SKIP_TESTS=true            (only used by task release, not this script)
EOF
}

main() {
  local cmd="${1:-all}"
  case "$cmd" in
    build) cmd_build ;;
    dmg) cmd_dmg ;;
    notarize) cmd_notarize ;;
    checksum) cmd_checksum ;;
    install) cmd_install ;;
    open) cmd_open ;;
    show) cmd_show ;;
    all) cmd_all ;;
    -h|--help|help) usage ;;
    *) die "Unknown command: $cmd (try --help)" ;;
  esac
}

main "$@"
