# Fork independence (sutz2001)

## Is this still connected to the original?

**Your development is independent.** The fork adds its own commits on top of the upstream history it inherited at fork time.

| Question | Answer |
|----------|--------|
| Who owns `main` now? | **You** — [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill) |
| Commits ahead of upstream? | **Yes** — fork-only work (0.2.x → 0.4.x) |
| Commits behind upstream? | **No** (as of fork point) — no automatic sync |
| Why does GitHub show `lekman` commits? | **Inherited history** — normal for forks; not active development |
| Why do some folders say “last year”? | **Unchanged since fork** — not proof of a live link |

### What is *not* a live connection

- Old commits in the history graph
- Folders with old “last modified” dates (`.codecov.yml`, `.env.example`, etc.)
- MIT license / NOTICE attribution to upstream (required, not operational)

### Optional reference only

A local `upstream` remote (`lekman/magsafe-buskill`) may exist for **manual** cherry-picks. The fork does **not** auto-merge upstream. See [AGENTS.md](../AGENTS.md) if you ever want to compare.

### Fork-specific identifiers

| Item | Fork value |
|------|------------|
| Bundle ID | `com.sutz2001.MagSafeGuard` |
| Version | `version.json` (independent semver, e.g. 0.4.x) |
| Releases | [FORK_CHANGELOG.md](FORK_CHANGELOG.md) + GitHub Releases on **sutz2001** |

### Legacy technical debt (harmless, not upstream sync)

Some internal keys still use `com.lekman.*` prefixes (UserDefaults, Keychain service names) from the inherited codebase. They are **local storage namespaces**, not network links to upstream. Migration to `com.sutz2001.*` can be a future cleanup if settings reset is acceptable.
