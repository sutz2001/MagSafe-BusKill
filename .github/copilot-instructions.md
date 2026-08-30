# GitHub Copilot — repository instructions

> **Keep in sync with:** `.cursor/rules/project-conventions.mdc`  
> When you change project conventions, defaults, or agent rules, update **both** files in the same commit.

## Project

**MagSafe Guard** — macOS menu bar security app (dead-man's switch on power disconnect).  
Fork: `sutz2001/MagSafe-BusKill` · Upstream: `lekman/magsafe-buskill`.

User docs: [README.md](../README.md) (EN) · [README.de.md](../README.de.md) (DE) — **always update both** when behavior, defaults, or build steps change.

## Taskfile first

```bash
task setup && task build && task test
task version:show
task version:sync    # after editing version.json
open MagSafeGuard.xcodeproj
```

## Fork-specific (do not revert)

| Setting | Value |
|---------|--------|
| Bundle ID | `com.sutz2001.MagSafeGuard` |
| Version file | `version.json` → `task version:sync` |
| Current fork version | `0.2.1` (independent from upstream `1.11.0`) |
| Grace period default | **30 s** |
| Config statics | `.defaultConfig` not `.default` |

## Versioning

- **Source:** `version.json` (`marketingVersion`, `buildNumber`)
- **Sync:** `task version:sync` → `AppVersion.swift` + Xcode project
- **Bump:** `task version:bump:patch` (0.2.0→0.2.1) or `task version:bump:minor` (0.2.0→0.3.0)
- **Semver (fork):** `0.MINOR.PATCH` until `1.0.0` stable; patch=fixes, minor=features

## Every commit (required)

English commit body with full change list. Format:

```text
<type>(scope): subject

## Summary
Why.

## Changes
- Detailed bullets by area (App, Docs, CI, Assets, Tests, …)
```

Details: `.github/instructions/commits.instructions.md`

### No `Co-authored-by` trailers (CI will fail)

- **Never** add `Co-authored-by:` lines — not for Cursor, Copilot, or any assistant.
- CI blocks anywhere in the message (case-insensitive): `claude`, `anthropic`, `co-authored`.
- Cursor may auto-append `Co-authored-by: Cursor <cursoragent@cursor.com>` — remove it before push.
- Already pushed? Replay commits without the trailer, then `git push --force-with-lease`.

## Security actions (only these five)

`lockScreen`, `soundAlarm`, `forceLogout`, `shutdown`, `customScript`

## Safety

- Never suggest running the app when armed without user intent
- No secrets in commits

## Sync upstream

```bash
git fetch upstream && git merge upstream/main
```

Preserve fork bundle ID, entitlements, `version.json`, and README fork notes.
