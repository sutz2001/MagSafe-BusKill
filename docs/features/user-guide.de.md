# MagSafe Guard — Kurzanleitung

**Sprache:** [English (user-guide.md)](user-guide.md) · Deutsch  
**Version:** Fork **0.5.7** (Build 16) · September 2026

Kurze Praxis-Anleitung für den Alltag. Technische Details: [operating-modes.md](operating-modes.md) (EN) · Panic-Design: [panic-modes.md](panic-modes.md)

---

## 1. Was die App macht

MagSafe Guard ist ein **Dead-Man's-Switch in der Menüleiste**:

1. Sie **scharfschalten** (Touch ID / Passwort).
2. Im scharfgeschalteten Zustand startet **Kabeltrennung** eine **Karenzzeit** (Standard 30 Sekunden).
3. Nach Ablauf (oder sofort bei Karenzzeit 0) laufen **Sicherheitsaktionen** (Sperre, Alarm, Abmelden, Shutdown, Skript).
4. Optionale **Netzwerk-Aktionen** (Webhook, VPN aus, SSH-Agent leeren, Zwischenablage leeren, WLAN aus) laufen beim gleichen Trigger.

Im Zustand **unscharf** passiert beim Abziehen des Netzteils **nichts**.

Standardmäßig nur **Menüleiste** (**Im Dock anzeigen** unter Einstellungen → Allgemein ist aus). Dock-Icon bei Bedarf einschalten. Menüleisten-Icons sind standardmäßig **monochrom**; **Farbige Menüleisten-Icons** in Allgemein oder im Statusmenü schalten dezente Zustandsfarben ein.

---

## 2. Betriebsmodi (Einstellungs-Presets)

**Einstellungen → Security** (oben im Tab): vier **Betriebsmodi** (Auswahlmenü). Die Auswahl setzt Standardwerte; einzelne Schalter können danach angepasst werden.

| Modus | Karenz | Sicherheitsaktionen | Mitteilungen | Dock | Netzwerk-Aktionen |
|-------|--------|---------------------|--------------|------|-------------------|
| **Einsteiger** | 30 s | Nur Sperre | An | Ihre Wahl | Keine |
| **Normal** | 30 s | Sperre + Alarm | An | Ihre Wahl | Keine |
| **Diskret** | 20 s | Nur Sperre | Aus (nur Icon) | Aus | Keine |
| **Panic** (Preset) | 5 s | Sperre + Abmelden | Aus | Aus | VPN aus, SSH leeren, Zwischenablage leeren |

**Hinweise:**

- **Einsteiger** ist Standard bei **Neuinstallation** — empfohlen für die ersten Tage (nur Sperre, volle Karenz zum Abbrechen).
- Farbige **Auswirkungs-Stufen** (Sicher / Datenverlust möglich / Hohes Risiko) bei Aktionen und Presets — nur Hinweis, nichts wird gesperrt.
- Die Auswahl **bleibt auf dem gewählten Modus**, auch wenn Sie einzelne Einstellungen ändern (kein automatischer Wechsel zu „Individuell“).
- Weicht die Konfiguration ab: **Auf [Modus]-Standard zurücksetzen** unter der Beschreibung.
- **Panic-Preset ≠ Panic-Schutz aktivieren** (siehe §5). Das Preset gilt für **normal scharf**; **Panic-Modus aktivieren** im Menü ist ein separater Zustand mit **0 s Karenz** und sofortigem Shutdown.

**Karenzzeit** und **Abbrechen erlauben** stehen auf dem gleichen Tab **Security** unter dem Modus-Schalter (Schieberegler 5–30 s).

**Mitteilungen:** Link **Mitteilungen anpassen…** zum Tab Mitteilungen, oder Modus **Diskret** für alles aus.

---

## 3. Normalmodus — Alltag

### Scharf / unscharf

| Aktion | So geht's |
|--------|-----------|
| Scharfschalten | Menüleiste → **Schutz aktivieren** (oder **⌘A** bei offenem Menü) |
| Entschärfen | Menü → **Schutz deaktivieren** + Touch ID / Passwort |
| Ereignisprotokoll | **⌘L** oder Menü → **Event Log** |
| Einstellungen | **⌘,** oder Menü → **Einstellungen** (Tab **Security**) |

### Karenzzeit

- Countdown in der **Menüleiste** (außer wenn Warnungen aus — siehe §4).
- **Netzteil wieder einstecken** während der Karenz → Karenz **abgebrochen**, System bleibt **scharf**.
- **Karenz abbrechen** (wenn auf Security erlaubt) → Touch ID / Passwort nötig.

### Sicherheitsaktionen

