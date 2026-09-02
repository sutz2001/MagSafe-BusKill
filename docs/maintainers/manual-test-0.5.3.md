# Manuelle Testliste v0.5.3

**Ziel:** Release **0.5.3** (Build 12) als Daily Driver verifizieren.  
**App:** `/Applications/MagSafeGuard-0.5.5.app` (Release-Build; Spotlight: „MagSafe Guard“)  
**Datum gestartet:** ___________ · **Tester:** Marc

> Häkchen in Cursor/VS Code oder GitHub setzen (`- [x]`). Bereits in der Dev-Session verifizierte Punkte sind vorausgefüllt.

---

## Vorbereitung

- [ ] Wichtige Arbeit gespeichert; Test-User oder Test-Session wenn Logout/Shutdown getestet wird
- [ ] Alte Debug-Instanz beendet (nur eine MagSafeGuard-Version läuft)
- [ ] Release in `/Applications` installiert (`task release:install`)
- [ ] About-Box zeigt **0.5.3 (12)**

---

## 1. Basis — Arm / Disarm

- [ ] App startet aus `/Applications`; Icon in der Menüleiste sichtbar
- [ ] **Arm Protection** → Touch ID / Passwort → Status „Disarm Protection“
- [ ] **Disarm Protection** → Auth → wieder disarmed
- [ ] Auth-Abbruch → bleibt disarmed, kein Crash

---

## 2. Grace Period (Normal, Grace z. B. 30 s)

- [ ] Armed → Netzteil ziehen → **Countdown** im Menüleisten-Icon (z. B. `! 30s`)
- [x] Countdown **tickt runter** (nicht bei 30 s hängen) *(0.5.3 Dev-Session)*
- [ ] Grace-**Popup** erscheint zentriert (wenn Security Alerts an)
- [ ] **Reconnect** während Grace → Grace abgebrochen, bleibt armed
- [ ] Erneut ziehen → Grace startet wieder
- [ ] **Cancel Grace** (wenn erlaubt) → Auth nötig
- [ ] Nach Ablauf: **Security Actions** laufen (mind. Lock) *(Logout getestet, Dev-Session)*
- [ ] **Shutdown:** nach Logout **sofort** (keine 30-s-Wartezeit)
- [ ] **Hygiene-Phase:** Clipboard + SSH innerhalb ~2 s, dann Webhook, VPN nur mit Restzeit
- [ ] **Script-Budget:** Standard **3 s** (Settings → Erweitert → Eigene Skripte), `0` = überspringen
- [ ] **Event Log** zeigt Disconnect + Grace / Actions

---

## 3. Alarm (Settings → Security → Sound Alarm)

- [ ] **Sound Alarm** aktiv → Sirene hörbar (nicht nur leises System-Beep)
- [x] **Alarm volume** Slider wirkt *(Dev-Session)*
- [x] **Boost system volume** an/aus spürbarer Unterschied *(Dev-Session)*
- [x] **Alarm duration** stoppt nach eingestellter Zeit *(Dev-Session)*
- [ ] Duration **0** (= endlos) → manuell disarm stoppt Alarm

---

## 4. Diskreter Betrieb

- [ ] Preset **Discreet** oder alle drei Notification-Toggles aus:
  - [ ] Keine Toasts / kein Grace-Banner
  - [ ] Kein Countdown-Text im Icon (Icon-Zustand ändert sich trotzdem)
- [x] **Grace-Puls** in den letzten 10 s (Menüleiste, dezent) *(Dev-Session)*
- [ ] Toggle einzeln wieder an → erwartetes Feedback zurück

---

## 5. Menüleiste & Settings

- [ ] Icon in Hell/Dunkel lesbar; ggf. Overflow-Menü (•••)
- [x] **Colored menu bar icons** — Akzentfarben pro Zustand *(Dev-Session)*
- [x] **Settings** öffnet stabil (kein Verschwinden beim ersten Klick) *(Dev-Session)*
- [ ] **Launch at login** + **Show in Dock** funktionieren
- [ ] Security-Tab: Aktionsreihenfolge ändern → **Relaunch** → Reihenfolge bleibt + wirkt beim Trigger
- [ ] iCloud-Tab **nicht sichtbar** (Personal Team) — erwartetes Verhalten
- [ ] EN/DE: Menüs und Grace-Texte plausibel

---

## 6. Netzwerk & Remote (optional)

Nur wenn du diese Features nutzt:

- [ ] Webhook / VPN / SSH / Clipboard bei Trigger
- [ ] `magsafeguard://arm?token=…` → armed ohne Touch ID
- [ ] `magsafeguard://trigger?token=…` → Actions wenn armed

---

## 7. Panic-Modus ⚠️ kontrolliert

**Echter Shutdown.** Nur auf Gerät testen, das du wieder einschalten kannst.

- [ ] **Arm Panic Mode…** → Rechtshinweis → Auth → eigenes Icon
- [ ] Netzteil ziehen → **keine Grace**, sofort Shutdown-Pipeline
- [ ] **⌃⌘P** nur wenn panic-armed → gleiche Reaktion
- [ ] Hotkey/URL **ignoriert** wenn nicht panic-armed
- [ ] Disarm panic → normales Verhalten
- [ ] Grace-Puls in Panic: letzte **5 s** (wenn diskret + Grace theoretisch — Panic hat 0 Grace; Puls-Policy separat prüfen falls relevant)

---

## 8. Regression

- [ ] **Sleep / Wake** while armed → App läuft weiter
- [ ] **Auto-arm** (falls aktiv): arms ohne Touch ID nach Regel
- [ ] Quit während Grace → Warnung wenn Grace läuft
- [ ] Settings überleben App-Neustart

---

## 9. Daily Driver (1 Woche)

- [ ] **Tag 1–3:** Armed im Alltag, kein Blocker
- [ ] **Tag 4–7:** Weiter armed, keine P0/P1-Bugs
- [ ] Notizen zu Auffälligkeiten:

```text
_____________________________________________
_____________________________________________
_____________________________________________
```

---

## Ergebnis

| | |
|---|---|
| **Release für Daily Driver freigegeben?** | [ ] Ja · [ ] Nein (Issues anlegen) |
| **GitHub Release v0.5.3?** | [ ] Ja · [ ] Später |
| **Datum abgeschlossen** | ___________ |

**Issues / Notizen:** [behavior-gaps.md](../features/behavior-gaps.md) · GitHub Issues

---

*Siehe auch: [stabilization-checklist.md](stabilization-checklist.md) · [acceptance-tests.md](acceptance-tests.md)*
