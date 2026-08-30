# AI agent instructions

Instruction files (**keep in sync**):

| Tool | File |
|------|------|
| **Cursor** | [.cursor/rules/project-conventions.mdc](.cursor/rules/project-conventions.mdc) |
| **GitHub Copilot** | [.github/copilot-instructions.md](.github/copilot-instructions.md) |

Path-specific Copilot rules: [.github/instructions/](.github/instructions/) (README, Swift, commits)

## Commits

Every commit needs an **English body** with `## Summary` and `## Changes` (detailed bullet list). See [.github/instructions/commits.instructions.md](.github/instructions/commits.instructions.md).

**Never** use `Co-authored-by:` trailers — CI fails on `co-authored` (also `claude`, `anthropic`). Strip auto-appended Cursor trailers before commit/push.

## Version

- Edit [`version.json`](version.json) → run `task version:sync`
- Current fork version: **0.2.1** (build 2), separate from upstream 1.11.0
- Show: `task version:show` · Bump: `task version:bump:patch` / `bump:minor`

## Quick facts

- Fork: `sutz2001/MagSafe-BusKill` · upstream: `lekman/magsafe-buskill`
- Docs: [README.md](README.md) · [README.de.md](README.de.md) — update **both** together
- Bundle: `com.sutz2001.MagSafeGuard` · grace period: **30 s**
