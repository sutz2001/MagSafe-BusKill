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

**Blocked by CI** (anywhere in the message, case-insensitive): `claude`, `anthropic`, `co-authored`

Do **not** use those strings even in commit subjects (e.g. avoid “co-authored rules” as a subject).

### `Co-authored-by` — do not use

Full policy: [AGENTS.md](../../AGENTS.md)

- Do **not** add `Co-authored-by:` trailers (including `Co-authored-by: Cursor <cursoragent@cursor.com>`).
- Cursor and some tools append them automatically — remove before `git commit` / before push.
- Workflow: `.github/workflows/commit-message-check.yml`
- Fix pushed commits: replay commits without the trailer (e.g. `git commit-tree`), then `git push --force-with-lease`.

When the user asks for a commit, always draft the full body with `## Summary` and `## Changes` before running `git commit`.
