#!/usr/bin/env bash
# Build a signed Release .app, optional DMG, and SHA256 checksum.
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
SIGN_MODE="${SIGN_MODE:-auto}" # auto | adhoc | unsigned

if ! command -v jq &>/dev/null; then
  echo "❌ jq is required (brew install jq)"
  exit 1
fi

MARKETING="$(jq -r .marketingVersion version.json)"
BUILD_NUM="$(jq -r .buildNumber version.json)"
ARTIFACT_BASE="MagSafeGuard-${MARKETING}"
STAGED_APP="${DIST_DIR}/${ARTIFACT_BASE}.app"
# User-facing .app name inside DMG /Applications (no version in the name).
APP_BUNDLE_NAME="MagSafe Guard.app"
PRODUCTS_DIR="${DERIVED_DATA}/Build/Products/${CONFIGURATION}"
BUILT_APP="${PRODUCTS_DIR}/MagSafeGuard.app"
DMG_PATH="${DIST_DIR}/${ARTIFACT_BASE}.dmg"
CHECKSUMS_FILE="${DIST_DIR}/SHA256SUMS"

log() { echo "$*"; }
die() { echo "❌ $*" >&2; exit 1; }

read_version() {
  MARKETING="$(jq -r .marketingVersion version.json)"
  BUILD_NUM="$(jq -r .buildNumber version.json)"
  ARTIFACT_BASE="MagSafeGuard-${MARKETING}"
  STAGED_APP="${DIST_DIR}/${ARTIFACT_BASE}.app"
  APP_BUNDLE_NAME="MagSafe Guard.app"
  DMG_PATH="${DIST_DIR}/${ARTIFACT_BASE}.dmg"
}

sign_settings() {
  case "$SIGN_MODE" in
    auto)
      SIGN_SETTINGS=""
      ;;
    adhoc)
      SIGN_SETTINGS='CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES'
      ;;
    unsigned)
      SIGN_SETTINGS='CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO'
      ;;
    *)
      die "Unknown SIGN_MODE=$SIGN_MODE (use auto, adhoc, or unsigned)"
      ;;
  esac
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
    [ -d "$resources" ] || return 0
    while IFS= read -r -d '' file; do
      if xattr -l "$file" 2>/dev/null | grep -q .; then
        local tmp="${file}.xattrstrip"
        ditto --norsrc "$file" "$tmp"
        mv "$tmp" "$file"
      fi
    done < <(find "$resources" -type f -print0)
  }
  strip_bundled_resource_xattrs
  xattr -cr "$ROOT/MagSafeGuard" "$ROOT/MagSafeGuardTests" 2>/dev/null || true

  log "📦 Release build — MagSafe Guard ${MARKETING} (build ${BUILD_NUM})"
  log "   Sign mode: ${SIGN_MODE}"
  log "   Output:    ${STAGED_APP}"
  echo ""

  run_xcodebuild

  [ -d "$BUILT_APP" ] || die "Built app not found at $BUILT_APP"

  rm -rf "$STAGED_APP"
  cp -R "$BUILT_APP" "$STAGED_APP"
  xattr -cr "$STAGED_APP" 2>/dev/null || true

  if [ "$SIGN_MODE" != "unsigned" ]; then
    if codesign --verify --deep --verbose=2 "$STAGED_APP" >/dev/null 2>&1; then
      log "✅ Code signature verified"
    else
      log "⚠️  Code signature verification failed (app may still run locally)"
    fi
  fi

  log ""
  log "✅ Staged app: $STAGED_APP"
}

cmd_dmg() {
  read_version
  [ -d "$STAGED_APP" ] || die "Staged app missing — run: task release:build"

  STAGING="${DIST_DIR}/.dmg-staging"
  rm -rf "$STAGING" "$DMG_PATH"
  mkdir -p "$STAGING"
  # Drag-install name must not include the version (Finder / Applications convention).
  cp -R "$STAGED_APP" "${STAGING}/${APP_BUNDLE_NAME}"
  ln -s /Applications "$STAGING/Applications"

  log "💿 Creating DMG: $DMG_PATH"
  hdiutil create \
    -volname "MagSafe Guard ${MARKETING}" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

  rm -rf "$STAGING"
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

cmd_install() {
  read_version
  [ -d "$STAGED_APP" ] || die "Staged app missing — run: task release"

  TARGET="/Applications/${APP_BUNDLE_NAME}"
  log "📲 Installing to $TARGET"
  # Remove prior versioned install names from older packaging.
  rm -rf "$TARGET" /Applications/MagSafeGuard-*.app
  cp -R "$STAGED_APP" "$TARGET"
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
  log "DMG:      ${DMG_PATH}"
  log "Checksum: ${CHECKSUMS_FILE}"
}

cmd_all() {
  cmd_build
  cmd_dmg
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
  checksum   Write dist/SHA256SUMS
  install    Copy staged app to /Applications/MagSafe Guard.app
  open       Open DMG or .app
  show       Print artifact paths
  all        build + dmg + checksum

Environment:
  SIGN_MODE=auto|adhoc|unsigned   (default: auto — Xcode automatic signing)
  SKIP_TESTS=true                 (only used by task release, not this script)
EOF
}

main() {
  local cmd="${1:-all}"
  case "$cmd" in
    build) cmd_build ;;
    dmg) cmd_dmg ;;
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
