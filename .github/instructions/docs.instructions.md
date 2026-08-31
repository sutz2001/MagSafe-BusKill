---
applyTo: "docs/**/*.md,AGENTS.md"
---

# Documentation editing rules

When editing project documentation:

1. **Behavior changes** → update [docs/features/operating-modes.md](../../docs/features/operating-modes.md) (states, flows, settings effects, event log).
2. **Gap fixes or new mismatches** → update [docs/features/behavior-gaps.md](../../docs/features/behavior-gaps.md); move resolved items out of **Open**.
3. **Shipped vs planned work** → align [docs/FORK_ROADMAP.md](../../docs/FORK_ROADMAP.md).
4. **Test backlog** → align [docs/maintainers/testing-guide.md](../../docs/maintainers/testing-guide.md) when coverage priorities change.
5. **New pages** → add a link in [docs/README.md](../../docs/README.md).

User-facing releases: update README EN/DE, `version.json` + `task version:sync`, AGENTS.md current version, and version lines in feature docs (e.g. operating-modes header).

Full policy: [AGENTS.md § Documentation](../../AGENTS.md#documentation-required).

Do not document aspirational behavior as current; mark **planned** features explicitly (e.g. panic mode v0.5.0).
