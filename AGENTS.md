# AI agent instructions

This repo uses **two instruction files** that must stay **in sync**:

| Tool | File |
|------|------|
| **Cursor** | [.cursor/rules/project-conventions.mdc](.cursor/rules/project-conventions.mdc) |
| **GitHub Copilot** | [.github/copilot-instructions.md](.github/copilot-instructions.md) |

Path-specific Copilot rules: [.github/instructions/](.github/instructions/)

## Quick facts

- Fork: `sutz2001/MagSafe-BusKill` · upstream: `lekman/magsafe-buskill`
- Docs: [README.md](README.md) · [README.de.md](README.de.md) — update **both** when features change
- Build: `task setup` → `open MagSafeGuard.xcodeproj` → ⌘R
- Bundle: `com.sutz2001.MagSafeGuard` · grace period default **30 s**

When changing conventions, edit **Cursor rule + Copilot instructions + both READMEs** as needed.
