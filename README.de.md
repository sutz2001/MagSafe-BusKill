# MagSafe Guard

**Sprache:** Deutsch · [English (README.md)](README.md)

macOS-Menüleisten-App, die das Netzkabel als Dead-Man's-Switch nutzt: Im Zustand **armed** startet beim Abziehen des Adapters eine **Grace Period**, danach laufen konfigurierbare Sicherheitsaktionen (Bildschirmsperre, Alarm, Abmelden, Herunterfahren oder eigenes Skript).

Inspiriert von [BusKill](https://github.com/BusKill/buskill-app). Upstream: [lekman/magsafe-buskill](https://github.com/lekman/magsafe-buskill). Dieser Fork: [sutz2001/MagSafe-BusKill](https://github.com/sutz2001/MagSafe-BusKill).

![Demo](docs/assets/magsafe-guard.gif)

---

## Was die App heute kann

| Bereich | Status | Hinweis |
|---------|--------|---------|
| Netzteil-Abzug erkennen | ✅ | MagSafe, USB-C, Drittanbieter |
| Scharf-/Unscharfschalten (Touch ID / Passwort) | ✅ | Nur im Zustand **armed** wird überwacht |
| Grace Period (Standard **30 s**, Bereich 5–30 s) | ✅ | Abbrechen per Auth möglich (wenn aktiviert) |
| Menüleiste & Einstellungen | ✅ | Kein normales App-Fenster |
| Sicherheitsaktionen (siehe unten) | ✅ | Reihenfolge in den Settings |
| Mitteilungen | ✅ | macOS fragt beim ersten Start |
| Auto-Arm (Standort / Netzwerk) | ✅ | Optional; Standort-Berechtigung nötig |
| Rate Limiting & Circuit Breaker | ✅ | Verhindert Aktions-Stürme |
| iCloud / CloudKit-Sync | ⚠️ Teilweise | **Kostenpflichtiger Apple-Developer-Account** nötig; in diesem Fork für Personal Team aus Entitlements entfernt |
| Push Notifications | ⚠️ Teilweise | Wie iCloud — mit kostenlosem Personal Team nicht nutzbar |
| Mac App Store | ❌ Noch nicht | Upstream: „coming soon“ |
| Volume auswerfen / Festplatte löschen | ❌ Nicht eingebaut | Nur per Custom Script möglich |
| Netzwerk-Aktionen | ❌ Nicht implementiert | Upstream geplant |
| Evidence / Log-Viewer-UI | 🔄 Upstream in Arbeit | Code teilweise vorhanden |

**Wichtig:** Im Zustand **disarmed** passiert beim Netzteil-Ziehen **nichts**.

---

## Sicherheitsaktionen

Definiert in `SecurityActionType` (`MagSafeGuardLib/.../SecurityActionProtocols.swift`).

| Aktion | Implementiert | Wirkung |
|--------|---------------|---------|
| **Bildschirm sperren** | ✅ | Display sperren (`pmset displaysleepnow`) |
| **Alarm** | ✅ | `alarm.wav` oder System-Beep in Schleife |
| **Abmelden erzwingen** | ✅ | Alle Benutzer abmelden (AppleScript) |
| **Herunterfahren** | ✅ | Shutdown planen (Standard-Verzögerung **30 s**) |
| **Eigenes Skript** | ✅ | Nur `.sh` / `.zsh` / `.bash` aus erlaubten Ordnern |

**Standard:** Bildschirm sperren + Alarm. Unter **Settings → Security** mit **+** hinzufügen, mit **−** entfernen (mindestens eine Aktion aktiv), per Drag & Drop sortieren.

**Erlaubte Skript-Pfade:**

- `~/.magsafe/scripts/`
- `/usr/local/magsafe-scripts/`

Skripte werden validiert (kein `..`, keine gefährlichen Befehle, ausführbar).

**Nicht als feste Aktionen:** Volume auswerfen, Remote-Wipe, Find My — nur per Custom Script.

---

## Ablauf

```text
disarmed → armed → Grace Period (30 s Standard) → Sicherheitsaktionen
              ↑              ↓
              └── Auth (entschärfen / Grace abbrechen)
```

1. In der Menüleiste **scharf schalten** (Auth nötig).
2. Normal arbeiten, Netzteil bleibt drin.
3. Kabel raus → Grace Period läuft.
4. Optional mit Touch ID / Passwort abbrechen.
5. Nach Ablauf: konfigurierte Aktionen der Reihe nach.

---

## Bauen & starten (dieser Fork)

### Voraussetzungen

- macOS **13+**
- **Xcode 15+**
- [Task](https://taskfile.dev): `brew install go-task/tap/go-task`

### Ersteinrichtung

```bash
git clone https://github.com/sutz2001/MagSafe-BusKill.git
cd MagSafe-BusKill
task setup
open MagSafeGuard.xcodeproj
```

In Xcode:

1. Target **MagSafeGuard** → **Signing & Capabilities**
2. **Team:** deine Apple-ID (**Personal Team** reicht für lokale Entwicklung)
3. **Bundle ID:** `com.sutz2001.MagSafeGuard`
4. **Kein** iCloud / Push bei kostenlosem Account — in diesem Fork bereits aus Entitlements entfernt
5. **⌘R** — App erscheint in der **Menüleiste**

### Kommandozeile

```bash
task build
task test
task run            # Menüleisten-App starten
```

App beenden: Menüleiste → Beenden, oder **⌘.** in Xcode.

---

## Apple-Signing: kostenlos vs. bezahlt

| Thema | Personal Team (kostenlose Apple-ID) | Developer Program (99 €/Jahr) |
|-------|-------------------------------------|----------------------------------|
| Auf **eigenem** Mac bauen & starten | ✅ | ✅ |
| iCloud / CloudKit in der App | ❌ | ✅ |
| Push Notifications | ❌ | ✅ |
| Verteilung an andere / Notarisierung | ❌ | ✅ |
| TestFlight / App Store | ❌ | ✅ |

### Läuft der Build ab?

- **Der Quellcode läuft nicht ab** — jederzeit neu bauen.
- **Entwickler-Builds** nutzen ein **Provisioning Profile**, das abläuft (Personal Team typisch **~7 Tage**).
- Danach startet die App ggf. **nicht mehr**, bis du in Xcode neu baust (**⌘R**). Xcode erneuert das Profil.
- Bezahlter Account: längere Zertifikate (~1 Jahr), gleiches Prinzip.
- Das ist **kein Trial** von MagSafe Guard, sondern normales Apple Code Signing.

---

## Fork-spezifische Anpassungen

| Punkt | Dieser Fork |
|-------|-------------|
| Bundle ID | `com.sutz2001.MagSafeGuard` |
| Team | Dein Personal Team |
| Entitlements | Ohne iCloud/Push (Personal Team) |
| Grace Period Standard | **30 Sekunden** |
| CI Scorecard | Übersprungen bei privaten Repos |
| Config-Namen | `.defaultConfig` (Upstream-Umbenennung) |

Upstream holen:

```bash
git fetch upstream
git merge upstream/main
```

---

## Versionierung

**Zentrale Datei:** [`version.json`](version.json)

| Feld | Aktuell (Fork) | Bedeutung |
|------|----------------|-----------|
| `marketingVersion` | **0.2.0** | Semver für Nutzer |
| `buildNumber` | **1** | Build-Nummer (Xcode) |

```bash
task version:show
task version:sync
task version:bump:patch    # 0.2.0 → 0.2.1
task version:bump:minor    # 0.2.0 → 0.3.0
```

Fork-Version unabhängig vom Upstream (`1.11.0`). In Swift: `AppVersion.marketing`.

---

## Tests & Qualität

```bash
task test
task qa:quick
task qa
```

CI auf GitHub Actions. Details: [docs/devops/ci-cd-workflows.md](docs/devops/ci-cd-workflows.md).

---

## Dokumentation

| Dokument | Zielgruppe |
|----------|------------|
| [README.md](README.md) | Englische Version |
| [AGENTS.md](AGENTS.md) | KI-Agenten-Index (Cursor + Copilot — gemeinsam pflegen) |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | GitHub-Copilot-Regeln |
| [.cursor/rules/project-conventions.mdc](.cursor/rules/project-conventions.mdc) | Cursor-Regeln |
| [docs/README.md](docs/README.md) | Vollständiger Doku-Index (Upstream) |
| [docs/maintainers/building-and-running.md](docs/maintainers/building-and-running.md) | Ausführliche Build-Anleitung |
| [docs/maintainers/code-signing.md](docs/maintainers/code-signing.md) | Signing & Verteilung |

---

## Lizenz & Danksagung

MIT — siehe [LICENSE](LICENSE).

- Konzept: [BusKill](https://github.com/BusKill/buskill-app)
- Upstream: [lekman/magsafe-buskill](https://github.com/lekman/magsafe-buskill)
