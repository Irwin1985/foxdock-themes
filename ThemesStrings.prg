*==================================================================
* ThemesStrings.prg: las cadenas del plugin themes, en inglés,
* español y alemán. Lo ejecuta el host al cargar el plugin (LoadPluginStrings),
* antes de su BuildMenu: una llamada toHost.AddString(<idioma>, <clave>, <texto>)
* por cadena. Las tres listas llevan las mismas claves, en el mismo orden; una que
* falte en español o alemán sale en inglés. {1} a {4}, los valores. \< marca la
* tecla de acceso. Los nombres propios (FoxDock, FoxAgent, VFP, GUID, JSON) no se
* traducen. Fichero en CP1252, con los acentos escritos: lo lee el usuario.
*==================================================================

LPARAMETERS toHost

*-- English
toHost.AddString("en", "themes.title", "Themes")
toHost.AddString("en", "themes.apply.message", "Apply the theme {1}")
toHost.AddString("en", "themes.none", "(no themes in {1})")
toHost.AddString("en", "themes.restore", "\<Restore VFP colors")
toHost.AddString("en", "themes.restore.message", "Back to the colors and fonts there were before the first theme")
toHost.AddString("en", "themes.folder", "\<Open themes folder")
toHost.AddString("en", "themes.applied", "Theme {1} applied")
toHost.AddString("en", "themes.appliedNoFont", "Theme {1} applied (not the editor font: see the FoxDock log)")
toHost.AddString("en", "themes.notApplied", "The theme could not be applied: {1}")
toHost.AddString("en", "themes.restored", "VFP colors restored")
toHost.AddString("en", "themes.notRestored", "Nothing restored: {1}")
toHost.AddString("en", "themes.noFolder", "The themes folder {1} does not exist")
toHost.AddString("en", "themes.folderFailed", "The themes folder could not be opened: {1}")

*-- Español
toHost.AddString("es", "themes.title", "Temas")
toHost.AddString("es", "themes.apply.message", "Aplica el tema {1}")
toHost.AddString("es", "themes.none", "(no hay temas en {1})")
toHost.AddString("es", "themes.restore", "\<Restaurar los colores de VFP")
toHost.AddString("es", "themes.restore.message", "Vuelve a los colores y las fuentes que había antes del primer tema")
toHost.AddString("es", "themes.folder", "\<Abrir la carpeta de temas")
toHost.AddString("es", "themes.applied", "Tema {1} aplicado")
toHost.AddString("es", "themes.appliedNoFont", "Tema {1} aplicado (la fuente del editor no: mira el log de FoxDock)")
toHost.AddString("es", "themes.notApplied", "No se pudo aplicar el tema: {1}")
toHost.AddString("es", "themes.restored", "Colores de VFP restaurados")
toHost.AddString("es", "themes.notRestored", "No se restauró nada: {1}")
toHost.AddString("es", "themes.noFolder", "La carpeta de temas {1} no existe")
toHost.AddString("es", "themes.folderFailed", "No se pudo abrir la carpeta de temas: {1}")

*-- Deutsch
toHost.AddString("de", "themes.title", "Designs")
toHost.AddString("de", "themes.apply.message", "Wendet das Design {1} an")
toHost.AddString("de", "themes.none", "(keine Designs in {1})")
toHost.AddString("de", "themes.restore", "VFP-Farben \<wiederherstellen")
toHost.AddString("de", "themes.restore.message", "Zurück zu den Farben und Schriften vor dem ersten Design")
toHost.AddString("de", "themes.folder", "Design-\<Ordner öffnen")
toHost.AddString("de", "themes.applied", "Design {1} angewendet")
toHost.AddString("de", "themes.appliedNoFont", "Design {1} angewendet (nicht die Editor-Schrift: siehe das FoxDock-Log)")
toHost.AddString("de", "themes.notApplied", "Das Design konnte nicht angewendet werden: {1}")
toHost.AddString("de", "themes.restored", "VFP-Farben wiederhergestellt")
toHost.AddString("de", "themes.notRestored", "Nichts wiederhergestellt: {1}")
toHost.AddString("de", "themes.noFolder", "Der Design-Ordner {1} existiert nicht")
toHost.AddString("de", "themes.folderFailed", "Der Design-Ordner konnte nicht geöffnet werden: {1}")
