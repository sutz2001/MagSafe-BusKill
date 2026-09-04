# Legal review gate — Paranoid (v0.6)

> **Not legal advice.** Maintainer process for Paranoid mode risk communication. Record sign-off on [GitHub issue #16](https://github.com/sutz2001/MagSafe-BusKill/issues/16) or below.

## Status

| Item | Status |
|------|--------|
| Feature code (M1–M6) | Shipped in **0.6.0** |
| In-app disclaimer (EN + DE) | Shipped |
| Informed self-review (BusKill-aligned) | **Done** — 2026-09-04 (v0.6.1) |
| Formal lawyer (DE/EU) | Optional — only before commercial / App Store–scale distribution |

## How BusKill handles kill-code

[BusKill](https://www.buskill.in/) ships **non-destructive** triggers by default (lock / shutdown). Self-destruct is **not in the app**:

- Destructive triggers live in **docs / advanced guides** only ([Destructive Triggers](https://docs.buskill.in/buskill-app/en/font_setting/software_usr/destructive.html), [LUKS Header Shredder](https://www.buskill.in/luks-self-destruct/)).
- Guides lead with experimental warnings and: authors **cannot be responsible** for data loss; leave if that is a concern.
- Intentional **high barrier**: false positives must not wipe casual users.

MagSafe Guard takes a different product choice — Paranoid is **in-app** — so the barrier is **UX friction**, not “docs only”:

| Guardrail | BusKill self-destruct | MagSafe Guard Paranoid |
|-----------|----------------------|-------------------------|
| In product by default | No | Opt-in feature (off until setup) |
| Risk text | Guide disclaimer | Full legal notice EN + DE |
| Confirmations | Manual udev / scripts | Codeword + double confirm + auth |
| Work / shared device | Implicit (advanced users) | Explicit employer warning |
| Limits honesty | Experimental / data loss | APFS / TRIM / non-forensic stated in UI |

For an open-source personal-use fork, **strong in-app warnings + opt-in gates** match BusKill’s risk posture more closely than waiting on a formal legal opinion. A paid lawyer review remains recommended before advertising a wide public consumer beta or App Store distribution.

## Checklist

- [x] Informed self-review (DE/EU consumer context; compared to BusKill approach)
- [x] Full paranoid disclaimer text reviewed in app (EN + DE) — irreversible loss, APFS limits, work-device warning
- [x] Work-device / employer warning prominent in setup + legal UI
- [x] Beta / release notes mention irreversible data loss and honest limits
- [x] Sign-off recorded (issue #16 + this log)
- [ ] Formal lawyer review — deferred until commercial / wide public consumer push

## Sign-off log

| Date | Reviewer | Notes |
|------|----------|-------|
| 2026-09-04 | Maintainer (`sutz2001`) | Informed self-review. Warnings + gates sufficient for personal / OSS beta. Formal counsel optional later. |

## References

- [panic-modes.md — Legal notices](../features/panic-modes.md#legal-notices)
- [FORK_ROADMAP.md — Phase 2d / M7](../FORK_ROADMAP.md)
- Issue [#16](https://github.com/sutz2001/MagSafe-BusKill/issues/16)
- BusKill: [destructive triggers](https://docs.buskill.in/buskill-app/en/font_setting/software_usr/destructive.html), [LUKS shredder](https://www.buskill.in/luks-self-destruct/)
