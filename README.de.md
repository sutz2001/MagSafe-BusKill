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
| **Version** | `0.6.0` (Build `20`) |
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

Upstream zielt auf Mac App Store und kostenpflichtige Apple-Funktionen. **Dieser Fork** setzt auf Personal Team, zweisprachige UI (EN/DE), Betriebsmodus-Voreinstellungen, Netzwerk-Aktionen, Panic-Modus, Release-Automatisierung (`task release`) und **GitHub + notarisierte DMG** — nicht über den App Store.

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

**Kurzanleitung (Normal, diskret, Panic):** [docs/features/user-guide.de.md](docs/features/user-guide.de.md) · [EN](docs/features/user-guide.md)

**Ausführliche Beschreibung (Zustände, Grace, Auto-Arm, Fernauslösung):** [docs/features/operating-modes.md](docs/features/operating-modes.md) (EN)

| Tipp | |
| --- | --- |
| Ereignisprotokoll | **⌘L** oder Menü → Event Log |
| Sprache | Einstellungen → Allgemein → System / EN / DE |
| Betriebsmodus & Karenz | Einstellungen → **Security** (Normal / Diskret / Panic) |
| Nur Menüleiste | Einstellungen → Allgemein → **Im Dock anzeigen** aus (Standard) |

---

## Funktionsumfang

