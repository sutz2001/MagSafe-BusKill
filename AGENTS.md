# AI agent instructions (canonical)

**Single source of truth** for Cursor, GitHub Copilot, and other agents.

Thin entry points (keep in sync when this file changes):

| Tool | File |
|------|------|
| **Cursor** | [.cursor/rules/project-conventions.mdc](.cursor/rules/project-conventions.mdc) |
| **GitHub Copilot** | [.github/copilot-instructions.md](.github/copilot-instructions.md) |

Path-specific Copilot rules: [.github/instructions/](.github/instructions/) (README, Swift, commits, docs)

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
task run                 # Debug-Build starten
task release             # Release-.app + DMG
task version:show
task version:sync        # after editing version.json
open MagSafeGuard.xcodeproj
```

### Testing & QA

```bash
task test                # SPM tests + coverage
task test:coverage       # explicit coverage report
task qa                  # full quality checks
task qa:quick            # fast pre-commit checks
task qa:full             # full suite incl. SonarCloud
```

CI / local test env (recognized by the test suite):

- `CI=true` — non-interactive mode (no auth dialogs, no real lock/shutdown in tests)
- `SKIP_UI_TESTS=true` — skip UI-dependent tests
- `COVERAGE_THRESHOLD=80` — minimum coverage (default 80)

Protocol-based testing and coverage targets: [docs/maintainers/testing-guide.md](docs/maintainers/testing-guide.md).

---

## Versioning

| Item | Value |
|------|--------|
| Source | `version.json` (`marketingVersion`, `buildNumber`) |
| **Current fork version** | **0.5.9** (build **19**) |
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

## Documentation (required)

Keep **technical and behavioral docs** aligned with the code whenever you ship **substantive** changes (runtime behavior, settings, security/network actions, sync, tests scope, or gap fixes). Do not leave docs describing old behavior after a fix ships.

### When to update

Update docs in the **same commit** as the code when any of these change:

- Application states, grace period, arm/disarm, or trigger flows
- Settings that affect runtime (new toggles, sync fields, defaults)
- Security or network actions, remote URL scheme, auto-arm
- Resolved or new UI/runtime mismatches (behavior gaps)
- User-visible version milestones (bump `version.json` → refresh version lines in feature docs)

Skip doc-only churn for refactors, renames, or internal cleanup that does not change observable behavior.

### What to update (by change type)

| Change | Update at minimum |
|--------|-------------------|
| Behavior / state machine | [docs/features/operating-modes.md](docs/features/operating-modes.md) |
| Gap fixed or new mismatch found | [docs/features/behavior-gaps.md](docs/features/behavior-gaps.md) — move items to **Resolved**, clear **Open** when done |
| Planned vs shipped features | [docs/FORK_ROADMAP.md](docs/FORK_ROADMAP.md) |
| Test priorities / coverage targets | [docs/maintainers/testing-guide.md](docs/maintainers/testing-guide.md) |
| New or moved doc pages | [docs/README.md](docs/README.md) index |
| User-facing features, build, version | [README.md](README.md) + [README.de.md](README.de.md) (see above) |

### Agents should

1. After implementing a fix or feature, ask whether **operating-modes** or **behavior-gaps** is stale; update before finishing.
2. Set **version as of** lines in feature docs when the change is user-facing (e.g. `operating-modes.md` header).
3. Mark gap IDs resolved with a one-line **Resolution** (same style as existing GAP rows).
4. Prefer updating existing docs over adding new files unless the user requests otherwise.

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
- **Cursor injects** `Co-authored-by: Cursor <cursoragent@cursor.com>` when using plain `git commit` — CI will fail and you will get failure emails.

#### How agents must commit (required)

**Do not use `git commit`.** Use `git commit-tree` so no trailer is injected:

```bash
# 1. Stage
git add <files>

# 2. Write tree
TREE=$(git write-tree)

# 3. Commit without trailers (HEREDOC = exact message, no injection)
PARENT=$(git rev-parse HEAD)
COMMIT=$(
  cat <<'EOF' | git commit-tree "$TREE" -p "$PARENT"
<type>(scope): subject

## Summary
Why this change exists.

## Changes
- Bullet list by area
EOF
)
git update-ref refs/heads/main "$COMMIT"
```

Optional verify before push:

```bash
git log -1 --format=%B | grep -qiE 'co-authored|claude|anthropic' && echo "BLOCKED WORDS IN MESSAGE" && exit 1
```

- Already pushed with trailers? Replay commits without the trailer (`git filter-branch` / rebase), then `git push --force-with-lease`.
- Workflow: `.github/workflows/commit-message-check.yml`

When the user asks for a commit: draft the full body first, verify no blocked words, then commit with **commit-tree only**.

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

## Sync upstream (optional reference)

The fork is **independent** — see [docs/FORK_INDEPENDENCE.md](docs/FORK_INDEPENDENCE.md).  
Only merge upstream manually if you explicitly want upstream changes:

```bash
git fetch upstream && git merge upstream/main
```

Preserve fork bundle ID, entitlements, `version.json`, README fork notes, and agent instruction files. **Do not** restore `com.LekmanConsulting.*` or upstream-only CI/docs without review.

---

## AI tooling (Cursor & GitHub Copilot)

This repo uses **one canonical rule file** (this document). Tool-specific entry points are thin stubs only:

| Tool | How rules load | Entry file |
|------|----------------|------------|
| **Cursor** | Project rules (`alwaysApply`) | [.cursor/rules/project-conventions.mdc](.cursor/rules/project-conventions.mdc) |
| **GitHub Copilot** | Repository + path instructions | [.github/copilot-instructions.md](.github/copilot-instructions.md) |

Path-specific Copilot rules: [.github/instructions/](.github/instructions/) (Swift, README, commits, docs).

The `.cursor/` folder is a **dot-directory** — hidden in Finder by default; use `ls -la .cursor/rules/` in Terminal.

**Removed upstream stack (do not restore):** `CLAUDE.md`, `.claude/`, `docs/ai/`, `tasks/ai.yml` — Claude Code CLI / Task Master agents; conflicted with `commit-tree` policy and fork conventions.

---

## Maintaining these rules

When conventions change, update **this file** (`AGENTS.md`) and adjust the thin stubs only if critical inline bullets need to change:

- `.cursor/rules/project-conventions.mdc`
- `.github/copilot-instructions.md`

Do not duplicate long explanations in the stubs — link here instead.
