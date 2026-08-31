# Fork-Roadmap (sutz2001)

Planung für [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).  
Stand: nach **0.3.0** (August 2026). Release-Historie: [FORK_CHANGELOG.md](FORK_CHANGELOG.md).

---

## Ausgangslage (heute)

| Bereich | Status |
|---------|--------|
| Power-Trigger, Grace Period, 5 Security Actions | ✅ produktiv |
| Auto-Arm (Standort/Netzwerk), Event-Log, Onboarding | ✅ produktiv |
| EN/DE, `task release`, CI grün | ✅ produktiv |
| Netzwerk-**Aktionen** (bei Trigger ausführen) | ❌ geplant |
| **Panic-Modus** | ❌ geplant |
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
| 1 | **Modus-Name** | Nur **„Panic-Modus“** in UI, Docs und Releases — kein alternativer Codename in öffentlichen Artefakten |
| 2 | **Netzwerk-Aktionen** | **Vollpaket:** Webhook + VPN + SSH-Agent + WLAN (+ optional Proxy/DNS) |
| 3 | **Panic-Auslöser** | **Hotkey** + Kabel + **Fernauslösung** (URL-Scheme / Shortcuts, später Polling/Push) |
| 4 | **Verteilung** | **GitHub** (Quellcode + optionale Releases) + **notarisierte DMG** — **kein App Store** |
| 5 | **Paid Apple Dev** | Wenn App veröffentlichungsreif: für **notarisierte Binaries**; nicht nötig zum Hosten von Quellcode auf GitHub |
| 6 | **Repository** | **Öffentlich** seit August 2026 (siehe [README](../README.md#repository-visibility)) |

---

## Leitplanken

1. **Sicherheit zuerst** — Destruktive Features nur opt-in, mit klarer Warnung und starker Bestätigung.
2. **Geschwindigkeit bei Panic** — Keine Grace Period; parallel und fire-and-forget.
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

- [ ] Domain + Use Cases (outbound + inbound)
- [ ] Settings → Security → Network + Remote Trigger
- [ ] Shortcuts-Dokumentation
- [ ] EN/DE · README · FORK_CHANGELOG

**Aufwand:** mittel–hoch · **Risiko:** niedrig (outbound)

---

## Phase 2 — Panic-Modus (~0.5.0)

**Ziel:** Separater **Panic-Modus** — Gerät in Sekunden unbrauchbar machen. Öffentlicher Name ausschließlich **„Panic-Modus“**.

### Verhalten

| Aspekt | Normal (armed) | Panic |
|--------|----------------|-------|
| Grace Period | 5–30 s | **0 s** |
| Ablauf | konfiguriert | **parallel** |
| Circuit Breaker | aktiv | **aus** |
| Auslöser | Kabel | Kabel + **Hotkey** + **Fernauslösung** |
| Abbruch | Auth möglich | **nein** |

### Maßnahmen (nach Geschwindigkeit)

**Sofort:** Lock + Logout · Agenten leeren · Keychain · Pfade löschen · Clipboard · Webhooks

**Sekunden:** Volumes unmount · FileVault-Recovery-Key · optional APFS erase (dediziertes Volume)

### Pflicht-Checkliste vor Panic-Modus

> **Muss erledigt sein, bevor Panic in einer Release landet** (auch Beta):

- [ ] **Rechtshinweis in der App** (DE + EN): irreversibler Datenverlust; Nutzer haftet selbst; **Warnung bei Dienstgerät / Arbeitslaptop**; keine Gewähr
- [ ] **Onboarding-Kapitel** nur für Panic mit expliziter Einwilligung
- [ ] **Doppelte Bestätigung + Pflicht-Codewort** zum Arming
- [ ] Eigenes Menüleisten-Icon (panic armed)
- [ ] **Kein** Testlauf mit echter Löschung
- [ ] `PanicActionExecutor` + `MockPanicExecutor` (CI)
- [ ] README + [FORK_ROADMAP.md](FORK_ROADMAP.md) + Settings-Text aktualisieren
- [ ] Vor öffentlicher Veröffentlichung: **Rechtliches prüfen** (DE/EU — kein Ersatz für Anwalt)

### Teststrategie

| Was | Wie |
|-----|-----|
| Trigger-Logik | Unit-Tests + Mock |
| Echtes Löschen | **Nie** in CI |

**Aufwand:** hoch · **Risiko:** hoch

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
Jetzt ──► 0.4.0  Netzwerk (voll) + Fernauslösung
       ──► 0.5.0  Panic-Modus + Hotkey (+ Pflicht-Checkliste)
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
