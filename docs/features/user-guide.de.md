# MagSafe Guard — Kurzanleitung

**Sprache:** [English (user-guide.md)](user-guide.md) · Deutsch  
**Version:** Fork **0.5.0** (Build 9) · August 2026

Kurze Praxis-Anleitung für den Alltag. Technische Details: [operating-modes.md](operating-modes.md) (EN) · Panic-Design: [panic-modes.md](panic-modes.md)

---

## 1. Was die App macht

MagSafe Guard ist ein **Dead-Man's-Switch in der Menüleiste**:

1. Sie **scharfschalten** (Touch ID / Passwort).
2. Im scharfgeschalteten Zustand startet **Kabeltrennung** eine **Karenzzeit** (Standard 30 Sekunden).
3. Nach Ablauf (oder sofort bei Karenzzeit 0) laufen **Sicherheitsaktionen** (Sperre, Alarm, Abmelden, Shutdown, Skript).
4. Optionale **Netzwerk-Aktionen** (Webhook, VPN aus, SSH-Agent leeren, WLAN aus) laufen beim gleichen Trigger.

Im Zustand **unscharf** passiert beim Abziehen des Netzteils **nichts**.

---

## 2. Normalmodus — Alltag

### Scharf / unscharf

| Aktion | So geht's |
|--------|-----------|
| Scharfschalten | Menüleiste → **Schutz aktivieren** (oder **⌘A** bei offenem Menü) |
| Entschärfen | Menü → **Schutz deaktivieren** + Touch ID / Passwort |
| Ereignisprotokoll | **⌘L** oder Menü → **Event Log** |
| Einstellungen | **⌘,** oder Menü → **Einstellungen** |

### Karenzzeit (Grace Period)

- Countdown in der **Menüleiste** (außer im diskreten Modus — siehe §3).
- **Netzteil wieder einstecken** während der Karenz → Karenz **abgebrochen**, System bleibt **scharf**.
- **Karenz abbrechen** (wenn in Einstellungen → Allgemein erlaubt) → Touch ID / Passwort nötig.

### Aktionen konfigurieren

**Einstellungen → Security**

- Fünf Aktionstypen ein/aus, per Drag & Drop **sortieren**.
- Abschnitt **Network**: Webhook, VPN, SSH, WLAN, Fernauslösungs-Token.

### Fernauslösung (optional)

Wenn aktiviert unter **Einstellungen → Security → Remote Trigger**:

| URL | Wirkung |
|-----|---------|
| `magsafeguard://arm?token=IHR_TOKEN` | Scharfschalten ohne interaktive Auth (wenn unscharf) |
| `magsafeguard://trigger?token=IHR_TOKEN` | Aktionen im **normalen** Scharf-Modus |
| `magsafeguard://panic?token=IHR_TOKEN` | Panic-Reaktion im **Panic-Modus** (siehe §4) |

Aus **Shortcuts** auf iPhone/Mac. Token geheim halten.

---

## 3. Diskreter Betrieb (v0.4.3)

Für unauffälligen Einsatz (Café, Meeting): nur das **Menüleisten-Icon** ändert sich — keine Töne, keine macOS-Benachrichtigungen.

**Einstellungen → Notifications**

| Schalter | Wenn aus |
|----------|----------|
| Status-Benachrichtigungen | Keine Arm/Disarm-Toasts |
| Sicherheitswarnungen | Kein Grace-Banner; kein Countdown-Text in der Menüleiste |
| Kritischer Alarmton | Kein Signalton beim Grace-Start |

**Alle drei aus** → diskreter Betrieb (nur Icon). Karenz läuft weiter; Entschärfen weiter über das Menü.

---

## 4. Panic-Modus (v0.5.0)

**Panic** ist ein separates Hochsicherheits-Profil: **keine Karenzzeit**, **kein Abbruch** während der Reaktion, **sofortiger Shutdown** nach Sperre/Abmelden/Netzwerk-Aktionen. **Keine Datenlöschung.**

### Wann sinnvoll

Reise, riskante Umgebung, oder wenn der Mac bei Kabeltrennung sofort unbenutzbar sein soll — ohne 30 Sekunden Wartezeit.

### Panic aktivieren

