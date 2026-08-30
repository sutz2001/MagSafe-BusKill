---
applyTo: "**/*"
---

# Commit message rules (agents & humans)

Every commit MUST use this structure. **Body in English.**

```text
<type>(<optional scope>): <short subject — max 72 chars>

## Summary
One or two sentences: why this change exists.

## Changes
- Grouped bullet list of every meaningful change
- Use areas: App, UI, CI, Docs, Assets, Tests, Config, etc.
- Mention files or modules when helpful
- Include version bump if `version.json` changed

## Notes (optional)
- Breaking changes, follow-ups, or testing done
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `build`

**Blocked by CI:** `claude`, `anthropic`, `co-authored` in commit messages.

When the user asks for a commit, always draft the full body with `## Summary` and `## Changes` before running `git commit`.
