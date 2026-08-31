# Fork-Roadmap (sutz2001)

Planung für [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).  
Stand: nach **0.4.0** (August 2026). Release-Historie: [FORK_CHANGELOG.md](FORK_CHANGELOG.md).

---

## Ausgangslage (heute)

| Bereich | Status |
|---------|--------|
| Power-Trigger, Grace Period, 5 Security Actions | ✅ produktiv |
| Auto-Arm (Standort/Netzwerk), Event-Log, Onboarding | ✅ produktiv |
| EN/DE, `task release`, CI grün | ✅ produktiv |
| Netzwerk-**Aktionen** (bei Trigger ausführen) | ✅ v0.4.0 |
| Fernauslösung (`magsafeguard://`) | ✅ v0.4.0 |
| **Panic-Modus** | ❌ geplant v0.5.0 |
| **Paranoid-Modus** | ❌ geplant v0.6.0 |
| Notarisierung (Developer ID) | ⏸️ wenn App reif + Paid Dev |
| Mac App Store | ❌ **ausgeschlossen** (Sandbox) |
| Repository | ✅ öffentlich — [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill) |

### Repository öffentlich

| Anforderung | Status |
|-------------|--------|
| `LICENSE` (MIT, Dual-Copyright) | ✅ |
| `NOTICE` (Upstream, Fork, BusKill) | ✅ |
| README EN/DE (Fork vs. Upstream) | ✅ |
| `LICENSE` + `NOTICE` in Release-Binaries | 📋 bei erstem GitHub Release |
| Panic-Rechtstexte in der App | erst v0.5.0 |

Öffentlich seit August 2026 (nach Prüfung der ersten drei Punkte auf `main`).

---

## Getroffene Entscheidungen