1. Menüleiste → **Panic-Modus aktivieren…** (Kürzel **⌘P** bei offenem Menü).
2. **Beim ersten Mal:** kurzen Rechtshinweis lesen → **Verstanden — Panic aktivieren**.
3. Mit Touch ID / Passwort authentifizieren.
4. Menüleisten-Icon wechselt zum **Triggered**-Stil im Panic-Modus.

Panic verlassen: Menü → **Schutz deaktivieren** (normaler Entschärf-Flow).

### Panic auslösen (wenn panic-scharf)

| Auslöser | Wirkung |
|----------|---------|
| **Kabel trennen** | Sofortige Panic-Pipeline |
| **⌃⌘P** (Control+Command+P) | Gleich — **global**, solange MagSafe Guard läuft |
| `magsafeguard://panic?token=…` | Gleich — per Fernauslösung (Shortcuts, anderes Gerät) |

**⌃⌘P** Hinweise:

- **P** = Panic (leicht zu merken).
- **Control** vermeidet Konflikt mit **⌘P** (Drucken).
- Keine Accessibility-Berechtigung nötig.
- Nur im **Panic-Modus** aktiv; im Normal-/Unscharf-Zustand ignoriert.

### Was Panic tut

1. Netzwerk-Aktionen (falls aktiviert)
2. Bildschirm **zuerst** sperren, dann Abmelden/Alarm parallel
3. **Sofort herunterfahren** (kein 1-Minuten-macOS-Dialog)

**Nicht:** Dateien löschen, Laufwerke wischen oder Abbruch-Dialog.

### ⚠️ Warnungen

- **Nicht gespeicherte Arbeit kann verloren gehen.**
- Nur auf einem Rechner testen, den Sie herunterfahren können.
- **Dienstgeräte:** Arbeitgeber-Richtlinien prüfen.
- Netzteil wieder einstecken während der Panic-Reaktion **bricht Shutdown nicht ab**.

---

## 5. Normal vs. Panic — Kurzvergleich

| | Normal scharf | Panic scharf |
|---|---------------|--------------|
| Karenzzeit | 5–30 s (Standard 30) | **0 s** |
| Abbruch in Karenz | Ja (wenn erlaubt) | **Nein** |
| Kabel wieder ein bei Reaktion | Bricht Karenz ab | **Keine Wirkung** |
| Shutdown | Geplant (Verzögerung konfigurierbar) | **Sofort** |
| Hotkey | — | **⌃⌘P** |
| Datenlöschung | Nein | Nein |

**Paranoid-Modus** (Datenvernichtung) ist **nicht** implementiert — geplant v0.6.0.

---

## 6. Auto-Arm (optional)

**Einstellungen → Auto-Arm**

- Automatisch scharfschalten beim Verlassen eines vertrauenswürdigen Ortes oder in unbekanntem Netz.
- Nutzt `armAutomatically()` — kein Touch-ID-Dialog beim Auto-Arm (Absicht).
- Kann vorübergehend im Menü deaktiviert werden.

---

## 7. Fehlerbehebung

| Problem | Prüfen |
|---------|--------|
| Abziehen bewirkt nichts | System ist **unscharf** |
| Kein Menüleisten-Icon | App läuft? Menüleisten-Überlauf (•••) |
| Hotkey ⌃⌘P ohne Wirkung | Muss **panic-scharf** sein; App muss laufen |
| Fern-URL ignoriert | Token korrekt? Fernauslösung in Einstellungen aktiv? |
| Build nach ~7 Tagen abgelaufen | Personal Team — neu bauen mit `task release` oder Xcode |

Mehr: [maintainers/troubleshooting.md](../maintainers/troubleshooting.md)

---

## 8. Weiterführend

| Dokument | Zielgruppe |
|----------|------------|
| [operating-modes.md](operating-modes.md) | Zustandsmaschine & technische Abläufe |
| [panic-modes.md](panic-modes.md) | Panic/Paranoid-Design & Rechtliches |
| [behavior-gaps.md](behavior-gaps.md) | Behobene vs. offene UI/Laufzeit-Themen |
| [FORK_CHANGELOG.md](../FORK_CHANGELOG.md) | Release-Historie |
| [README.de.md](../../README.de.md) | Bauen, installieren, Roadmap |
