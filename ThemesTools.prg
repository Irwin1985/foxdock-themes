*==================================================================
* ThemesTools.prg: las tools del plugin «themes» para el agente.
*
* Heredan de IdeTool (plugins\foxagent\IdeTools.prg): el host, J(), Done(),
* los parámetros y el rol que pide cada una.
*
*   ide_list_themes   los temas que hay y el que está puesto (lee)
*   ide_set_theme     pone un tema (actúa: rol 10)
*
* Lo que un tema no cubre lo dice cada tema (notCovered) y la respuesta de
* ide_set_theme (editorFont), para no prometer más de lo que VFP aplica.
*==================================================================

#DEFINE TH_NO_HOST "FoxDock is not mounted (after CLEAR ALL it sleeps until a FoxDock menu bar or key is pressed)"
#DEFINE TH_NOT_LOADED "The themes plugin is not loaded in this IDE (FoxDock > Plugins)."

DEFINE CLASS IdeThemesTool AS IdeTool
	PROCEDURE Plugin
		IF ISNULL(THIS.Host())
			RETURN .NULL.
		ENDIF
		RETURN _screen.oFoxDock.PluginById("themes")
	ENDPROC

	*-- Un tema como lo ve el agente.
	PROCEDURE ThemeJson
		LPARAMETERS toPlugin, toT, tcCurrent
		LOCAL loJ, loV
		loJ = THIS.J()
		loV = loJ.MakeObject()
		loJ.Put(loV, "id", toT.Item("#id"))
		loJ.Put(loV, "name", loJ.Get(toT, "name", ""))
		loJ.Put(loV, "current", toT.Item("#id") == tcCurrent)
		loJ.Put(loV, "editorFont", IIF(EMPTY(loJ.Get(toT, "editorfont", "")), .NULL., ;
			ALLTRIM(loJ.Get(toT, "editorfont", "")) + " " + TRANSFORM(INT(loJ.Get(toT, "editorfontsize", 10)))))
		loJ.Put(loV, "notCovered", loJ.Get(toT, "notcovered", ""))
		loJ.Put(loV, "file", toT.Item("#file"))
		RETURN loV
	ENDPROC
ENDDEFINE


DEFINE CLASS IdeListThemesTool AS IdeThemesTool
	ToolName = "ide_list_themes"
	ToolDescription = "The color themes FoxDock can put on this Visual FoxPro IDE (FoxDock > Themes): each with its id (for " + ;
		"ide_set_theme), its name, whether it is the current one, its editor font, and what it does not cover (notCovered). " + ;
		"Also the themes folder and whether there is a backup to restore. A theme file that is not valid is not listed (the " + ;
		"FoxDock log says why). Reads only."

	FUNCTION Run(toContext)
		LOCAL loP, loJ, loD, loList, loOut, lnI, lcCur
		IF ISNULL(THIS.Host())
			RETURN THIS.Err(TH_NO_HOST)
		ENDIF
		loP = THIS.Plugin()
		IF ISNULL(loP)
			RETURN THIS.Err(TH_NOT_LOADED)
		ENDIF
		loJ = THIS.J()
		*-- El de ESTE VFP (en VFP Advanced no es themes.current).
		lcCur = loP.CurrentTheme()
		loList = loP.ThemeList()
		loOut = loJ.MakeArray()
		FOR lnI = 1 TO loList.Count
			loOut.Add(THIS.ThemeJson(loP, loList.Item(lnI), lcCur))
		ENDFOR
		loD = loJ.MakeObject()
		loJ.Put(loD, "folder", loP.cFolder)
		loJ.Put(loD, "current", IIF(EMPTY(lcCur), .NULL., lcCur))
		loJ.Put(loD, "hasBackup", FILE(loP.BackupFile()))
		loJ.Put(loD, "count", loOut.Count)
		loJ.Put(loD, "themes", loOut)
		RETURN THIS.Done(loD)
	ENDFUNC
ENDDEFINE


DEFINE CLASS IdeSetThemeTool AS IdeThemesTool
	ToolName = "ide_set_theme"
	lActsOnIde = .T.
	ToolDescription = "Puts one of the themes of ide_list_themes on this Visual FoxPro IDE, as FoxDock > Themes does: the syntax " + ;
		"colors change at once in the open editors and the new ones; the editor font reaches only the editors opened after, " + ;
		"and not at all when the FoxPro resource (FOXUSER) has its own default font (editorFont says which: applied, " + ;
		"overriddenByResource, notInTheme or unknown); the main window (_SCREEN) font and colors at once. Before the first theme " + ;
		"it keeps a backup of the VFP colors (FoxDock > Themes > Restore VFP colors goes back to it). It writes only its own " + ;
		"registry values (never the whole Options), and never the resource. Returns how many values it wrote."

	FUNCTION DefineParameters()
		THIS.AddParam("name", "string", "The theme: its id or its name, as ide_list_themes gives them (dark, vfp-classic...).", .T.)
	ENDFUNC

	FUNCTION Run(toContext)
		LOCAL loP, loJ, loD, lcName, loT
		IF ISNULL(THIS.Host())
			RETURN THIS.Err(TH_NO_HOST)
		ENDIF
		loP = THIS.Plugin()
		IF ISNULL(loP)
			RETURN THIS.Err(TH_NOT_LOADED)
		ENDIF
		lcName = THIS.PText(toContext, "name")
		IF EMPTY(lcName)
			RETURN THIS.Err("'name' is required: one of the ids of ide_list_themes.")
		ENDIF
		loT = loP.Find(lcName)
		IF ISNULL(loT)
			RETURN THIS.Err("There is no theme '" + lcName + "' in " + loP.cFolder + ". ide_list_themes lists the ones there are.")
		ENDIF
		IF !loP.Apply(loT.Item("#id"))
			RETURN THIS.Err("The theme could not be applied: " + loP.cLastError)
		ENDIF
		loJ = THIS.J()
		loD = loJ.MakeObject()
		loJ.Put(loD, "theme", loT.Item("#id"))
		loJ.Put(loD, "name", loJ.Get(loT, "name", ""))
		loJ.Put(loD, "registryValuesWritten", loP.nWritten)
		loJ.Put(loD, "reread", loP.lReread)
		loJ.Put(loD, "screenChanged", loP.lScreenSet)
		loJ.Put(loD, "editorFont", loP.cEditorFont)
		loJ.Put(loD, "notCovered", loJ.Get(loT, "notcovered", ""))
		_screen.oFoxDock.AgentDid("put the theme " + loJ.Get(loT, "name", "") + " on the IDE")
		RETURN THIS.Done(loD)
	ENDFUNC
ENDDEFINE