| # | Thema | Entscheidung |
|---|--------|--------------|
| 1 | **Modus-Namen** | **Panic** (Schutz, Shutdown) und **Paranoid** (Vernichtung) — öffentlich in UI, Docs, Releases |
| 2 | **Netzwerk-Aktionen** | **Vollpaket:** Webhook + VPN + SSH-Agent + WLAN (+ optional Proxy/DNS) |
| 3 | **Panic-Auslöser** | **Hotkey** + Kabel + **Fernauslösung** (URL-Scheme / Shortcuts, später Polling/Push) |
| 4 | **Verteilung** | **GitHub** (Quellcode + optionale Releases) + **notarisierte DMG** — **kein App Store** |
| 5 | **Paid Apple Dev** | Wenn App veröffentlichungsreif: für **notarisierte Binaries**; nicht nötig zum Hosten von Quellcode auf GitHub |
| 6 | **Repository** | **Öffentlich** seit August 2026 (siehe [README](../README.md#repository-visibility)) |

---

## Leitplanken

1. **Sicherheit zuerst** — Destruktive Features nur opt-in, mit klarer Warnung und starker Bestätigung.
2. **Geschwindigkeit bei Schutz** — Lock/Logout zuerst und schnell (auch normal armed); Panic/Paranoid: 0 Grace, parallel, kein Circuit-Breaker-Block.
3. **Testbarkeit** — Panic nur mit Mocks; **kein** E2E mit echter Löschung.
4. **Verteilung** — Volle Features nur außerhalb des Mac App Store (Direct / GitHub).
5. **Rechtliches vor Panic** — Siehe [Pflicht-Checkliste](#pflicht-checkliste-vor-panic-modus) unten.

---

## Phase 1 — Netzwerk-Aktionen (~0.4.0)

**Ziel:** Beim Sicherheits-Trigger und im Panic-Modus Netzwerk-Reaktionen ausführen — inkl. **Fernauslösung**.

### Aktionstypen (alles in 0.4.0)

| Aktion | Kurz |
|--------|------|
| **HTTP Webhook (outbound)** | `POST` bei Event; Token in Keychain |
| **VPN trennen** | WireGuard, Tunnelblick, `networksetup` |
| **SSH-Agent leeren** | `ssh-add -D` |
| **WLAN aus** | `networksetup -setairportpower off` |
| **DNS / Proxy reset** | Advanced |

### Fernauslösung (Inbound)

| Variante | Priorität |
|----------|-----------|
| **URL-Scheme** (`magsafeguard://panic?token=…`) + iOS Shortcuts | hoch |
| **Webhook-Polling** (Mac fragt Endpoint ab) | mittel |
| **Push (APNs)** | nach Paid Dev |

### Lieferumfang

- [x] Outbound network actions (webhook, VPN, SSH, Wi‑Fi)
- [x] Settings → Security → Network + Remote Trigger
- [ ] Domain Use Cases refactor (optional)
- [ ] Shortcuts-Dokumentation
- [x] EN/DE · README · FORK_CHANGELOG (0.4.0)

**Aufwand:** mittel–hoch · **Risiko:** niedrig (outbound)

---

## Phase 2 — Panic-Modus (~0.5.0)

**Ziel:** **Panic** — Gerät sofort unzugänglich machen **ohne** Daten zu löschen.  
Design: [docs/features/panic-modes.md](features/panic-modes.md)

### Verhalten (Panic)

| Aspekt | Normal (armed) | Panic |
|--------|----------------|-------|
| Grace Period | 5–30 s | **0 s** |
| Ablauf | konfiguriert | **parallel** |
| Circuit Breaker | aktiv | **aus** |
| Auslöser | Kabel | Kabel + **Hotkey** + `magsafeguard://panic` |
| Abbruch | Auth möglich | **nein** |
| Daten löschen | — | **nein** |

**Sofort:** Lock + Logout + Netzwerk-Aktionen + **harter Shutdown** (neuer Pfad, kein 1-Minuten-Dialog).

### Arming (Panic)

- Eine starke Bestätigung
- **Kurzer** Rechtshinweis (EN + DE): unsaved work, kein Abbruch, Vorsicht Dienstgerät — **kein** Codewort
- Eigenes Menüleisten-Icon

### Pflicht-Checkliste vor Panic (v0.5.0)

- [ ] **Protection-first trigger path** — lock under 500 ms; parallel tier-2; bypass rate limit on theft trigger ([GAP-15](features/behavior-gaps.md))
- [ ] `PanicModeExecutor` + sofortiger Shutdown (nicht `scheduleShutdown`)
- [ ] Panic-Arming-UI + kurzer Rechtshinweis (EN + DE)
- [ ] Eigenes Menüleisten-Icon (panic armed)
- [ ] Hotkey + `magsafeguard://panic`
- [ ] `MockPanicExecutor` (CI) — kein destruktiver Testlauf
- [ ] [panic-modes.md](features/panic-modes.md) · `operating-modes.md` · README EN/DE

---

## Phase 2b — Paranoid-Modus (~0.6.0)

**Ziel:** **Paranoid** — schnellste mögliche Datenvernichtung + sofortiger Shutdown.  
**Voraussetzung:** Nutzer hat vorgehärtet (FileVault an, Wipe-Pfade/Volumes konfiguriert). Setup-Modus, kein Plug-and-play.

### Verhalten (Paranoid)

Alles aus Panic, plus **parallele** Destruction-Pipeline (fire-and-forget), dann **sofort** Shutdown (nicht auf Wipe warten).

| Maßnahme | Priorität |
|----------|-----------|
| Clipboard, SSH-Agent, Browser kill | sofort |
| Konfigurierte Pfade / APFS-Volume | parallel |
| Lokales Recovery-Key-Backup löschen | falls konfiguriert |
| Shutdown | sofort (terminal) |

### Arming (Paranoid)

- Setup-Wizard (FileVault-Check, Wipe-Ziele)
- **Doppelte** Bestätigung + **Pflicht-Codewort**
- Eigenes Onboarding nur für Paranoid
- **Voller** Rechtshinweis (EN + DE) inkl. irreversibler Datenverlust, Dienstgerät-Warnung

### Pflicht-Checkliste vor Paranoid (v0.6.0)

- [ ] `ParanoidModeExecutor` + `DestructionPipeline` + Mocks
- [ ] Setup-Wizard + FileVault-Prüfung
- [ ] Doppelte Bestätigung + Codewort + voller Rechtstext
- [ ] `magsafeguard://paranoid` (eigenes Token empfohlen)
- [ ] Ehrliche Limits in UI (APFS, Forensik)
- [ ] Rechtliche Prüfung DE/EU vor öffentlicher Beta
- [ ] README EN + DE

### Teststrategie (beide Modi)

| Was | Wie |
|-----|-----|
| Trigger-Logik, 0 Grace | Unit-Tests + Mock |
| Echtes Löschen | **Nie** in CI |

**Aufwand:** Panic mittel · Paranoid hoch · **Risiko:** Paranoid sehr hoch

---

## Phase 3 — Verteilung (~1.0.0)

| Kanal | Status | Hinweis |
|-------|--------|---------|
| **GitHub (Quellcode)** | ✅ jetzt | MIT + NOTICE; Nutzer bauen mit eigener Apple-ID |
| **GitHub Releases (.dmg)** | geplant | Optional; für Fremde besser notarisiert |
| **Developer ID + Notarisierung** | geplant | Paid Dev (~99 $/Jahr); Gatekeeper-freundlich |
| **Mac App Store** | ❌ ausgeschlossen | Sandbox: kein Shutdown, keine freien Skripte, kein Panic |

### Braucht man Apple Developer nur für GitHub?

| Szenario | Paid Dev nötig? |
|----------|-----------------|
| Repo mit Quellcode (öffentlich oder privat) | **Nein** |
| Nutzer klont und baut selbst (Personal Team) | **Nein** |
| Du lädst `.dmg` nur für dich hoch | **Nein** (Personal Team, ~7 Tage Signatur) |
| Fremde installieren deine `.dmg` ohne Warnung | **Ja** (Developer ID + Notarisierung) |

---

## Phase 4 — Nice-to-have (nach 1.0)

- Home Assistant / MQTT Presets
- Evidence / Forensik-Paket
- Hardware-BusKill (USB)
- Selektiver Upstream-Sync

---

## Zeitstrahl

```
Jetzt ──► 0.4.x  Netzwerk + Fernauslösung (done)
       ──► 0.5.0  Panic (Shutdown, 0 Grace, kein Datenverlust)
       ──► 0.6.0  Paranoid (Vernichtung + Shutdown, Setup-Modus)
       ──► 1.0.0  Stabil + notarisierte DMG (optional Paid Dev)
```

---

## Rechtliches (keine Rechtsberatung)

### MIT-Fork veröffentlichen — **bereits erledigt im Repo**

| Anforderung | Status |
|-------------|--------|
| [LICENSE](../LICENSE) mit Upstream- + Fork-Copyright | ✅ |
| [NOTICE](../NOTICE) mit Attribution & BusKill-Hinweis | ✅ |
| Eigenes Branding (`com.sutz2001.MagSafeGuard`) | ✅ |
| Bei Binary-Releases LICENSE + NOTICE beilegen | 📋 bei GitHub Releases beachten |

### Deutschland / EU (Panic-Modus)

Security-Tools sind bei **informierter Einwilligung** grundsätzlich zulässig. Panic erhöht das Risiko (eigene Daten, **Dienstgeräte**, fernausgelöste Zerstörung) → **Pflicht-Checkliste** oben ist verbindlich geplant.

### Mac App Store — warum ausgeschlossen

Apple Sandbox erlaubt die aktuelle Architektur (System-Shutdown, AppleScript-Logout, Nutzer-Skripte außerhalb `NSUserScriptTask`, Massenlöschung) nicht. **Kein weiterer Planungsaufwand** für App Store.

---

## Referenzen

- `SecurityActionType`: `MagSafeGuardLib/.../SecurityActionProtocols.swift`
- [docs/PRD.md](PRD.md) (Upstream)
- [AGENTS.md](../AGENTS.md)
- [README.md](../README.md) · [README.de.md](../README.de.md)
