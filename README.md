# foxdock-themes

The `themes` plugin of FoxDock, the plugin system for the Visual FoxPro 9 IDE. Color themes for the IDE: syntax colors, the editor font, and the font and colors of the main window.

> Also in Spanish ([README_ES.md](README_ES.md)) and German ([README_DE.md](README_DE.md)).

## Install

You need FoxDock and [FoxPack](https://irwinrodriguez.dev/products/foxpack).

- In FoxDock: **FoxDock > Plugins > Plugin center...**, **Available**, choose `themes` and press **Install**.
- From a console: `foxpack plugin add themes`.

If `themes` came with your FoxDock installer, the plugin center shows its new versions in **Updates**.

## The `themes` plugin

It changes in one go the syntax colors, the font of the program editor, and the font and colors of the
main window (`_SCREEN`), from **FoxDock > Themes**.

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
Restore VFP colors
Open themes folder
```

**What a theme covers, and when you see it.**

| Part | Where it is written | When you see it |
|---|---|---|
| The syntax colors: comment, keyword, constant, normal, operator, string and variable, each with its text and its background | the registry (the key of the VFP it runs in: `HKCU\Software\Microsoft\VisualFoxPro\9.0\Options` in VFP 9, `...\VisualFoxPro\10.2\Options` or `...\VisualFoxPro64\10.2\Options` in VFP Advanced; the seven `Editor*Color` values) and `SYS(3056, 1)` | **at once**, in the open editors and in the new ones |
| The font of the program editor | `Options\IDE\ProgramFont`, after rereading (rereading would overwrite it) | in the program editors you open **afterwards**; the one already open keeps its font |
| The font and colors of `_SCREEN` | by code | at once. VFP saves the font when it quits, but not the colors: the plugin sets them on each start |

**What it does not cover.** Each theme says so in its `notCovered`, and `ide_set_theme` returns it:
- **The editor font, if your resource file (`FOXUSER.DBF`) has its own default font** (Edit › Properties
  › «Use as default»): the one in the resource wins. It does not reach a file that already has its window
  saved in the resource either. **FoxDock does not write your resource file.** When you apply the theme,
  the log warns about it, and `ide_set_theme` answers `editorFont: overriddenByResource`.
- The debugger windows, the Command window, the method editors of the designers and the text and memo
  editors: not tested with a theme.
- VFP Advanced: each version has its own key, its own backup (`backup-10.2.json`, `backup-10.2-x64.json`) and its own current theme; a theme you set in VFP Advanced does not change VFP 9.

**The backup and «Restore VFP colors».** Before the first theme, the plugin keeps in
`<themes folder>\backup\backup.json` what each value it can write held (or that it did not exist), and
the font and colors of `_SCREEN`. «Restore VFP colors» goes back to that, **in the open editors too**, and
leaves the backup where it is. If you change colors by hand in Options after the first theme, «Restore»
goes back to what there was before the first theme, not to your changes.

**Uninstalling with a theme on.** VFP paints the editors and the Command window with the colors it reads
from the registry when it opens, so they would stay after uninstalling FoxDock. While a theme is on, the
plugin keeps next to the backup a `restore.reg` (`restore-10.2.reg` in VFP Advanced) with the values from
before, and the uninstaller imports it: the colors go back as «Restore VFP colors» would leave them.
«Restore VFP colors» erases it, since then there is nothing to undo.

The plugin writes **only its own values**. It never calls `SYS(3056, 2)`, which would write all your
options at once (it is the same as «Set As Default»).

**The options** (`"options": { "themes": { ... } }`):
- `current`: the current theme (its id, the name of the file). It is applied when the IDE starts, and
  only what is not there yet is written.
- `folder`: another themes folder instead of `plugins\themes\themes\`.

**A theme** is a flat `.json`, in UTF-8, in that folder. Its id is the name of the file:

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

- The elements are `comment`, `keyword`, `constant`, `normal`, `operator`, `string` and `variable`, each
  with `Fore` (the text) and `Back` (the background), as `#RRGGBB`.
- **A color the theme does not give stays «automatic»**, as in a freshly installed VFP. That is why
  `vfp-classic.json` gives only the green of comments and the blue of keywords, and leaves the factory
  values.
- `editorFont` and `editorFontSize` (10 if missing): the font of the program editor.
- `screenFont`, `screenFontSize`, `screenBack` and `screenFore`: those of `_SCREEN`. What is missing is
  not touched.

A `.json` that is not a theme (it is not an object, a color is not `#RRGGBB`, or it has no colors and no
fonts) does not appear in the list, and the log says why, once.

For the agent there are two tools, `ide_list_themes` and `ide_set_theme`:
AGENT-TOOLS_EN.md § 7.

## About this manual

This text is the section about `themes` of the FoxDock plugin manual. The references to other sections (§) and to AGENT-TOOLS point to the documents FoxDock installs in its `docs` folder.

## License

MIT. See [LICENSE](LICENSE).
