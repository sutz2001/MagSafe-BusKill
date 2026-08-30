---
applyTo: "README.md,README.de.md,docs/README.md,MagSafeGuard/README.md"
---

# README editing rules

When editing any project README:

1. Update **README.md** (English) and **README.de.md** (German) together in the same commit
2. Keep the language switch link at the top of both files
3. Feature status tables must match between languages
4. Document fork-specific values: bundle `com.sutz2001.MagSafeGuard`, grace period **30 s**, Personal Team signing limits
5. Security actions: only the five implemented types (see root README)
6. Do not re-add Taskmaster export blocks to README.md

Also update [AGENTS.md](../AGENTS.md) when conventions change (canonical source).
If `version.json` changes, run `task version:sync` and update README version tables + AGENTS.md current version in the same commit.
