# GitHub Copilot — repository instructions

**Canonical rules:** [AGENTS.md](../AGENTS.md) — read for full project, versioning, commits, README sync, upstream, and safety.

When conventions change, update **AGENTS.md** first; keep this file as a thin stub unless critical inline bullets need updating.

## Non-negotiable (always apply)

- **README:** update [README.md](../README.md) + [README.de.md](../README.de.md) together
- **Docs:** sync behavior/feature docs with substantive changes — [AGENTS.md § Documentation](../AGENTS.md#documentation-required)
- **Version:** [version.json](../version.json) → `task version:sync`; suggest bump before user-facing commits (see AGENTS.md)
- **Bundle ID:** `com.sutz2001.MagSafeGuard`
- **Commits:** `## Summary` + `## Changes` — [.github/instructions/commits.instructions.md](instructions/commits.instructions.md)
- **Agents: never `git commit`** — use **`git commit-tree`** only ([AGENTS.md](../AGENTS.md#co-authored-by-trailers--do-not-use-ci-will-fail)). No `Co-authored-by`; CI fails on `co-authored`, `claude`, `anthropic`.

## Taskfile

```bash
task setup && task build && task test
task qa:quick            # fast checks before commit
task version:show
task version:sync
```

Path-specific rules: [instructions/swift.instructions.md](instructions/swift.instructions.md), [instructions/commits.instructions.md](instructions/commits.instructions.md), [instructions/readme.instructions.md](instructions/readme.instructions.md), [instructions/docs.instructions.md](instructions/docs.instructions.md).

## Security actions (only five)

`lockScreen`, `soundAlarm`, `forceLogout`, `shutdown`, `customScript`

## Cursor parity

Cursor loads [.cursor/rules/project-conventions.mdc](../.cursor/rules/project-conventions.mdc) — same non-negotiables as this file; details in [AGENTS.md](../AGENTS.md).
