# Fork-Roadmap (sutz2001)

Planung für [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).  
Stand: nach **0.5.5** (September 2026). Release-Historie: [FORK_CHANGELOG.md](FORK_CHANGELOG.md).

**Kurzanleitung:** [user-guide.de.md](features/user-guide.de.md) · [user-guide.md](features/user-guide.md) (EN)

---

## Ausgangslage (heute)

| Bereich | Status |
|---------|--------|
| Power-Trigger, Grace Period, 5 Security Actions | ✅ produktiv |
| Auto-Arm (Standort/Netzwerk), Event-Log, Onboarding | ✅ produktiv |
| EN/DE, `task release`, CI grün | ✅ produktiv |
| Netzwerk-Aktionen + Fernauslösung (`magsafeguard://`) | ✅ v0.4.0 |
| Diskreter Betrieb (nur Menüleisten-Icon) | ✅ v0.4.3 |
| **Panic-Modus** (0 Grace, Hotkey ⌃⌘P, sofort Shutdown) | ✅ v0.5.0 |
| **Betriebsmodi** (Normal / Diskret / Panic-Presets) | ✅ v0.5.1 |
| **Zwischenablage leeren** (Netzwerk-Aktion) | ✅ v0.5.1 |
| **Paranoid-Modus** | ❌ geplant v0.6.0 |
| **Stabilisierung (0.5.x)** | 🔄 **aktueller Fokus** — [Checkliste](maintainers/stabilization-checklist.md) |
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
| Panic-Rechtstexte in der App | ✅ v0.5.0 (kurzer Hinweis EN/DE) |

Öffentlich seit August 2026 (nach Prüfung der ersten drei Punkte auf `main`).

---

## Getroffene Entscheidungen