**Einstellungen → Security** — fünf Typen ein/aus, per Drag & Drop **sortieren**.

Bei Kabeltrennung (normal scharf) läuft **Sperre zuerst**, dann weitere Aktionen.

### Netzwerk-Aktionen

In der App: **Einstellungen → Security → Network**.

| Aktion | Wirkung |
|--------|---------|
| HTTP-Webhook | JSON-POST `{event, source, timestamp}`; optional Bearer-Token |
| VPN trennen | Aktive VPN-Verbindung beenden |
| SSH-Agent leeren | `ssh-add -D` |
| Zwischenablage leeren | macOS-Zwischenablage leeren (systemweit) |
| WLAN deaktivieren | Wi‑Fi aus — **orangefarbener Hinweis** (Find My) |

WLAN aus ist in **keinem Preset** aktiv (Find My). Webhooks bleiben individuell.

### Eigene Skripte (optional)

**Einstellungen → Erweitert → Eigene Skripte** — Pfade unter `~/.magsafe/scripts/` oder `/usr/local/magsafe-scripts/`.  
Beispiele: [docs/examples/scripts/README.md](../examples/scripts/README.md) (Browser beenden, Cryptomator/VeraCrypt trennen, externe Laufwerke, Verlauf best-effort).

**Eigenes Skript** unter Security aktivieren, wenn ein Pfad gesetzt ist.

### Fernauslösung (optional)

Wenn aktiviert unter **Einstellungen → Security → Remote Trigger**:

| URL | Wirkung |
|-----|---------|
| `magsafeguard://arm?token=IHR_TOKEN` | Scharfschalten ohne interaktive Auth (wenn unscharf) |
| `magsafeguard://trigger?token=IHR_TOKEN` | Aktionen im **normalen** Scharf-Modus |
| `magsafeguard://panic?token=IHR_TOKEN` | Panic-Reaktion im **Panic-Schutz** (siehe §5) |

Aus **Shortcuts** auf iPhone/Mac. Token geheim halten.

### Kommandozeilen-CLI (optional)

Für **lokale Automation** (Skripte, LaunchAgents) auf dem gleichen Mac — kein Ersatz für die URL-Scheme-Fernauslösung von anderen Geräten.

**Voraussetzung:** MagSafe Guard läuft in der **Menüleiste**.

**Einmal bauen** (aus einem Repo-Klon):

```bash
task cli:build
```

Dann das Wrapper-Skript (oder die Binary unter `MagSafeGuardLib/.build/release/MagSafeGuardCLI`):

```bash
./scripts/magsafeguard-cli status
./scripts/magsafeguard-cli apply-profile beginner
./scripts/magsafeguard-cli arm
./scripts/magsafeguard-cli disarm
```

| Befehl | Wirkung |
|--------|---------|
| `status` | Gibt JSON aus `~/Library/Application Support/MagSafeGuard/cli-status.json` aus (Zustand, Profil, konfiguriertes Risiko, Version) |
| `apply-profile <name>` | Betriebsmodus setzen: `beginner`, `normal`, `discreet` oder `panic` — ohne Auth |
| `arm` / `disarm` | Wie im Menü — **Touch ID / Passwort** in der App |

`arm` umgeht **keine** Authentifizierung (anders als `magsafeguard://arm?token=…` mit aktiviertem Remote Trigger).

---

## 4. Diskreter Betrieb

**Unauffällig:** nur Menüleisten-Icon — keine Töne, keine macOS-Benachrichtigungen.

**Schnell:** Betriebsmodus **Diskret** (Einstellungen → Security).

**Manuell:** **Einstellungen → Mitteilungen** — alle drei aus:

| Schalter | Wenn aus |
|----------|----------|
| Status-Benachrichtigungen | Keine Arm/Disarm-Toasts |
| Sicherheitswarnungen | Kein Grace-Banner; kein Countdown-Text |
| Kritischer Alarmton | Kein Signalton beim Grace-Start |

Karenz läuft weiter; Entschärfen über das Menü.

---

## 5. Panic-Schutzmodus (v0.5.0)

**Panic-Modus aktivieren…** im Menü ist **nicht** dasselbe wie das **Panic**-Preset in den Einstellungen.

| | Panic-**Preset** (Einstellungen) | Panic-**Schutz** (Menü) |
|---|----------------------------------|-------------------------|
| Zweck | Aggressive Defaults für **normal scharf** | Maximale Reaktion bei Kabeltrennung |
| Karenz bei Trennung | 5 s (konfigurierbar) | **0 s** — sofort |
| Abbruch während Reaktion | Laut Einstellungen | **Nein** |
| Shutdown | Laut Sicherheitsaktionen | **Sofort** |
| Aktivierung | Einstellungen → Security → Panic | Menü → **Panic-Modus aktivieren…** + Auth |

