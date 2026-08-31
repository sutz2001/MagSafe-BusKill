# MagSafe Guard

<p align="center">
  <img src="https://raw.githubusercontent.com/sutz2001/MagSafe-BusKill/refs/heads/main/docs/assets/logo-256.png" width="128" alt="MagSafe Guard App-Icon" />
</p>

<p align="center">
  <strong>MagSafe Guard</strong><br>
  <em>Dein Sicherheits-Wächter für den Mac</em>
</p>

**Sprache:** Deutsch · [English (README.md)](README.md)

> **macOS-Sicherheitswerkzeug** — das Netzkabel als Dead-Man's-Switch. In der Menüleiste scharf schalten; beim Abziehen startet eine Grace Period, danach konfigurierbare Schutzaktionen.

Inspiriert von [BusKill](https://github.com/BusKill/buskill-app). Unabhängiger Fork von [lekman/magsafe-buskill](https://github.com/lekman/magsafe-buskill).

**CI:** Leichte Ubuntu-Checks bei Push/PR auf `main` (Commit-Messages). macOS-Tests und Security-Scans: lokal `task test` oder manuell unter [Actions](https://github.com/sutz2001/MagSafe-BusKill/actions).

| | |
| --- | --- |
| **Version** | `0.5.0` (Build `9`) |
| **Plattform** | macOS 13+ (Ventura) · Menüleisten-App |
| **Bundle ID** | `com.sutz2001.MagSafeGuard` |
| **Lizenz** | MIT — [`LICENSE`](LICENSE) · [`NOTICE`](NOTICE) |
| **Repository** | **Öffentlich** — [github.com/sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill) |

![Demo — Netzteil-Abzug löst Schutz aus (kein Mac App Store)](docs/assets/magsafe-guard.gif)

---

## Upstream & dieser Fork

| | |
| --- | --- |
| **Upstream** | [github.com/lekman/magsafe-buskill](https://github.com/lekman/magsafe-buskill) |
| **Entwicklung** | **Eigenständig** — siehe [docs/FORK_INDEPENDENCE.md](docs/FORK_INDEPENDENCE.md) |
| **Dieser Fork** | [github.com/sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill) |
| **Fork-Maintainer** | Marc Seitz |
| **Namensnennung** | [`LICENSE`](LICENSE) (Doppel-Copyright) · [`NOTICE`](NOTICE) (Herkunft) |

Upstream zielt auf Mac App Store und kostenpflichtige Apple-Funktionen. **Dieser Fork** setzt auf Personal Team, zweisprachige UI (EN/DE), eigene Versionierung, Release-Automatisierung (`task release`) und eine Roadmap zu Netzwerk-Aktionen und Panic-Modus — Verteilung über **GitHub + notarisierte DMG**, nicht über den App Store.

---

## Funktionsweise

```text
  disarmed ──scharf──► armed ──Kabel raus──► Grace Period ──► Sicherheitsaktionen
                         ▲            │                    │
                         │            └── Kabel rein ──────┘ (Karenz endet, bleibt armed)
                         └──── Auth (entschärfen / abbrechen) ────┘
```

| Zustand | Verhalten |
| --- | --- |
| **Disarmed** | Netzteil ziehen bewirkt **nichts** |
| **Armed** | Kabel-Abzug startet Grace Period (Standard **30 s**) |
| **Grace Period** | Countdown in der Menüleiste; Abbrechen per Touch ID / Passwort; **Kabel wieder einstecken beendet die Karenz — System bleibt armed** |
| **Triggered** | Konfigurierte Aktionen der Reihe nach |

**Alltag:** Menüleiste → **Scharf schalten** → mit Adapter arbeiten → bei Risiko Kabel ziehen oder Grace abwarten → Aktionen laufen.

**Ausführliche Beschreibung (Zustände, Grace, Auto-Arm, Fernauslösung):** [docs/features/operating-modes.md](docs/features/operating-modes.md) (EN)

| Tipp | |
| --- | --- |
| Ereignisprotokoll | **⌘L** oder Menü → Event Log |
| Sprache | Einstellungen → Allgemein → System / EN / DE |
| Grace Period | Einstellungen → Allgemein (5–30 s) |

---

## Funktionsumfang

| Bereich | Status | Hinweis |
| --- | --- | --- |
| Netzteil-Abzug (MagSafe, USB-C) | **Ausgeliefert** | IOKit, kein Kernel-Treiber |
| Scharf/Unscharf (Touch ID, Passwort) | **Ausgeliefert** | Überwachung nur wenn armed |
| Grace Period + Menüleisten-Countdown | **Ausgeliefert** | Standard 30 s |
| Sicherheitsaktionen (5 Typen) | **Ausgeliefert** | Sortierbar in Settings |
| Auto-Arm (Standort / Netzwerk) | **Ausgeliefert** | Optionale Berechtigungen |
| Event-Log, Onboarding, EN/DE | **Ausgeliefert** | v0.3.0 |
| Netzwerk-Aktionen + Fernauslösung | **Ausgeliefert** | v0.4.0 — Webhook, VPN, SSH, WLAN; `magsafeguard://` |
| Panic-Modus | **Ausgeliefert** | v0.5.0 — keine Karenzzeit, sofortiger Shutdown · [Design](docs/features/panic-modes.md) |
| Paranoid-Modus | **Geplant** | v0.6.0 — Vernichtung + Shutdown (FileVault + Setup nötig) |
| Notarisierte DMG für Dritte | **Später** | v1.0 · Paid Dev optional |
| Mac App Store | **Ausgeschlossen** | Sandbox inkompatibel |

### Sicherheitsaktionen

| Aktion | Wirkung |
| --- | --- |
| Bildschirm sperren | Display sofort sperren |
| Alarm | Alarmton in Schleife |
| Abmelden erzwingen | Alle Benutzer abmelden |
| Herunterfahren | Shutdown planen (Verzögerung konfigurierbar) |
| Eigenes Skript | `.sh` / `.zsh` / `.bash` nur aus erlaubten Pfaden |

**Pfade:** `~/.magsafe/scripts/` · `/usr/local/magsafe-scripts/`  
**Einstellungen → Security** — mit **+** / **−** / Drag & Drop.

---

## Bauen & starten

Benötigt **macOS 13+**, **Xcode 15+** und [Task](https://taskfile.dev) (`brew install go-task/tap/go-task`).  
Eine **kostenlose Apple-ID** (Personal Team) reicht für den eigenen Mac.

### Schnellstart

```bash
git clone https://github.com/sutz2001/MagSafe-BusKill.git
cd MagSafe-BusKill
task setup
open MagSafeGuard.xcodeproj
```

In Xcode: **MagSafeGuard** → **Signing & Capabilities** → **Team** wählen → **⌘R**.  
Die App sitzt in der **Menüleiste**, nicht im Dock.

```bash
task run          # Alternative: Debug-Build per Terminal starten
```

### Entwicklung

```bash
task build        # SPM-Build
task test         # SPM-Tests + Coverage (siehe docs/maintainers/testing-guide.md)
task xcode:test   # App-Unit-Tests in Xcode
task qa:quick     # Lint & Security
task qa           # volle lokale QA
```

### Release (Alltagsnutzung auf dem eigenen Mac)

```bash
task release              # Version → Tests → Release-.app → DMG → SHA256
task release:install      # nach /Applications
task release:open         # DMG im Finder
```

Ausgabe: `dist/` (`.app`, `.dmg`, `SHA256SUMS`).

<details>
<summary>Release-Optionen (erweitert)</summary>

```bash
SKIP_TESTS=true task release
SIGN_MODE=adhoc task release:build
SIGN_MODE=unsigned task release:build
task release:clean
```

</details>

**Hinweis Signing:** Personal-Team-Builds laufen nach ~7 Tagen ab — neu bauen mit `task release` oder ⌘R. Normales Apple Code Signing.

---

## Verteilung

| Ziel | Kostenpflichtiger Apple Developer (99 €/Jahr)? |
| --- | --- |
| Quellcode klonen & selbst bauen | Nein — kostenlose Apple-ID |
| Quellcode auf GitHub veröffentlichen | Nein |
| Eigene `.dmg` als GitHub-Release (nur für dich) | Nein |
| Fremde installieren `.dmg` ohne Gatekeeper-Warnung | Ja — Developer ID + Notarisierung |
| Mac App Store | Nicht geplant |

**Modell:** Open Source auf GitHub; Nutzer **kompilieren selbst** oder nutzen eine **notarisierte DMG**, sobald verfügbar.

---

## Roadmap

| Phase | Version | Schwerpunkt |
| --- | --- | --- |
| Jetzt | **0.3.0** | Kern-Dead-Man's-Switch, Event-Log, i18n, `task release` |
| Als Nächstes | **0.4.0** | Netzwerk-Aktionen + Fernauslösung |
| Danach | **0.5.0** | Panic-Modus — sofort Shutdown, 0 Grace |
| Anschließend | **0.6.0** | Paranoid-Modus — Datenvernichtung (Setup nötig) |
| Stabil | **1.0.0** | Notarisierte Developer-ID-Verteilung |

Details: **[docs/FORK_ROADMAP.md](docs/FORK_ROADMAP.md)** · Releases: **[docs/FORK_CHANGELOG.md](docs/FORK_CHANGELOG.md)**

### Vor Panic & Paranoid

> Design: **[docs/features/panic-modes.md](docs/features/panic-modes.md)**

**Panic (v0.5.0)** — kurzer Hinweis beim ersten Aktivieren:

- [ ] Kurzer Wirkhinweis (DE + EN): ungespeicherte Arbeit, kein Abbruch nach Auslösung, Vorsicht Dienstgerät
- [ ] Eine starke Bestätigung zum Arming (kein Codewort)
- [ ] Kein destruktiver Testlauf in Produktions-Builds

**Paranoid (v0.6.0)** — volle Checkliste:

- [ ] Voller Rechtshinweis (DE + EN): irreversibler Datenverlust, eigene Verantwortung, Dienstgerät-Warnung
- [ ] Doppelte Bestätigung + Pflicht-Codewort
- [ ] Setup-Wizard (FileVault, Wipe-Pfade/Volumes)
- [ ] Rechtliche Prüfung DE/EU (keine Rechtsberatung — ggf. Anwalt)

---

## Repository-Sichtbarkeit

Das Repository ist **öffentlich** unter [github.com/sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).

| Anforderung | Status |
| --- | --- |
| [`LICENSE`](LICENSE) — MIT, Upstream- + Fork-Copyright | Erledigt |
| [`NOTICE`](NOTICE) — Attribution, Upstream-Link, BusKill | Erledigt |
| README — Fork vs. Upstream, Maintainer, Lizenz | Erledigt |
| Binaries enthalten `LICENSE` + `NOTICE` | Offen (bei GitHub Releases) |
| Panic-Rechtstexte in der App | Erst ab v0.5.0 relevant |

Die ersten drei Punkte wurden auf `main` geprüft, bevor das Repository öffentlich gestellt wurde (August 2026).

---

## Fork-spezifisch

| Punkt | Wert |
| --- | --- |
| Bundle ID | `com.sutz2001.MagSafeGuard` |
| Grace Period Standard | 30 s |
| iCloud / Push | Aus Entitlements entfernt |
| Version | [`version.json`](version.json) → `task version:sync` |

```bash
task version:show
task version:bump:patch
task version:bump:minor
```

Optionaler Upstream-Vergleich (nur manuell): `git fetch upstream && git merge upstream/main` — für die Fork-Entwicklung nicht erforderlich.

---

## Dokumentation

| Dokument | Inhalt |
| --- | --- |
| [README.md](README.md) | Englische Version |
| [docs/FORK_ROADMAP.md](docs/FORK_ROADMAP.md) | Roadmap & Rechtliches |
| [docs/FORK_CHANGELOG.md](docs/FORK_CHANGELOG.md) | Fork-Release-Historie |
| [docs/maintainers/building-and-running.md](docs/maintainers/building-and-running.md) | Ausführliche Build-Anleitung |
| [docs/maintainers/code-signing.md](docs/maintainers/code-signing.md) | Signing & Verteilung |
| [AGENTS.md](AGENTS.md) | Mitwirkenden- & KI-Regeln |

---

## Lizenz & Haftung

**MIT-Lizenz** — siehe [`LICENSE`](LICENSE) und [`NOTICE`](NOTICE). Weitergabe nur mit Copyright- und Permission-Hinweis.

- Konzept: [BusKill](https://github.com/BusKill/buskill-app)
- Upstream: Tobias Lekman · [lekman/magsafe-buskill](https://github.com/lekman/magsafe-buskill)
- Fork-Anpassungen: Marc Seitz © 2025

MagSafe Guard wird **ohne Gewähr** bereitgestellt. Du trägst die Verantwortung für den Einsatz — auch auf Dienstgeräten und mit eigenen Skripten.
