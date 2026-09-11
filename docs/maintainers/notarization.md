# Notarization (Developer ID)

Paid Apple Developer Program → **Developer ID Application** certificate → sign → notarize → staple.

Team ID for this fork: **`7FPM58LVXH`** · Bundle ID: `com.sutz2001.MagSafeGuard`

> Not legal advice. Keep the Developer ID private key backed up (export `.p12`).

## One-time setup

### 1. Developer ID Application certificate

Account Holder only (you, if you enrolled personally):

1. Xcode → **Settings → Accounts** → your Apple ID → select team **7FPM58LVXH**
2. **Manage Certificates…** → **+** → **Developer ID Application**
3. Confirm:

```bash
security find-identity -v -p codesigning | grep "Developer ID Application"
```

### 2. App-specific password + notarytool profile

1. [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → **App-Specific Passwords** → create one (e.g. `MagSafeGuard-notary`)
2. Store credentials (once):

```bash
xcrun notarytool store-credentials "MagSafeGuard-notary" \
  --apple-id "YOUR_APPLE_ID@email" \
  --team-id "7FPM58LVXH" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

Verify:

```bash
xcrun notarytool history --keychain-profile MagSafeGuard-notary
```

## Release (signed + notarized DMG)

```bash
SIGN_MODE=developerid task release:package
# or full publish (runs tests unless SKIP_TESTS=true):
SIGN_MODE=developerid SKIP_TESTS=true task release
```

`SIGN_MODE=developerid` builds unsigned in Xcode (avoids `com.apple.provenance` codesign failures), re-signs with Developer ID + hardened runtime using [`MagSafeGuard.developerid.entitlements`](../../MagSafeGuard/MagSafeGuard.developerid.entitlements) (sandbox **off** for system actions), creates an HFS+ DMG, notarizes app + DMG, staples tickets, writes `dist/SHA256SUMS`.

Skip notarization (sign only):

```bash
SIGN_MODE=developerid NOTARIZE=0 bash scripts/package-release.sh all
```

Notarize existing artifacts:

```bash
task release:notarize
# or: bash scripts/notarize-release.sh all
```

## Install / verify

```bash
task release:install
spctl -a -vv "/Applications/MagSafe Guard.app"
codesign -dv --verbose=4 "/Applications/MagSafe Guard.app" 2>&1 | head -20
```

## GitHub Release

```bash
gh release upload vX.Y.Z dist/MagSafeGuard-X.Y.Z.dmg dist/SHA256SUMS --clobber
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| No Developer ID identity | Create cert in Xcode (step 1) |
| `No Keychain password item found for profile` | Run `notarytool store-credentials` (step 2) |
| Notary rejected: invalid signature | Ensure `--options runtime --timestamp` and nested frameworks signed |
| Gatekeeper still warns | Staple failed or wrong download; re-run `stapler staple` on DMG |
| Xcode Release codesign fails on provenance | Expected — use `SIGN_MODE=developerid` (unsigned build + re-sign) |

Related: [code-signing.md](code-signing.md) (broader / partly historical), [`scripts/package-release.sh`](../../scripts/package-release.sh), [`scripts/notarize-release.sh`](../../scripts/notarize-release.sh).
