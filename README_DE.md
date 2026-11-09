# foxdock-themes

Das Plugin `themes` für FoxDock, das Plugin-System für die IDE von Visual FoxPro 9. Farbthemen für die IDE: Syntaxfarben, Editorschrift sowie Schrift und Farben des Hauptfensters.

> Auch auf Englisch ([README.md](README.md)) und Spanisch ([README_ES.md](README_ES.md)).

## Installieren

Sie brauchen FoxDock und [FoxPack](https://irwinrodriguez.dev/products/foxpack).

- In FoxDock: **FoxDock > Plugins > Plugin-Center...**, **Verfügbar**, `themes` auswählen und **Installieren** drücken.
- Von der Konsole: `foxpack plugin add themes`.

Wenn `themes` mit Ihrem FoxDock-Installer kam, zeigt das Plugin-Center seine neuen Versionen unter **Aktualisierungen**.

## Das Plugin `themes`

Es ändert in einem Schritt die Syntaxfarben, die Schrift des Programm-Editors und die Schrift und die
Farben des Hauptfensters (`_SCREEN`), über **FoxDock > Designs** (FoxDock > Themes).

```
VFP classic
• Dark                 (the current theme has «•»)
Dracula
GitHub dark
GitHub light
Gruvbox dark
Light
Monokai
Nord
One dark
One light
Solarized dark
Solarized light
Tokyo Night
---
VFP-Farben wiederherstellen
Design-Ordner öffnen
```

**Was ein Farbschema abdeckt, und wann Sie es sehen.**

| Teil | Wo es geschrieben wird | Wann Sie es sehen |
|---|---|---|
| Die Syntaxfarben: Kommentar, Schlüsselwort, Konstante, normal, Operator, Zeichenkette und Variable, jede mit ihrem Text und ihrem Hintergrund | die Registrierung (der Schlüssel des VFP, in dem es läuft: `HKCU\Software\Microsoft\VisualFoxPro\9.0\Options` in VFP 9, `...\VisualFoxPro\10.2\Options` oder `...\VisualFoxPro64\10.2\Options` in VFP Advanced; die sieben Werte `Editor*Color`) und `SYS(3056, 1)` | **sofort**, in den offenen Editoren und in den neuen |
| Die Schrift des Programm-Editors | `Options\IDE\ProgramFont`, nach dem erneuten Einlesen (das erneute Einlesen würde sie überschreiben) | in den Programm-Editoren, die Sie **danach** öffnen. Der schon offene behält seine Schrift |
| Die Schrift und die Farben von `_SCREEN` | per Code | sofort. VFP speichert die Schrift beim Beenden, die Farben nicht: Das Plugin setzt sie bei jedem Start |

**Was es nicht abdeckt.** Jedes Farbschema nennt es in seinem `notCovered`, und `ide_set_theme` gibt es
zurück:
- **Die Schrift des Editors, wenn Ihre Ressourcendatei (`FOXUSER.DBF`) eine eigene Standardschrift hat**
  (Edit › Properties › «Use as default»): Die der Ressource gewinnt. Sie erreicht auch keine Datei, deren
  Fenster schon in der Ressource gespeichert ist. **FoxDock schreibt Ihre Ressourcendatei nicht.** Wenn
  Sie das Farbschema anwenden, warnt das Protokoll davor, und `ide_set_theme` antwortet
  `editorFont: overriddenByResource`.
- Die Fenster des Debuggers, das Befehlsfenster, die Methoden-Editoren der Designer und die Text- und
  Memo-Editoren: mit einem Farbschema nicht getestet.
- VFP Advanced: Jede Version hat ihren eigenen Schlüssel, ihre eigene Sicherung (`backup-10.2.json`, `backup-10.2-x64.json`) und ihr eigenes aktuelles Thema; ein Thema, das Sie in VFP Advanced setzen, ändert VFP 9 nicht.

**Die Sicherung und «VFP-Farben wiederherstellen» (Restore VFP colors).** Vor dem ersten Farbschema hält das Plugin in
`<themes folder>\backup\backup.json` fest, was in jedem Wert stand, den es schreiben kann (oder dass er
nicht existierte), und die Schrift und die Farben von `_SCREEN`. «VFP-Farben wiederherstellen» kehrt dahin zurück,
**auch in den offenen Editoren**, und lässt die Sicherung, wo sie ist. Wenn Sie nach dem ersten
Farbschema in den Optionen von Hand Farben ändern, kehrt «Restore» zu dem zurück, was vor dem ersten
Farbschema war, und nicht zu Ihren Änderungen.

**Deinstallieren mit einem gesetzten Farbschema.** VFP malt die Editoren und das Befehlsfenster mit den
Farben, die es beim Öffnen aus der Registry liest; sie blieben also nach dem Deinstallieren von FoxDock. Solange
ein Farbschema gesetzt ist, legt das Plugin neben die Sicherung eine `restore.reg` (`restore-10.2.reg` in
VFP Advanced) mit den Werten von vorher, und das Deinstallationsprogramm importiert sie: Die Farben kehren
dahin zurück, wo «VFP-Farben wiederherstellen» sie lassen würde. «VFP-Farben wiederherstellen» löscht sie, denn dann gibt es
nichts rückgängig zu machen.

Das Plugin schreibt **nur seine eigenen Werte**. Es ruft nie `SYS(3056, 2)` auf, das alle Ihre Optionen
auf einmal schreiben würde (es ist dasselbe wie «Set As Default»).

**Die Optionen** (`"options": { "themes": { ... } }`):
- `current`: das aktuelle Farbschema (seine Id, der Name der Datei). Es wird beim Start der IDE
  angewendet, und geschrieben wird nur, was noch nicht da ist.
- `folder`: ein anderer Ordner für die Farbschemata statt `plugins\themes\themes\`.

**Ein Farbschema** ist eine flache `.json` in UTF-8 in diesem Ordner. Seine Id ist der Name der Datei:

```json
{
  "name": "Dark",
  "commentFore": "#6A9955", "commentBack": "#1E1E1E",
  "keywordFore": "#569CD6", "keywordBack": "#1E1E1E",
  "editorFont": "Consolas", "editorFontSize": 10,
  "screenFont": "Consolas", "screenBack": "#1E1E1E", "screenFore": "#D4D4D4",
  "notCovered": "What this theme does not cover."
}
```

- Die Elemente sind `comment`, `keyword`, `constant`, `normal`, `operator`, `string` und `variable`, jedes
  mit `Fore` (der Text) und `Back` (der Hintergrund), als `#RRGGBB`.
- **Eine Farbe, die das Farbschema nicht angibt, bleibt «automatisch»**, wie in einem frisch
  installierten VFP. Darum gibt `vfp-classic.json` nur das Grün der Kommentare und das Blau der
  Schlüsselwörter an und lässt die Werkswerte.
- `editorFont` und `editorFontSize` (10, wenn es fehlt): die Schrift des Programm-Editors.
- `screenFont`, `screenFontSize`, `screenBack` und `screenFore`: die von `_SCREEN`. Was fehlt, wird nicht
  angerührt.

Eine `.json`, die kein Farbschema ist (sie ist kein Objekt, eine Farbe ist nicht `#RRGGBB`, oder sie hat
weder Farben noch Schriften), erscheint nicht in der Liste, und das Protokoll sagt einmal, warum.

Für den Agenten gibt es zwei Tools, `ide_list_themes` und `ide_set_theme`:
AGENT-TOOLS_DE.md § 7.

## Über dieses Handbuch

Dieser Text ist der Abschnitt über `themes` aus dem Plugin-Handbuch von FoxDock. Die Verweise auf andere Abschnitte (§) und auf AGENT-TOOLS zeigen auf die Dokumente, die FoxDock in seinem Ordner `docs` installiert.

## Lizenz

MIT. Siehe [LICENSE](LICENSE).