| # | Thema | Entscheidung |
|---|--------|--------------|
| 1 | **Modus-Namen** | **Panic** (Schutz, Shutdown) und **Paranoid** (Vernichtung) — öffentlich in UI, Docs, Releases |
| 2 | **Netzwerk-Aktionen** | **Vollpaket:** Webhook + VPN + SSH-Agent + WLAN (+ optional Proxy/DNS) |
| 3 | **Panic-Auslöser** | **Hotkey ⌃⌘P** + Kabel + **Fernauslösung** (`magsafeguard://panic`); LAN/Web vom Handy → [Idee](features/future-ideas.md) |
| 4 | **Verteilung** | **GitHub** (Quellcode + optionale Releases) + **notarisierte DMG** — **kein App Store** |
| 5 | **Paid Apple Dev** | Wenn App veröffentlichungsreif: für **notarisierte Binaries**; nicht nötig zum Hosten von Quellcode auf GitHub |
| 6 | **Repository** | **Öffentlich** seit August 2026 (siehe [README](../README.md#repository-visibility)) |

---

## Leitplanken

1. **Sicherheit zuerst** — Destruktive Features nur opt-in, mit klarer Warnung und starker Bestätigung.
2. **Geschwindigkeit bei Schutz** — Lock/Logout zuerst und schnell (auch normal armed); Panic/Paranoid: 0 Grace, parallel, kein Circuit-Breaker-Block.
3. **Testbarkeit** — Panic nur mit Mocks; **kein** E2E mit echter Löschung.
4. **Verteilung** — Volle Features nur außerhalb des Mac App Store (Direct / GitHub).
5. **Rechtliches** — Panic: kurzer Hinweis (shipped). Paranoid: volle Prüfung vor v0.6.

---

## Phase 1 — Netzwerk-Aktionen (0.4.0) ✅

**Ziel:** Beim Sicherheits-Trigger Netzwerk-Reaktionen ausführen — inkl. **Fernauslösung**.

### Lieferumfang

- [x] Outbound network actions (webhook, VPN, SSH, clipboard, Wi‑Fi)
- [x] Settings → Security → Network + Remote Trigger
- [x] `magsafeguard://arm` + `magsafeguard://trigger`
- [x] EN/DE · README · FORK_CHANGELOG (0.4.0)

**Aufwand:** mittel–hoch · **Risiko:** niedrig (outbound)

---

## Phase 1b — Diskreter Betrieb (0.4.3) ✅

- [x] `showStatusNotifications`, `showSecurityAlerts`, `playCriticalAlertSound`
- [x] `isDiscreetOperation` wenn alle drei aus
- [x] Docs: [user-guide](features/user-guide.md), [operating-modes](features/operating-modes.md)

---

## Phase 2 — Panic-Modus (0.5.0) ✅

**Ziel:** **Panic** — Gerät sofort unzugänglich machen **ohne** Daten zu löschen.  
Design: [docs/features/panic-modes.md](features/panic-modes.md) · Anleitung: [user-guide.de.md §5](features/user-guide.de.md#5-panic-schutzmodus-v050)

### Verhalten (Panic) — ausgeliefert

| Aspekt | Normal (armed) | Panic |
|--------|----------------|-------|
| Grace Period | 5–30 s | **0 s** |
| Ablauf bei Kabel-Trigger | protection-first | **parallel + sofort Shutdown** |
| Circuit Breaker / Rate Limit | nur Standard-Kontext | **aus** bei Theft/Panic |
| Auslöser | Kabel, `trigger` URL | Kabel + **⌃⌘P** + `panic` URL |
| Abbruch | Auth möglich | **nein** |
| Daten löschen | — | **nein** |

### Checkliste v0.5.0 — erledigt

- [x] Protection-first trigger path (GAP-15)
- [x] `PanicModeExecutor` + `executeImmediateShutdown()`
- [x] Panic-Arming-UI + kurzer Rechtshinweis (EN + DE)
- [x] Eigenes Menüleisten-Icon (panic armed)
- [x] Hotkey **⌃⌘P** + `magsafeguard://panic`
- [x] Unit-Tests mit Mocks (`PanicModeExecutorTests`, `AppControllerTests`)
- [x] `operating-modes.md` · `panic-modes.md` · README EN/DE · [user-guide](features/user-guide.md)

---

## Phase 2b — Betriebsmodi & Presets (0.5.x) ✅

**Ziel:** Schnell zwischen **Normal**, **Diskret** und **Panic**-Defaults wechseln, ohne „Custom“-Modus in der UI.

- [x] `OperationProfile` + `OperationProfilePresets` (Grace, Aktionen, Mitteilungen, Dock, Netzwerk)
- [x] Settings → Security: segmentierter Picker, Karenz, Link zu Mitteilungen, Reset-Link
- [x] **Zwischenablage leeren** als Netzwerk-Aktion; Panic-/Paranoid-Baseline
- [x] Trigger-Skripte unter `MagSafeGuard/Resources/TriggerScripts/` (mit App gebündelt)
- [x] Kurzanleitung + README EN/DE aktualisiert

---

## Phase 2c — Stabilisierung (0.5.x, aktueller Fokus)

**Ziel:** App als **Daily Driver** auf dem eigenen Mac — Bugs fixen, Tests grün, Release-DMG, manuelle Smoke-Tests. **Keine neuen Features.**

Checkliste: **[maintainers/stabilization-checklist.md](maintainers/stabilization-checklist.md)**

| Priorität | Thema |
|-----------|--------|
| P0 | `task test` / `task xcode:test` grün (u. a. `PowerMonitorUseCaseImplTests` Sendable) |
| P0 | Manueller Smoke: Normal, diskret, Panic (kontrolliert) |
| P1 | `task release` → `/Applications`, mehrere Tage Alltagsnutzung |
| P2 | Acceptance-Tests-Doc aktualisieren; optional erstes GitHub Release |

**Exit:** Checkliste § Exit criteria erfüllt → dann 0.5.x nur noch Patches oder Sprung Richtung 1.0.0 (notarisierte DMG).

---

## Phase 2d — Paranoid-Modus (0.6.0) 🔄

**Ziel:** **Paranoid** — schnellste mögliche Datenvernichtung + sofortiger Shutdown.  
**Voraussetzung:** Nutzer hat vorgehärtet (FileVault an, Wipe-Pfade/Volumes konfiguriert). Setup-Modus, kein Plug-and-play.

Design: [panic-modes.md](features/panic-modes.md) · GitHub-Milestone: **v0.6-paranoid**

### Abhängigkeiten

```text
M1 Config + Settings → M2 DestructionPipeline → M3 ParanoidModeExecutor
M1 → M4 Setup-Wizard → M5 Arming + Legal
M3 + M5 → M6 Routing + Trigger → M7 Docs + Legal-Gate
```

### Milestones

| # | Milestone | Ziel-Tag | Aufwand |
|---|-----------|----------|---------|
| M1 | Datenmodell & Settings-UI | 0.6.0-alpha | S |
| M2 | `DestructionPipeline` (Mock + Mac) | 0.6.0-alpha | M |
| M3 | `ParanoidModeExecutor` | 0.6.0-beta | M |
| M4 | Setup-Wizard (FileVault + Ziele) | 0.6.0-beta | M |
| M5 | Arming, Codewort, Legal UI | 0.6.0-beta | M |
| M6 | Routing, Icon, Hotkey, `paranoid` URL | 0.6.0-rc | M |
| M7 | Docs, i18n, Legal-Gate | 0.6.0 | S |

### PR-Schnitte (Issues auf GitHub)

| PR | Issue | Milestone |
|----|-------|-----------|
| 1 | [#5 ParanoidConfiguration + migration v14](https://github.com/sutz2001/MagSafe-BusKill/issues/5) | M1 — done |
| 2 | [#6 Settings UI wipe targets](https://github.com/sutz2001/MagSafe-BusKill/issues/6) | M1 — done |
| 3 | [#7 DestructionPipeline + Mock](https://github.com/sutz2001/MagSafe-BusKill/issues/7) | M2 — done |
| 4 | [#8 MacDestructionPipeline](https://github.com/sutz2001/MagSafe-BusKill/issues/8) | M2 — done |
| 5 | [#9 ParanoidModeExecutor](https://github.com/sutz2001/MagSafe-BusKill/issues/9) | M3 — done |
| 6 | [#10 Setup wizard](https://github.com/sutz2001/MagSafe-BusKill/issues/10) | M4 — in progress |
| 7 | [#11 Legal + codeword](https://github.com/sutz2001/MagSafe-BusKill/issues/11) | M5 |
| 8 | [#12 armParanoid + menu + icon](https://github.com/sutz2001/MagSafe-BusKill/issues/12) | M5–M6 |
| 9 | [#13 Trigger routing](https://github.com/sutz2001/MagSafe-BusKill/issues/13) | M6 |
| 10 | [#14 magsafeguard://paranoid](https://github.com/sutz2001/MagSafe-BusKill/issues/14) | M6 |
| 11 | [#15 Docs + version 0.6.0](https://github.com/sutz2001/MagSafe-BusKill/issues/15) | M7 |
| 12 | [#16 Legal review gate](https://github.com/sutz2001/MagSafe-BusKill/issues/16) | M7 |

Milestone: [v0.6-paranoid](https://github.com/sutz2001/MagSafe-BusKill/milestone/1)

**Erster manueller Test:** nach PR-5 mit Mock-Pipeline. **Erster echter Wipe:** nach PR-4 nur auf Spare-Mac / dediziertem Test-Volume.

### Bewusst nicht in v0.6.0

- Keychain-Massenlöschung (hohes Fehlerrisiko → ggf. v0.6.1)
- Eingebauter Browser-Kill (Skripte + Panic-Baseline reichen)
- LUKS-Header am Boot-Volume (macOS-Limit)
- E2E-Wipe in CI (verboten — nur Mocks)
- LAN-Web-Trigger → [future-ideas.md](features/future-ideas.md)

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

- **iCloud: Skript-Inhalte syncen** (nicht nur Pfade) — wenn CloudKit aktiv: Custom-Scripts aus `~/.magsafe/scripts/` als Bundle/Records mit deployen (heute sync’t Settings nur die Pfad-Liste). Spielerei / Multi-Mac-Komfort, kein Muss.
- **LAN trigger from phone** (same Wi‑Fi, minimal web UI?) — [Gedankenfetzen](features/future-ideas.md#lan-trigger-from-phone-same-wi-fi); heute nur `magsafeguard://` + Shortcuts
- Home Assistant / MQTT Presets
- Evidence / Forensik-Paket
- Hardware-BusKill (USB)
- Selektiver Upstream-Sync

---

## Zeitstrahl

```text
Jetzt ──► 0.4.x  Netzwerk + Fernauslösung (done)
       ──► 0.4.3  Diskreter Betrieb (done)
       ──► 0.5.0  Panic (Shutdown, 0 Grace, Hotkey ⌃⌘P) (done)
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

Security-Tools sind bei **informierter Einwilligung** grundsätzlich zulässig. Panic erhöht das Risiko (eigene Daten, **Dienstgeräte**, fernausgelöste Zerstörung). Kurzer Hinweis in der App (v0.5.0) ist ausgeliefert; Paranoid erfordert volle Prüfung vor v0.6.

### Mac App Store — warum ausgeschlossen

Apple Sandbox erlaubt die aktuelle Architektur (System-Shutdown, AppleScript-Logout, Nutzer-Skripte außerhalb `NSUserScriptTask`, Massenlöschung) nicht. **Kein weiterer Planungsaufwand** für App Store.

---

## Referenzen

- `SecurityActionType`: `MagSafeGuardLib/.../SecurityActionProtocols.swift`
- [docs/PRD.md](PRD.md) (Upstream)
- [AGENTS.md](../AGENTS.md)
- [README.md](../README.md) · [README.de.md](../README.de.md)
- [user-guide.md](features/user-guide.md) · [user-guide.de.md](features/user-guide.de.md)
- [Future ideas (scratch pad)](features/future-ideas.md) — uncommitted thought fragments
