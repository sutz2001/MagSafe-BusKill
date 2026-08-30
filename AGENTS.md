# AI agent instructions (canonical)

**Single source of truth** for Cursor, GitHub Copilot, and other agents.

Thin entry points (keep in sync when this file changes):

| Tool | File |
|------|------|
| **Cursor** | [.cursor/rules/project-conventions.mdc](.cursor/rules/project-conventions.mdc) |
| **GitHub Copilot** | [.github/copilot-instructions.md](.github/copilot-instructions.md) |

Path-specific Copilot rules: [.github/instructions/](.github/instructions/) (README, Swift, commits)

---

## Project

**MagSafe Guard** — macOS menu bar security app (dead-man's switch on power disconnect).

- Fork: `sutz2001/MagSafe-BusKill` · Upstream: `lekman/magsafe-buskill`
- Bundle ID: `com.sutz2001.MagSafeGuard` — never restore `com.LekmanConsulting.*` or team `PW6K4BERFV`
- Personal Team: no iCloud/Push in `MagSafeGuard/MagSafeGuard.entitlements`
- Grace period default: **30 s**
- Config statics: `.defaultConfig` not `.default`

User docs: [README.md](README.md) (EN) · [README.de.md](README.de.md) (DE)

---

## Taskfile first

Prefer `task` over raw tool commands:

```bash
task setup && task build && task test
task version:show
task version:sync    # after editing version.json
open MagSafeGuard.xcodeproj
```

---

## Versioning

| Item | Value |
|------|--------|
| Source | `version.json` (`marketingVersion`, `buildNumber`) |
| **Current fork version** | **0.3.0** (build **3**) |
| Upstream (reference only) | `1.11.0` — fork semver is independent |
| Sync | `task version:sync` → `AppVersion.swift` + Xcode `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` |
| Show | `task version:show` |
| Patch bump | `task version:bump:patch` (e.g. 0.2.1 → 0.2.2) — fixes, small changes |
| Minor bump | `task version:bump:minor` (e.g. 0.2.1 → 0.3.0) — new features |

### When to bump (agents should suggest proactively)

Before a commit that ships **user-visible** changes (UI, behavior, assets, localization):

1. **Suggest** a version bump to the user if `version.json` was not updated yet.
2. Use **patch** for fixes and small tweaks; **minor** for new features.
3. Run `task version:sync` in the same commit as the `version.json` change.
4. Update the version table in **README.md** and **README.de.md** (`marketingVersion` row).
5. Update the **Current fork version** line in this file (`AGENTS.md`).

Do not bump version for docs-only or CI-only changes unless the user asks.

---

## README (required)

- **English:** `README.md` (primary)
- **German:** `README.de.md` (must stay in sync)
- Cross-link at the top of both files
- When changing features, defaults, actions, build steps, or fork-specific settings → update **both** READMEs in the same commit

---

## Every commit (required)

English body with `## Summary` and `## Changes`. Full format: [.github/instructions/commits.instructions.md](.github/instructions/commits.instructions.md).

```text
<type>(scope): subject

## Summary
Why this change exists.

## Changes
- Bullet list by area (App, Docs, CI, Assets, Tests, …)
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `build`

### Co-authored-by trailers — do not use (CI will fail)

- **Never** add `Co-authored-by:` lines — not for Cursor, Copilot, or any tool.
- CI blocks these substrings anywhere in the message (case-insensitive): `claude`, `anthropic`, `co-authored`.
- That includes the commit **subject** and **body** — do not write “co-authored” even when documenting the rule in a commit message.
- Cursor may auto-append `Co-authored-by: Cursor <cursoragent@cursor.com>` — strip before commit or use `git commit-tree` to avoid trailer injection.
- Already pushed? Replay commits without the trailer, then `git push --force-with-lease`.
- Workflow: `.github/workflows/commit-message-check.yml`

When the user asks for a commit: draft the full body first, verify no blocked words, then commit.

---

## Security actions (only these five)

`lockScreen`, `soundAlarm`, `forceLogout`, `shutdown`, `customScript`

No ad-hoc system actions outside `SecurityActionType` / repository layer.

---

## Safety

- Do not run/build the armed app without user intent
- No secrets in commits
- Do not add iCloud entitlements without noting paid Apple Developer Program requirement

---

## Sync upstream

```bash
git fetch upstream && git merge upstream/main
```

Preserve fork bundle ID, entitlements, `version.json`, README fork notes, and agent instruction files.

---

## Maintaining these rules

When conventions change, update **this file** (`AGENTS.md`) and adjust the thin stubs only if critical inline bullets need to change:

- `.cursor/rules/project-conventions.mdc`
- `.github/copilot-instructions.md`

Do not duplicate long explanations in the stubs — link here instead.