Im **Panic-Schutz** gilt beim Abziehen die Panic-Pipeline — unabhängig vom Karenz-Schieberegler.

### Panic-Schutz aktivieren

1. Menüleiste → **Panic-Modus aktivieren…** (Kürzel **⌘P** bei offenem Menü).
2. **Beim ersten Mal:** kurzen Rechtshinweis lesen → **Verstanden — Panic aktivieren**.
3. Mit Touch ID / Passwort authentifizieren.
4. Menüleisten-Icon wechselt zum **Triggered**-Stil.

Verlassen: Menü → **Schutz deaktivieren**.

### Panic auslösen (wenn panic-scharf)

| Auslöser | Wirkung |
|----------|---------|
| **Kabel trennen** | Sofortige Panic-Pipeline |
| **⌃⌘P** (Control+Command+P) | Gleich — **global**, solange die App läuft |
| `magsafeguard://panic?token=…` | Gleich — Fernauslösung |

**⌃⌘P** nur im **Panic-Schutz**; ignoriert wenn unscharf oder normal scharf.

### Was der Panic-Schutz tut

1. Aktivierte **Netzwerk-Aktionen** (Preset: VPN, SSH, Zwischenablage — plus eigene)
2. Bildschirm **zuerst** sperren, dann Abmelden/Alarm parallel
3. **Sofort herunterfahren** (kein 1-Minuten-Dialog)

**Nicht:** Dateien löschen oder Laufwerke wischen.

### ⚠️ Warnungen

- **Nicht gespeicherte Arbeit kann verloren gehen.**
- Nur auf einem Rechner testen, den Sie herunterfahren können.
- **Dienstgeräte:** Arbeitgeber-Richtlinien prüfen.
- Netzteil wieder einstecken **bricht Shutdown nicht ab**.

---

## 6. Kurzvergleich

| | Normal scharf | Diskret | Panic-Preset | Panic-**Schutz** |
|---|---------------|---------|--------------|------------------|
| Typische Karenz | 30 s | 20 s | 5 s | **0 s** |
| Mitteilungen | An | Aus | Aus | Aus |
| Shutdown bei Kabel | Verzögerung konfigurierbar | Konfigurierbar | Abmelden + Reihenfolge | **Sofort** |
| Hotkey | — | — | — | **⌃⌘P** |

**Paranoid-Modus** (Datenvernichtung) ist **nicht** implementiert — geplant v0.6.0 (gleiche Netzwerk-Basis inkl. Zwischenablage).

---

## 7. Auto-Arm (optional)

In der App: **Einstellungen → Auto-Arm**.

- Automatisch scharfschalten beim Verlassen eines vertrauenswürdigen Ortes oder in unbekanntem Netz.
- Nutzt `armAutomatically()` — kein Touch-ID-Dialog beim Auto-Arm (Absicht).
- Kann vorübergehend im Menü deaktiviert werden.

---

## 8. Fehlerbehebung

| Problem | Prüfen |
|---------|--------|
| Abziehen bewirkt nichts | System ist **unscharf** |
| Kein Menüleisten-Icon | App läuft? Menüleisten-Überlauf (•••) |
| App nicht findbar | Einstellungen → Allgemein → **Im Dock anzeigen**, oder Spotlight |
| Hotkey ⌃⌘P ohne Wirkung | Muss **panic-scharf** sein; App muss laufen |
| Fern-URL ignoriert | Token korrekt? Fernauslösung aktiv? |
| CLI: „Status unavailable“ | Läuft die App? Einmal `status` nach Start ausführen, damit die Statusdatei geschrieben wird |
| CLI `arm` läuft in Timeout | Touch ID / Passwort in der App bestätigen; bis 30 s warten |
| Build nach ~7 Tagen abgelaufen | Personal Team — neu bauen mit `task release` oder Xcode |

Mehr: [maintainers/troubleshooting.md](../maintainers/troubleshooting.md)

---

## 9. Weiterführend

| Dokument | Zielgruppe |
|----------|------------|
| [operating-modes.md](operating-modes.md) | Zustandsmaschine & technische Abläufe |
| [panic-modes.md](panic-modes.md) | Panic/Paranoid-Design & Rechtliches |
| [examples/scripts/README.md](../examples/scripts/README.md) | Beispiel-Skripte |
| [behavior-gaps.md](behavior-gaps.md) | Behobene vs. offene UI/Laufzeit-Themen |
| [FORK_CHANGELOG.md](../FORK_CHANGELOG.md) | Release-Historie |
| [README.de.md](../../README.de.md) | Bauen, installieren, Roadmap |
