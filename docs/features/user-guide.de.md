# MagSafe Guard — Kurzanleitung

**Sprache:** [English (user-guide.md)](user-guide.md) · Deutsch  
**Version:** Fork **0.5.1** (Build 10) · September 2026

Kurze Praxis-Anleitung für den Alltag. Technische Details: [operating-modes.md](operating-modes.md) (EN) · Panic-Design: [panic-modes.md](panic-modes.md)

---

## 1. Was die App macht

MagSafe Guard ist ein **Dead-Man's-Switch in der Menüleiste**:

1. Sie **scharfschalten** (Touch ID / Passwort).
2. Im scharfgeschalteten Zustand startet **Kabeltrennung** eine **Karenzzeit** (Standard 30 Sekunden).
3. Nach Ablauf (oder sofort bei Karenzzeit 0) laufen **Sicherheitsaktionen** (Sperre, Alarm, Abmelden, Shutdown, Skript).
4. Optionale **Netzwerk-Aktionen** (Webhook, VPN aus, SSH-Agent leeren, Zwischenablage leeren, WLAN aus) laufen beim gleichen Trigger.

Im Zustand **unscharf** passiert beim Abziehen des Netzteils **nichts**.

Standardmäßig nur **Menüleiste** (**Im Dock anzeigen** unter Einstellungen → Allgemein ist aus). Dock-Icon bei Bedarf einschalten.

---

## 2. Betriebsmodi (Einstellungs-Presets)

**Einstellungen → Security** (oben im Tab): drei **Betriebsmodi**. Die Auswahl setzt Standardwerte; einzelne Schalter können danach angepasst werden.

| Modus | Karenz | Sicherheitsaktionen | Mitteilungen | Dock | Netzwerk-Aktionen |
|-------|--------|---------------------|--------------|------|-------------------|
| **Normal** | 30 s | Sperre + Alarm | An | Ihre Wahl | Keine |
| **Diskret** | 20 s | Nur Sperre | Aus (nur Icon) | Aus | Keine |
| **Panic** (Preset) | 5 s | Sperre + Abmelden | Aus | Aus | VPN aus, SSH leeren, Zwischenablage leeren |

**Hinweise:**

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

**Einstellungen → Security → Network**

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
Beispiele: [docs/examples/scripts/README.md](../examples/scripts/README.md) (Browser beenden, Verlauf best-effort).

**Eigenes Skript** unter Security aktivieren, wenn ein Pfad gesetzt ist.

### Fernauslösung (optional)

Wenn aktiviert unter **Einstellungen → Security → Remote Trigger**:

| URL | Wirkung |
|-----|---------|
| `magsafeguard://arm?token=IHR_TOKEN` | Scharfschalten ohne interaktive Auth (wenn unscharf) |
| `magsafeguard://trigger?token=IHR_TOKEN` | Aktionen im **normalen** Scharf-Modus |
| `magsafeguard://panic?token=IHR_TOKEN` | Panic-Reaktion im **Panic-Schutz** (siehe §5) |

Aus **Shortcuts** auf iPhone/Mac. Token geheim halten.

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

**Einstellungen → Auto-Arm**

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
