# Future ideas (scratch pad)

**Status:** thought fragments only — **not planned, not committed.**  
Capture rough ideas before they become specs. Remove or promote to [FORK_ROADMAP.md](../FORK_ROADMAP.md) when scope is clear.

---

## LAN trigger from phone (same Wi‑Fi)

**Captured:** 2026-08-31 (Marc)

### Problem

Trigger MagSafe Guard from a **phone** when Mac and phone share the **same LAN** (home, café Wi‑Fi). Use case: panic or arm/disarm without pulling the cable and without a dedicated iOS/Android app.

### What exists today (v0.5.0)

| Approach | Works? | Limitation |
|----------|--------|------------|
| `magsafeguard://panic?token=…` via **Shortcuts** | Yes | Needs Shortcuts automation; URL scheme handling on iOS; not LAN-specific |
| `magsafeguard://trigger` / `arm` | Yes | Same |
| Outbound **webhook** on trigger | Yes | Mac → internet, not phone → Mac |

So remote trigger is already possible from a phone **indirectly** (Shortcuts, another device opening the URL). A smoother “same Wi‑Fi, one tap” flow does **not** exist yet.

### Rough directions (implementation unclear)

**A — Tiny local web page (no phone app)**  
Mac app serves a minimal HTTPS or HTTP page on the LAN (or loopback + Tailscale only):

- e.g. `http://<mac-hostname>.local:PORT/` with arm / panic / status buttons
- Token in header, cookie, or one-time pairing QR in Settings
- Phone uses **Safari** bookmark or home-screen shortcut — no App Store app

**B — Discovery**  
Bonjour / mDNS (`MagSafe-Guard._http._tcp`) so the user does not type IP addresses. Settings show QR code → opens trigger page.

**C — Inbound polling (already on old roadmap)**  
Mac polls a cloud or home-server endpoint (“phone pressed button”); phone only talks to that server. Works across networks but adds infrastructure; different threat model.

**D — Native companion app**  
Explicitly **de-prioritized** for now — high cost, two codebases, store policies.

### Open questions

- Bind to **LAN only** vs **localhost + VPN** (Tailscale) — exposure if café Wi‑Fi is hostile
- **HTTPS** on local network (self-signed pain) vs token-only over HTTP on trusted home LAN
- **Rate limiting** and **pairing** so random LAN clients cannot trigger
- macOS **sandbox / firewall** prompts; Personal Team entitlements
- Panic vs normal arm — same auth model as URL scheme (panic only when panic-armed)
- Relation to **Paranoid** (v0.6) — likely same inbound channel, stricter pairing

### Non-goals (for this sketch)

- No commitment to ship in any version
- Not a replacement for cable / hotkey / `magsafeguard://` — an optional convenience layer

### If promoted later

Update [FORK_ROADMAP.md](../FORK_ROADMAP.md), [panic-modes.md](panic-modes.md) (triggers), security review, and user guide.

---

*Add new sections below as one-off ideas. Keep each block short.*