| Bereich | Status | Hinweis |
| --- | --- | --- |
| Netzteil-Abzug (MagSafe, USB-C) | **Ausgeliefert** | IOKit, kein Kernel-Treiber |
| Scharf/Unscharf (Touch ID, Passwort) | **Ausgeliefert** | Überwachung nur wenn armed |
| Grace Period + Menüleisten-Countdown | **Ausgeliefert** | Standard 30 s; Presets 20 s (Diskret) / 5 s (Panic-Profil) |
| Betriebsmodi (Normal / Diskret / Panic) | **Ausgeliefert** | v0.5.1 — Einstellungen → Security · [Anleitung](docs/features/user-guide.de.md#2-betriebsmodi-einstellungs-presets) |
| Sicherheitsaktionen (5 Typen) | **Ausgeliefert** | Sortierbar unter Einstellungen → Security |
| Auto-Arm (Standort / Netzwerk) | **Ausgeliefert** | Optionale Berechtigungen |
| Event-Log, Onboarding, EN/DE | **Ausgeliefert** | v0.3.0 |
| Netzwerk-Aktionen + Fernauslösung | **Ausgeliefert** | v0.4.0 — Webhook, VPN, SSH, Zwischenablage, WLAN; `magsafeguard://` |
| Diskreter Betrieb | **Ausgeliefert** | v0.4.3+ — Profil **Diskret** oder Mitteilungs-Schalter · [Anleitung](docs/features/user-guide.de.md#4-diskreter-betrieb) |
| Panic-Modus | **Ausgeliefert** | v0.5.0 — 0 s Karenz im Panic-Schutz, **⌃⌘P** · [Anleitung](docs/features/user-guide.de.md#5-panic-schutzmodus-v050) |
| Paranoid-Modus | **Ausgeliefert** | v0.6.0 — Wipe + Shutdown; FileVault + Setup + Codewort · [Anleitung](docs/features/user-guide.de.md#6-paranoid-schutzmodus-v060) |
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

### Netzwerk-Aktionen

| Aktion | Wirkung |
| --- | --- |
| HTTP-Webhook | JSON-POST beim Trigger (Token im Schlüsselbund) |
| VPN trennen | Aktive VPN-Verbindung beenden |
| SSH-Agent leeren | Schlüssel aus `ssh-agent` entfernen |
| Zwischenablage leeren | System-Zwischenablage leeren |
| WLAN deaktivieren | Wi‑Fi aus (Hinweis zu „Mein Mac finden“) |

**Einstellungen → Security** (Abschnitt Network). **Panic**-Preset aktiviert VPN, SSH-Agent und Zwischenablage (kein WLAN aus — Find My bleibt).

**Skript-Pfade:** `~/.magsafe/scripts/` · `/usr/local/magsafe-scripts/`  
**Trigger-Skripte (mitgeliefert):** [`MagSafeGuard/Resources/TriggerScripts/`](MagSafeGuard/Resources/TriggerScripts/) — in der App enthalten; README dort für Installation nach `~/.magsafe/scripts/`  
Sicherheitsaktionen: **Einstellungen → Security** — **+** / **−** / Drag & Drop.

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
| Erledigt | **0.4.x** | Netzwerk-Aktionen, Fernauslösung, diskreter Betrieb |
| Erledigt | **0.5.0** | Panic-Modus — 0 Grace, Hotkey **⌃⌘P**, sofort Shutdown |
| Erledigt | **0.5.1** | Betriebsmodi, Zwischenablage-Aktion, Settings/Doku |
| Erledigt | **0.5.2** | Optionale farbige Menüleisten-Icons (Standard: monochrom) |
| Erledigt | **0.5.3** | Grace-Zuverlässigkeit, Alarm-Einstellungen, diskreter Menüleisten-Puls |
| Erledigt | **0.5.4** | Shutdown nach Bildschirmsperre (Timer + Reihenfolge) |
| Erledigt | **0.5.5** | Trigger-Pipeline: Hygiene-Phase, Skript-Budget, Logout + sofort Shutdown |
| Erledigt | **0.5.6** | Einsteiger-Preset, Risiko-Labels, Erst-Scharf-Hinweis, `magsafeguard-cli` |
| Erledigt | **0.5.7** | Onboarding aufgeteilt (Alltag vs. Panic/Paranoid), CLI in Kurzanleitung |
| Erledigt | **0.5.8** | Auswerfen entfernbarer Volumes (Hygiene) |
| Erledigt | **0.5.9** | Cryptomator/Bluetooth-Hygiene, gebündelte Trigger-Skripte |
| Erledigt | **0.6.0** | Paranoid-Modus — Wipe, FileVault-Gate, Codewort, **⌃⌘⇧P**, `magsafeguard://paranoid` |
| Stabil | **1.0.0** | Notarisierte Developer-ID-Verteilung |

Details: **[docs/FORK_ROADMAP.md](docs/FORK_ROADMAP.md)** · Releases: **[docs/FORK_CHANGELOG.md](docs/FORK_CHANGELOG.md)** · **Kurzanleitung:** [DE](docs/features/user-guide.de.md) · [EN](docs/features/user-guide.md)

### Paranoid-Modus (v0.6.0 — ausgeliefert)

> Details: **[docs/features/panic-modes.md](docs/features/panic-modes.md)** · [Kurzanleitung §6](docs/features/user-guide.de.md#6-paranoid-schutzmodus-v060)

- [x] Voller Rechtshinweis (DE + EN): irreversibler Datenverlust, eigene Verantwortung, Dienstgerät-Warnung
- [x] Doppelte Bestätigung + Pflicht-Codewort
- [x] Setup-Wizard (FileVault, Wipe-Pfade/Volumes)
- [ ] Rechtliche Prüfung DE/EU vor breiter öffentlicher Beta — [Checkliste](docs/maintainers/legal-review-gate.md) (keine Rechtsberatung — ggf. Anwalt)

**Panic (v0.5.0)** und **Paranoid (v0.6.0)** sind ausgeliefert — siehe [Kurzanleitung](docs/features/user-guide.de.md).

---

## Repository-Sichtbarkeit

Das Repository ist **öffentlich** unter [github.com/sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).

| Anforderung | Status |
| --- | --- |
| [`LICENSE`](LICENSE) — MIT, Upstream- + Fork-Copyright | Erledigt |
| [`NOTICE`](NOTICE) — Attribution, Upstream-Link, BusKill | Erledigt |
| README — Fork vs. Upstream, Maintainer, Lizenz | Erledigt |
| Binaries enthalten `LICENSE` + `NOTICE` | Offen (bei GitHub Releases) |
| Panic-Rechtstexte in der App | Ausgeliefert in v0.5.0 (kurzer Hinweis DE/EN beim ersten Arming) |

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
| [docs/features/user-guide.de.md](docs/features/user-guide.de.md) | **Kurzanleitung** — Betriebsmodi, diskret, Panic · [EN](docs/features/user-guide.md) |
| [docs/features/operating-modes.md](docs/features/operating-modes.md) | Zustandsmaschine & technische Abläufe |
| [`MagSafeGuard/Resources/TriggerScripts/SCRIPTS.md`](MagSafeGuard/Resources/TriggerScripts/SCRIPTS.md) | Mitgelieferte Trigger-Skripte (auch in .app) |
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
- Fork-Anpassungen: Marc Seitz © 2026

MagSafe Guard wird **ohne Gewähr** bereitgestellt. Du trägst die Verantwortung für den Einsatz — auch auf Dienstgeräten und mit eigenen Skripten.
