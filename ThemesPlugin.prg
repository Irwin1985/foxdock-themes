*==================================================================
* ThemesPlugin.prg: el plugin «themes» de FoxDock.
*
* Un tema son los colores de sintaxis del editor, la fuente del editor de
* programas y la fuente y los colores de _SCREEN. Cada uno es un .json plano
* (UTF-8) en la carpeta themes\ del plugin, o en la de la opción
* themes.folder. Lo que VFP guarda y cuándo lo lee:
*
*   - Los colores de sintaxis viven en el registro (HKCU\...\9.0\Options,
*     siete Editor*Color). Escribirlos no basta: SYS(3056, 1) los relee, y
*     entonces cambian al momento los editores abiertos y los nuevos. Nunca
*     SYS(3056, 2): escribe TODO Options, como Set As Default.
*   - La fuente del editor de programas es Options\IDE\ProgramFont, que lee
*     cada editor nuevo al abrirse. NO llega si el recurso (FOXUSER) tiene su
*     propio WINDMODIFY/DEFAULT, ni a un fichero que ya tiene su registro en
*     el recurso: este plugin no escribe el recurso del usuario, y lo dice
*     (cEditorFont, el log y ide_set_theme).
*   - Los colores de _SCREEN no se guardan en ningún sitio: se ponen al
*     aplicar y en cada montaje. Su fuente la guarda VFP al salir.
*   - SYS(3056, 1) ESCRIBE Options\IDE\Program, ProgramExtension y
*     ProgramFont con lo que VFP tiene en memoria, estén o no, y pisa
*     un ProgramFont recién escrito. Por eso lo de Options\IDE se
*     escribe (o se borra, en Restore) DESPUÉS de releer.
*
* Antes del primer tema se guarda lo que había (las claves que el plugin
* escribe, las dos que crea SYS(3056, 1) y _SCREEN) en
* <carpeta>\backup\backup.json; «Restore VFP colors» vuelve a eso y no lo
* borra. themes.current se aplica al montar, y solo se escribe lo que no
* está ya.
*
* Cada VFP, lo suyo: la clave es la de la versión que
* corre (VisualFoxPro\9.0, VisualFoxPro\10.2 o VisualFoxPro64\10.2), y VFP
* Advanced tiene su propia copia (backup-10.2.json, backup-10.2-x64.json) y
* su propio «current» (current_vfpa, current_vfpa64). VFP 9 conserva los
* nombres de siempre.
*
* La clave del «current» de VFPA no lleva puntos ni guiones: Options toma el
* punto por una ruta y jsonfox cambia el guion por «_». Versiones anteriores
* usaban "current-10.2", que se escribía "current-10": { "2": "dark" } y se
* leía "current_10._", así que el tema no volvía. Si la clave nueva está vacía,
* se lee la vieja (OldCurrentKeys), y la vieja se borra la primera vez que se
* guarda el tema, con su línea en el log.
*
* Lo que queda oscuro al desinstalar FoxDock con un tema puesto es el
* registro: VFP pinta la ventana de
* comandos y los editores con los Options\Editor*Color que lee al arrancar, y
* no los vuelve a escribir (ni al salir ni con SYS(3056, 1)); el recurso no
* guarda colores. Mientras haya un tema puesto, junto a la copia de seguridad
* hay un restore<sufijo>.reg con lo inverso (los valores de antes, y
* "Nombre"=- para los que no existían), que el desinstalador importa con
* reg.exe. «Restore VFP colors» lo borra: sin tema, no hay nada que deshacer.
*
* La suite pone FOXDOCK_THEMES_REGISTRY_ROOT para escribir en una clave suya
* y no en la de VFP; entonces NO se llama a SYS(3056, 1), que releería (y
* escribiría) el registro del VFP del usuario.
*
* nOrder 990: detrás de foxforge, para no mover los menús de antes.
*
* Superficie pública en inglés. Fichero en CP1252, con los acentos
* escritos.
*==================================================================

#DEFINE CRLF CHR(13) + CHR(10)
#DEFINE TH_ELEMENTS "Comment,Keyword,Constant,Normal,Operator,String,Variable"
#DEFINE TH_MARK "• "

DEFINE CLASS ThemesPlugin AS PluginBase
	cId = "themes"
	cTitle = "Themes"
	nOrder = 960
	cVersion = "0.1.0"
	lWantsIdle = .T.

	cFolder = ""          && la carpeta de los temas, con su \
	cRegRoot = ""         && la clave de VFP (o la de la suite), con su \
	cSuffix = ""          && "" en VFP 9; "-10.2" o "-10.2-x64" en VFP Advanced
	cCurrentKey = ""      && "current" en VFP 9; "current_vfpa" o "current_vfpa64" en VFP Advanced
	lRedirected = .F.     && cRegRoot es la de FOXDOCK_THEMES_REGISTRY_ROOT
	cBroken = ""          && los .json rotos ya anotados, para no repetirlos
	nWritten = 0          && valores del registro escritos en la última aplicación
	lReread = .F.         && si la última aplicación llamó a SYS(3056, 1)
	lScreenSet = .F.      && si la última aplicación tocó _SCREEN
	cEditorFont = ""      && applied, alreadyApplied, overriddenByResource, notInTheme, unknown
	cLastError = ""

	PROCEDURE OnHostReady
		LOCAL lcCur
		This.Ready()
		lcCur = This.CurrentTheme()
		IF !EMPTY(lcCur)
			IF !This.Apply(lcCur)
				This.oHost.LogWarn("themes: the current theme '" + lcCur + "' could not be applied on mount: " + This.cLastError)
			ENDIF
		ENDIF
		RETURN .T.
	ENDPROC

	PROCEDURE FindFolder
		LOCAL lcDir
		lcDir = TRANSFORM(This.oHost.Options.Get(This.cId, "folder", ""))
		This.cFolder = IIF(EMPTY(lcDir), This.cHome + "themes\", ADDBS(lcDir))
	ENDPROC

	*-- La clave de las opciones de ESTE VFP (desde VFP Advanced, la de VFP 9
	*-- cambiaría el tema de VFP 9). VFP 9 en VisualFoxPro\9.0,
	*-- VFPA en VisualFoxPro\10.2 y el de 64 bits en VisualFoxPro64\10.2
	*-- (VERSION(5) da 900 y 1002, y _WIN64 es .T. en el de 64).
	PROCEDURE RegRootFor
		LPARAMETERS tnVersion5, tlWin64
		RETURN "HKCU\Software\Microsoft\VisualFoxPro" + IIF(tlWin64, "64", "") + "\" + ;
			TRANSFORM(INT(tnVersion5 / 100)) + "." + TRANSFORM(MOD(tnVersion5, 100)) + "\"
	ENDPROC

	*-- Lo que distingue la copia de seguridad y el «current» de cada VFP: ""
	*-- en VFP 9 (los nombres de siempre), y "-10.2" o "-10.2-x64" en VFPA.
	PROCEDURE VfpSuffix
		LPARAMETERS tnVersion5, tlWin64
		IF tnVersion5 < 1000 AND !tlWin64
			RETURN ""
		ENDIF
		RETURN "-" + TRANSFORM(INT(tnVersion5 / 100)) + "." + TRANSFORM(MOD(tnVersion5, 100)) + IIF(tlWin64, "-x64", "")
	ENDPROC

	*-- _WIN64 solo existe en VFP Advanced.
	PROCEDURE ThisWin64
		IF TYPE("_WIN64") == "L"
			RETURN EVALUATE("_WIN64")
		ENDIF
		RETURN .F.
	ENDPROC

	*-- La opción del tema actual de cada VFP: sin puntos ni guiones, que
	*-- en Options un punto es una ruta.
	PROCEDURE CurrentKeyFor
		LPARAMETERS tnVersion5, tlWin64
		IF tnVersion5 < 1000 AND !tlWin64
			RETURN "current"
		ENDIF
		RETURN "current_vfpa" + IIF(tlWin64, "64", "")
	ENDPROC

	PROCEDURE CurrentKey
		IF EMPTY(This.cRegRoot)
			This.FindRegRoot()
		ENDIF
		RETURN This.cCurrentKey
	ENDPROC

	*-- Las opciones que dejaron versiones anteriores para el tema actual de
	*-- este VFP, como las lee Options ("current-10.2" vuelve como
	*-- "current_10._" y "current-10.2-x64" como "current_10.__x64"). En VFP 9,
	*-- ninguna: su «current» no cambió.
	PROCEDURE OldCurrentKeys
		LOCAL loAll, loOld, lcK, llX64
		loOld = CREATEOBJECT("Collection")
		IF This.CurrentKey() == "current"
			RETURN loOld
		ENDIF
		llX64 = This.CurrentKey() == "current_vfpa64"
		loAll = This.oHost.Options.KeysOf(This.cId, "current")
		FOR EACH lcK IN loAll
			IF INLIST(LEFT(lcK, 8), "current-", "current_") AND !INLIST(lcK, "current_vfpa", "current_vfpa64") AND ;
					IIF("x64" $ lcK, llX64, !llX64)
				loOld.Add(lcK)
			ENDIF
		ENDFOR
		RETURN loOld
	ENDPROC

	*-- El tema actual de este VFP: su opción y, si está vacía, la primera
	*-- vieja que tenga uno.
	PROCEDURE CurrentTheme
		LOCAL lcCur, loOld, lcK
		lcCur = TRANSFORM(This.oHost.Options.Get(This.cId, This.CurrentKey(), ""))
		IF EMPTY(lcCur)
			loOld = This.OldCurrentKeys()
			FOR EACH lcK IN loOld
				lcCur = TRANSFORM(This.oHost.Options.Get(This.cId, lcK, ""))
				IF !EMPTY(lcCur)
					EXIT
				ENDIF
			ENDFOR
		ENDIF
		RETURN lcCur
	ENDPROC

	*-- Guarda el tema actual de este VFP ("" = ninguno) y borra las opciones
	*-- viejas, diciéndolo en el log.
	PROCEDURE SaveCurrent
		LPARAMETERS tcTheme
		LOCAL loOld, lcK, lcGone
		loOld = This.OldCurrentKeys()
		lcGone = ""
		FOR EACH lcK IN loOld
			This.oHost.Options.Remove(This.cId, lcK)
			lcGone = lcGone + IIF(EMPTY(lcGone), "", ", ") + lcK
		ENDFOR
		IF !EMPTY(lcGone)
			This.oHost.Log("themes: the current theme of this VFP is kept in themes." + This.CurrentKey() + ;
				" now; the options FoxDock 0.9.15 and before left for it (" + lcGone + ") are gone from config.json")
		ENDIF
		RETURN This.oHost.Options.Set(This.cId, This.CurrentKey(), tcTheme)
	ENDPROC

	*-- tnVersion5 y tlWin64: los de este VFP si no vienen (la suite pasa los de
	*-- VFP Advanced para ver su «current»).
	PROCEDURE FindRegRoot
		LPARAMETERS tnVersion5, tlWin64
		IF PCOUNT() < 2
			tnVersion5 = VERSION(5)
			tlWin64 = This.ThisWin64()
		ENDIF
		This.cRegRoot = This.RegRootFor(tnVersion5, tlWin64)
		This.cSuffix = This.VfpSuffix(tnVersion5, tlWin64)
		This.cCurrentKey = This.CurrentKeyFor(tnVersion5, tlWin64)
		This.lRedirected = !EMPTY(GETENV("FOXDOCK_THEMES_REGISTRY_ROOT"))
		IF This.lRedirected
			This.cRegRoot = ADDBS(GETENV("FOXDOCK_THEMES_REGISTRY_ROOT"))
			This.oHost.Log("themes: registry root redirected by FOXDOCK_THEMES_REGISTRY_ROOT to " + This.cRegRoot + ;
				" (and SYS(3056, 1) is not called)")
		ENDIF
	ENDPROC

	*-- El host construye el menú ANTES de OnHostReady: la carpeta y la clave
	*-- se buscan la primera vez que hacen falta.
	PROCEDURE Ready
		IF EMPTY(This.cFolder)
			This.FindFolder()
		ENDIF
		IF EMPTY(This.cRegRoot)
			This.FindRegRoot()
		ENDIF
	ENDPROC

	*-- Relee los colores si se escribió algo y la clave es la de VFP.
	PROCEDURE Reread
		This.lReread = This.nWritten > 0 AND !This.lRedirected
		IF This.lReread
			=SYS(3056, 1)
		ENDIF
	ENDPROC

	*==============================================================
	* Los temas
	*==============================================================

	*-- Los temas de la carpeta, cada uno una Collection (FoxDockJson.Parse,
	*-- claves en minúsculas) con «#id» (el nombre del fichero sin .json) y
	*-- «#file». vfp-classic primero; los demás, por nombre de fichero. Un
	*-- .json que no es un tema se anota una vez y se salta.
	PROCEDURE ThemeList
		LOCAL loList, lnN, lnI, loT, lcWhy, lcFile, lcBroken, lnAt
		LOCAL ARRAY laF[1]
		This.Ready()
		loList = CREATEOBJECT("Collection")
		lcBroken = ""
		lnN = IIF(DIRECTORY(This.cFolder, 1), ADIR(laF, This.cFolder + "*.json"), 0)
		IF lnN > 1
			=ASORT(laF, 1)
		ENDIF
		FOR lnI = 1 TO lnN
			lcFile = This.cFolder + laF[lnI, 1]
			lcWhy = ""
			loT = This.LoadTheme(lcFile, @lcWhy)
			IF ISNULL(loT)
				lcBroken = lcBroken + "|" + LOWER(laF[lnI, 1])
				IF !("|" + LOWER(laF[lnI, 1]) + "|" $ This.cBroken + "|")
					This.oHost.LogWarn("themes: " + lcFile + " is not a valid theme, so it is not listed: " + lcWhy)
				ENDIF
				LOOP
			ENDIF
			IF loT.Item("#id") == "vfp-classic" AND loList.Count > 0
				loList.Add(loT, loT.Item("#id"), 1)
			ELSE
				loList.Add(loT, loT.Item("#id"))
			ENDIF
		ENDFOR
		This.cBroken = lcBroken
		RETURN loList
	ENDPROC

	*-- Un tema, o .NULL. con el motivo en tcWhy.
	PROCEDURE LoadTheme
		LPARAMETERS tcFile, tcWhy
		LOCAL lcText, loT, loJ, loKeys, lnI, lcKey, lcV, llAny, loErr
		tcWhy = ""
		TRY
			lcText = FILETOSTR(tcFile)
		CATCH TO loErr
			lcText = .NULL.
			tcWhy = "it cannot be read: " + loErr.Message
		ENDTRY
		IF ISNULL(lcText)
			RETURN .NULL.
		ENDIF
		IF LEFT(lcText, 3) == CHR(0xEF) + CHR(0xBB) + CHR(0xBF)
			lcText = SUBSTR(lcText, 4)
		ENDIF
		*-- ALLTRIM quita espacios, no tabuladores ni saltos: se le dicen (vfpdocs).
		lcText = ALLTRIM(STRCONV(lcText, 11), 0, " ", CHR(9), CHR(13), CHR(10))
		IF !(LEFT(lcText, 1) == "{" AND RIGHT(lcText, 1) == "}")
			tcWhy = "it is not a JSON object"
			RETURN .NULL.
		ENDIF
		loJ = This.oHost.oJson
		loT = loJ.Parse(lcText)
		*-- Las claves que se leen: un color que no es #RRGGBB lo rompe.
		llAny = .F.
		loKeys = This.ColorKeys()
		FOR lnI = 1 TO loKeys.Count
			lcKey = loKeys.Item(lnI)
			lcV = loJ.Get(loT, lcKey, .NULL.)
			IF ISNULL(lcV)
				LOOP
			ENDIF
			IF !This.IsHexColor(lcV)
				tcWhy = lcKey + " is " + TRANSFORM(lcV) + ", not a color like #1E1E1E"
				RETURN .NULL.
			ENDIF
			llAny = .T.
		ENDFOR
		IF !EMPTY(loJ.Get(loT, "editorfont", ""))
			llAny = .T.
			IF VARTYPE(loJ.Get(loT, "editorfontsize", 10)) # "N" OR loJ.Get(loT, "editorfontsize", 10) <= 0
				tcWhy = "editorFontSize is not a positive number"
				RETURN .NULL.
			ENDIF
		ENDIF
		IF !EMPTY(loJ.Get(loT, "screenfont", ""))
			llAny = .T.
		ENDIF
		IF !llAny
			tcWhy = "it has no colors and no fonts (the keys are in docs\PLUGINS_EN.md, section 11)"
			RETURN .NULL.
		ENDIF
		loT.Add(LOWER(JUSTSTEM(tcFile)), "#id")
		loT.Add(tcFile, "#file")
		IF EMPTY(loJ.Get(loT, "name", ""))
			loJ.Put(loT, "name", JUSTSTEM(tcFile))
		ENDIF
		RETURN loT
	ENDPROC

	*-- Las claves de color que lee un tema, en minúsculas.
	PROCEDURE ColorKeys
		LOCAL loK, lnI, lcEl
		loK = CREATEOBJECT("Collection")
		FOR lnI = 1 TO GETWORDCOUNT(TH_ELEMENTS, ",")
			lcEl = LOWER(GETWORDNUM(TH_ELEMENTS, lnI, ","))
			loK.Add(lcEl + "fore")
			loK.Add(lcEl + "back")
		ENDFOR
		loK.Add("screenfore")
		loK.Add("screenback")
		RETURN loK
	ENDPROC

	PROCEDURE IsHexColor
		LPARAMETERS tvV
		RETURN VARTYPE(tvV) == "C" AND LEN(tvV) = 7 AND LEFT(tvV, 1) == "#" AND ;
			EMPTY(CHRTRAN(UPPER(SUBSTR(tvV, 2)), "0123456789ABCDEF", ""))
	ENDPROC

	*-- "#RRGGBB" -> "r,g,b".
	PROCEDURE HexToTriple
		LPARAMETERS tcHex
		RETURN TRANSFORM(EVALUATE("0x" + SUBSTR(tcHex, 2, 2))) + "," + ;
			TRANSFORM(EVALUATE("0x" + SUBSTR(tcHex, 4, 2))) + "," + ;
			TRANSFORM(EVALUATE("0x" + SUBSTR(tcHex, 6, 2)))
	ENDPROC

	PROCEDURE HexToRgb
		LPARAMETERS tcHex
		RETURN RGB(EVALUATE("0x" + SUBSTR(tcHex, 2, 2)), EVALUATE("0x" + SUBSTR(tcHex, 4, 2)), EVALUATE("0x" + SUBSTR(tcHex, 6, 2)))
	ENDPROC

	*-- Un tema por su id (el fichero) o su nombre, sin distinguir mayúsculas.
	PROCEDURE Find
		LPARAMETERS tcName
		LOCAL loList, lnI, loT, lcWant
		lcWant = LOWER(ALLTRIM(TRANSFORM(tcName)))
		loList = This.ThemeList()
		FOR lnI = 1 TO loList.Count
			loT = loList.Item(lnI)
			IF loT.Item("#id") == lcWant OR LOWER(This.oHost.oJson.Get(loT, "name", "")) == lcWant
				RETURN loT
			ENDIF
		ENDFOR
		RETURN .NULL.
	ENDPROC

	*-- El valor de Editor<el>Color de un tema, con la forma que escribe VFP:
	*-- "RGB(fr,fg,fb,br,bg,bb), NoAuto|Auto, NoAuto|Auto". Un color que el
	*-- tema no da es «Auto», con los números de fábrica (negro sobre blanco):
	*-- así vfp-classic deja los siete valores de fábrica.
	PROCEDURE ColorValue
		LPARAMETERS toT, tcEl
		LOCAL loJ, lcFore, lcBack
		loJ = This.oHost.oJson
		lcFore = loJ.Get(toT, LOWER(tcEl) + "fore", "")
		lcBack = loJ.Get(toT, LOWER(tcEl) + "back", "")
		RETURN "RGB(" + IIF(EMPTY(lcFore), "0,0,0", This.HexToTriple(lcFore)) + "," + ;
			IIF(EMPTY(lcBack), "255,255,255", This.HexToTriple(lcBack)) + "), " + ;
			IIF(EMPTY(lcFore), "Auto", "NoAuto") + ", " + IIF(EMPTY(lcBack), "Auto", "NoAuto")
	ENDPROC

	*-- Lo que un tema escribe en el registro: Collection valor -> clave
	*-- relativa a cRegRoot. Nada más que esto.
	PROCEDURE RegistryValuesOf
		LPARAMETERS toT
		LOCAL loV, lnI, lcEl, loJ
		loJ = This.oHost.oJson
		loV = CREATEOBJECT("Collection")
		FOR lnI = 1 TO GETWORDCOUNT(TH_ELEMENTS, ",")
			lcEl = GETWORDNUM(TH_ELEMENTS, lnI, ",")
			loV.Add(This.ColorValue(toT, lcEl), "Options\Editor" + lcEl + "Color")
		ENDFOR
		IF !EMPTY(loJ.Get(toT, "editorfont", ""))
			loV.Add(ALLTRIM(loJ.Get(toT, "editorfont", "")) + ", " + TRANSFORM(INT(loJ.Get(toT, "editorfontsize", 10))) + ", N, 1", ;
				"Options\IDE\ProgramFont")
		ENDIF
		RETURN loV
	ENDPROC

	*-- Las claves de la copia de seguridad: las que el plugin puede escribir y
	*-- las dos que SYS(3056, 1) crea si no están.
	PROCEDURE BackupKeys
		LOCAL loK, lnI
		loK = CREATEOBJECT("Collection")
		FOR lnI = 1 TO GETWORDCOUNT(TH_ELEMENTS, ",")
			loK.Add("Options\Editor" + GETWORDNUM(TH_ELEMENTS, lnI, ",") + "Color")
		ENDFOR
		loK.Add("Options\IDE\ProgramFont")
		loK.Add("Options\IDE\Program")
		loK.Add("Options\IDE\ProgramExtension")
		RETURN loK
	ENDPROC

	*==============================================================
	* Aplicar y restaurar
	*==============================================================

	*-- Aplica un tema: escribe lo que no está ya, relee si escribió algo, pone
	*-- _SCREEN y guarda themes.current. Devuelve .T. o .F. (cLastError).
	PROCEDURE Apply
		LPARAMETERS tcName
		LOCAL loT, loJ, loV, lnI, lcKey, lcWant, lcCur, loOld
		This.cLastError = ""
		This.nWritten = 0
		This.lReread = .F.
		This.lScreenSet = .F.
		loT = This.Find(tcName)
		IF ISNULL(loT)
			This.cLastError = "there is no theme '" + TRANSFORM(tcName) + "' in " + This.cFolder
			RETURN .F.
		ENDIF
		IF !This.EnsureBackup()
			RETURN .F.
		ENDIF
		loJ = This.oHost.oJson
		loV = This.RegistryValuesOf(loT)
		*-- Primero los colores y la relectura; lo de Options\IDE, después: la
		*-- relectura lo pisa con lo que VFP tiene en memoria.
		IF !This.WriteValues(loV, .F.)
			RETURN .F.
		ENDIF
		This.Reread()
		IF !This.WriteValues(loV, .T.)
			RETURN .F.
		ENDIF
		This.lScreenSet = This.SetScreen(loJ.Get(loT, "screenfont", ""), loJ.Get(loT, "screenfontsize", 0), ;
			IIF(EMPTY(loJ.Get(loT, "screenback", "")), -1, This.HexToRgb(loJ.Get(loT, "screenback", ""))), ;
			IIF(EMPTY(loJ.Get(loT, "screenfore", "")), -1, This.HexToRgb(loJ.Get(loT, "screenfore", ""))))
		This.cEditorFont = This.EditorFontState(loT, loV)
		*-- Sin encadenar sobre OldCurrentKeys(): VFP da el error 31.
		loOld = This.OldCurrentKeys()
		IF !(TRANSFORM(This.oHost.Options.Get(This.cId, This.CurrentKey(), "")) == loT.Item("#id")) OR loOld.Count > 0
			This.SaveCurrent(loT.Item("#id"))
		ENDIF
		*-- Lo que deshace el tema, para el desinstalador (también cuando la
		*-- copia es de una versión que no lo escribía).
		This.WriteRestoreReg()
		This.oHost.Log("themes: " + loJ.Get(loT, "name", "") + " applied (" + loT.Item("#id") + "): " + ;
			TRANSFORM(This.nWritten) + " registry value(s) written" + This.RereadNote() + ;
			"; _SCREEN " + IIF(This.lScreenSet, "set", "unchanged") + "; editor font " + This.cEditorFont)
		IF This.cEditorFont == "overriddenByResource"
			This.oHost.LogWarn("themes: the editor font of " + loJ.Get(loT, "name", "") + " does not reach the editor: the resource " + ;
				SYS(2005) + " has its own default font (Edit > Properties > Use as default). FoxDock does not write the resource.")
		ENDIF
		This.oHost.RefreshMenu()
		RETURN .T.
	ENDPROC

	*-- Escribe los valores que no están ya: los de Options\IDE (tlIde) o los
	*-- demás. Cuenta en nWritten.
	PROCEDURE WriteValues
		LPARAMETERS toV, tlIde
		LOCAL lnI, lcKey, lcCur
		FOR lnI = 1 TO toV.Count
			lcKey = toV.GetKey(lnI)
			IF (This.IsIdeKey(lcKey) AND !tlIde) OR (!This.IsIdeKey(lcKey) AND tlIde)
				LOOP
			ENDIF
			lcCur = This.RegGet(lcKey)
			IF !(VARTYPE(lcCur) == "C" AND lcCur == toV.Item(lnI))
				IF !This.RegSet(lcKey, toV.Item(lnI))
					RETURN .F.
				ENDIF
				This.nWritten = This.nWritten + 1
			ENDIF
		ENDFOR
		RETURN .T.
	ENDPROC

	PROCEDURE IsIdeKey
		LPARAMETERS tcKey
		RETURN UPPER(LEFT(tcKey, 12)) == "OPTIONS\IDE\"
	ENDPROC

	*-- La fuente del editor: ¿llegará al próximo editor que se abra?
	PROCEDURE EditorFontState
		LPARAMETERS toT, toV
		LOCAL lnRes
		IF toV.GetKey("Options\IDE\ProgramFont") = 0
			RETURN "notInTheme"
		ENDIF
		lnRes = This.ResourceHasDefaultFont()
		RETURN ICASE(lnRes = 1, "overriddenByResource", lnRes = -1, "unknown", "applied")
	ENDPROC

	*-- 1 si el recurso en uso tiene WINDMODIFY/DEFAULT (su fuente gana a
	*-- ProgramFont), 0 si no o si no hay recurso, -1 si no se pudo
	*-- leer. Se lee con NOUPDATE y se cierra.
	PROCEDURE ResourceHasDefaultFont
		LOCAL lnSel, lnOut, loErr
		IF !(SET("RESOURCE") == "ON") OR !FILE(SYS(2005))
			RETURN 0
		ENDIF
		lnSel = SELECT()
		lnOut = -1
		TRY
			SELECT 0
			USE (SYS(2005)) AGAIN SHARED NOUPDATE ALIAS fdthemesres
			LOCATE FOR UPPER(ALLTRIM(fdthemesres.type)) == "PREFW" AND UPPER(ALLTRIM(fdthemesres.id)) == "WINDMODIFY" ;
				AND UPPER(ALLTRIM(fdthemesres.name)) == "DEFAULT"
			lnOut = IIF(FOUND(), 1, 0)
		CATCH TO loErr
			lnOut = -1
		FINALLY
			IF USED("fdthemesres")
				USE IN fdthemesres
			ENDIF
			SELECT (lnSel)
		ENDTRY
		RETURN lnOut
	ENDPROC

	*-- Pone lo que venga de _SCREEN (fuente vacía, tamaño 0 o color -1: no se
	*-- toca). Devuelve .T. si cambió algo.
	PROCEDURE SetScreen
		LPARAMETERS tcFont, tnSize, tnBack, tnFore
		LOCAL llDid
		llDid = .F.
		IF !EMPTY(tcFont) AND !(UPPER(_screen.FontName) == UPPER(ALLTRIM(tcFont)))
			_screen.FontName = ALLTRIM(tcFont)
			llDid = .T.
		ENDIF
		IF VARTYPE(tnSize) == "N" AND tnSize > 0 AND _screen.FontSize # tnSize
			_screen.FontSize = tnSize
			llDid = .T.
		ENDIF
		IF VARTYPE(tnBack) == "N" AND tnBack >= 0 AND _screen.BackColor # tnBack
			_screen.BackColor = tnBack
			llDid = .T.
		ENDIF
		IF VARTYPE(tnFore) == "N" AND tnFore >= 0 AND _screen.ForeColor # tnFore
			_screen.ForeColor = tnFore
			llDid = .T.
		ENDIF
		RETURN llDid
	ENDPROC

	PROCEDURE BackupFile
		IF EMPTY(This.cRegRoot)
			This.FindRegRoot()
		ENDIF
		RETURN This.cFolder + "backup\backup" + This.cSuffix + ".json"
	ENDPROC

	*-- El .reg que deshace el tema de este VFP: restore.reg,
	*-- restore-10.2.reg o restore-10.2-x64.reg, junto a su copia.
	PROCEDURE RestoreRegFile
		RETURN FORCEPATH("restore" + This.cSuffix + ".reg", JUSTPATH(This.BackupFile()))
	ENDPROC

	*-- Escribe RestoreRegFile() desde la copia: REGEDIT4 (ANSI), la clave
	*-- de la copia (registryRoot), los valores de antes y "Nombre"=- para los
	*-- que no existían. Sin la copia, nada. Devuelve .T. si lo escribió.
	PROCEDURE WriteRestoreReg
		LOCAL loJ, loB, loK, lcKey, lvWas, lcRoot, lcOpt, lcIde, lcLine, lcText, lcFile, loErr, llOk, lcSafety
		IF !FILE(This.BackupFile())
			RETURN .F.
		ENDIF
		loJ = This.oHost.oJson
		lcFile = This.RestoreRegFile()
		llOk = .F.
		lcSafety = SET("SAFETY")
		SET SAFETY OFF
		TRY
			loB = loJ.Parse(STRCONV(FILETOSTR(This.BackupFile()), 11))
			lcRoot = ADDBS(loJ.Get(loB, "registryRoot", This.cRegRoot))
			IF UPPER(LEFT(lcRoot, 5)) == "HKCU\"
				lcRoot = "HKEY_CURRENT_USER\" + SUBSTR(lcRoot, 6)
			ENDIF
			lcOpt = ""
			lcIde = ""
			loK = This.BackupKeys()
			FOR EACH lcKey IN loK
				lvWas = loJ.Get(loB, lcKey, .NULL.)
				lcLine = ["] + JUSTFNAME(lcKey) + ["=] + IIF(ISNULL(lvWas), "-", ;
					["] + STRTRAN(STRTRAN(TRANSFORM(lvWas), "\", "\\"), ["], [\"]) + ["]) + CRLF
				IF This.IsIdeKey(lcKey)
					lcIde = lcIde + lcLine
				ELSE
					lcOpt = lcOpt + lcLine
				ENDIF
			ENDFOR
			lcText = "REGEDIT4" + CRLF + CRLF + ;
				"; FoxDock Themes: the VFP colors from before the first theme (" + JUSTFNAME(This.BackupFile()) + ")." + CRLF + ;
				"; The uninstaller of FoxDock imports it; FoxDock > Themes > Restore VFP colors erases it." + CRLF + CRLF + ;
				"[" + lcRoot + "Options]" + CRLF + lcOpt + CRLF + "[" + lcRoot + "Options\IDE]" + CRLF + lcIde
			IF !(FILE(lcFile) AND FILETOSTR(lcFile) == lcText)
				STRTOFILE(lcText, lcFile, 0)
			ENDIF
			llOk = .T.
		CATCH TO loErr
			This.oHost.LogWarn("themes: " + lcFile + " could not be written (" + loErr.Message + "): the uninstaller will not " + ;
				"put the VFP colors back by itself")
		ENDTRY
		SET SAFETY &lcSafety
		RETURN llOk
	ENDPROC

	PROCEDURE EraseRestoreReg
		LOCAL loErr
		*-- Dentro de un paquete MSIX, la carpeta de datos no se toca (MayErase).
		IF FILE(This.RestoreRegFile()) AND (!PEMSTATUS(This.oHost, "MayErase", 5) OR ;
				This.oHost.MayErase(This.RestoreRegFile(), "the restore file of the colours"))
			TRY
				ERASE (This.RestoreRegFile())
			CATCH TO loErr
			ENDTRY
		ENDIF
	ENDPROC

	*-- Antes del primer tema: lo que había en cada clave que el plugin puede
	*-- escribir (null si no existía) y _SCREEN. Si ya existe, no se toca.
	PROCEDURE EnsureBackup
		LOCAL loJ, loB, loK, lnI, lcFile, loErr, llOk
		lcFile = This.BackupFile()
		IF FILE(lcFile)
			RETURN .T.
		ENDIF
		loJ = This.oHost.oJson
		loB = loJ.MakeObject()
		loJ.Put(loB, "takenAt", TTOC(DATETIME(), 3))
		loJ.Put(loB, "registryRoot", This.cRegRoot)
		loK = This.BackupKeys()
		FOR lnI = 1 TO loK.Count
			loJ.Put(loB, loK.Item(lnI), This.RegGet(loK.Item(lnI)))
		ENDFOR
		loJ.Put(loB, "screenFontName", _screen.FontName)
		loJ.Put(loB, "screenFontSize", _screen.FontSize)
		loJ.Put(loB, "screenBackColor", _screen.BackColor)
		loJ.Put(loB, "screenForeColor", _screen.ForeColor)
		llOk = .F.
		TRY
			IF !DIRECTORY(JUSTPATH(lcFile), 1)
				MKDIR (JUSTPATH(lcFile))
			ENDIF
			STRTOFILE(STRCONV(loJ.Stringify(loB), 9), lcFile, 0)
			llOk = .T.
		CATCH TO loErr
			This.cLastError = "the backup " + lcFile + " could not be written (" + loErr.Message + "), so no theme was applied"
		ENDTRY
		IF llOk
			This.oHost.Log("themes: backup of the VFP colors taken in " + lcFile)
		ENDIF
		RETURN llOk
	ENDPROC

	*-- Vuelve a la copia de seguridad: cada color a su valor (o se borra si no
	*-- existía), SYS(3056, 1), DESPUÉS lo de Options\IDE (la relectura lo
	*-- escribe con lo que VFP tiene en memoria), y _SCREEN. La copia
	*-- se queda. Devuelve .T./.F.
	PROCEDURE Restore
		LOCAL loJ, loB, loK, lnI, lcKey, lvWas, lvNow, lcFile
		This.cLastError = ""
		This.nWritten = 0
		This.lReread = .F.
		This.lScreenSet = .F.
		lcFile = This.BackupFile()
		IF !FILE(lcFile)
			This.cLastError = "there is nothing to restore: no theme was applied from " + This.cFolder + " (no " + lcFile + ")"
			RETURN .F.
		ENDIF
		loJ = This.oHost.oJson
		loB = loJ.Parse(STRCONV(FILETOSTR(lcFile), 11))
		loK = This.BackupKeys()
		*-- Un color que no estaba: con el valor borrado, SYS(3056, 1) deja en
		*-- los editores el que VFP tiene en memoria. Se pone el de
		*-- fábrica, se relee para que se vea, y después se borra.
		This.RestoreValues(loB, loK, .F., .T.)
		This.Reread()
		This.RestoreValues(loB, loK, .F., .F.)
		This.RestoreValues(loB, loK, .T., .F.)
		This.lScreenSet = This.SetScreen(loJ.Get(loB, "screenfontname", ""), loJ.Get(loB, "screenfontsize", 0), ;
			loJ.Get(loB, "screenbackcolor", -1), loJ.Get(loB, "screenforecolor", -1))
		This.SaveCurrent("")
		This.EraseRestoreReg()
		This.oHost.Log("themes: VFP colors restored from " + lcFile + ": " + TRANSFORM(This.nWritten) + ;
			" registry value(s) written or removed" + This.RereadNote() + "; _SCREEN " + IIF(This.lScreenSet, "set", "unchanged"))
		This.oHost.RefreshMenu()
		RETURN .T.
	ENDPROC

	*-- Cada clave de la copia (las de Options\IDE, tlIde, o las demás) a lo que
	*-- dice la copia: su valor, o fuera si era null. Con tlFactory, un color
	*-- que era null se pone a su valor de fábrica en vez de borrarse. Cuenta
	*-- en nWritten.
	PROCEDURE RestoreValues
		LPARAMETERS toB, toK, tlIde, tlFactory
		LOCAL lnI, lcKey, lvWas, lvNow
		FOR lnI = 1 TO toK.Count
			lcKey = toK.Item(lnI)
			IF (This.IsIdeKey(lcKey) AND !tlIde) OR (!This.IsIdeKey(lcKey) AND tlIde)
				LOOP
			ENDIF
			lvWas = This.oHost.oJson.Get(toB, lcKey, .NULL.)
			lvNow = This.RegGet(lcKey)
			IF tlFactory AND ISNULL(lvWas)
				IF ISNULL(lvNow)
					LOOP
				ENDIF
				lvWas = This.FactoryColor(lcKey)
			ENDIF
			DO CASE
				CASE ISNULL(lvWas) AND !ISNULL(lvNow)
					This.RegDelete(lcKey)
					This.nWritten = This.nWritten + 1
				CASE !ISNULL(lvWas) AND !(VARTYPE(lvNow) == "C" AND lvNow == lvWas)
					This.RegSet(lcKey, lvWas)
					This.nWritten = This.nWritten + 1
			ENDCASE
		ENDFOR
	ENDPROC

	*-- El valor de fábrica de un Editor<el>Color (lo que escribe
	*-- SYS(3056, 2) en un VFP recién instalado).
	PROCEDURE FactoryColor
		LPARAMETERS tcKey
		RETURN ICASE(UPPER(tcKey) == "OPTIONS\EDITORCOMMENTCOLOR", "RGB(0,128,0,255,255,255), NoAuto, Auto", ;
			UPPER(tcKey) == "OPTIONS\EDITORKEYWORDCOLOR", "RGB(0,0,255,255,255,255), NoAuto, Auto", ;
			"RGB(0,0,0,255,255,255), Auto, Auto")
	ENDPROC

	PROCEDURE RereadNote
		RETURN ICASE(This.lReread, ", reread with SYS(3056, 1)", ;
			This.nWritten = 0, " (they were already there)", ;
			", not reread: the registry root is redirected (FOXDOCK_THEMES_REGISTRY_ROOT)")
	ENDPROC

	*==============================================================
	* El registro (WScript.Shell: RegRead da error si el valor no está)
	*==============================================================

	PROCEDURE RegGet
		LPARAMETERS tcKey
		LOCAL loSh, lvV, loErr
		This.Ready()
		lvV = .NULL.
		TRY
			loSh = CREATEOBJECT("WScript.Shell")
			lvV = loSh.RegRead(This.cRegRoot + tcKey)
		CATCH TO loErr
			lvV = .NULL.
		ENDTRY
		RETURN lvV
	ENDPROC

	PROCEDURE RegSet
		LPARAMETERS tcKey, tcValue
		LOCAL loSh, loErr, llOk
		This.Ready()
		llOk = .F.
		TRY
			loSh = CREATEOBJECT("WScript.Shell")
			loSh.RegWrite(This.cRegRoot + tcKey, tcValue, "REG_SZ")
			llOk = .T.
		CATCH TO loErr
			This.cLastError = "the registry value " + This.cRegRoot + tcKey + " could not be written: " + loErr.Message
		ENDTRY
		RETURN llOk
	ENDPROC

	PROCEDURE RegDelete
		LPARAMETERS tcKey
		LOCAL loSh, loErr
		This.Ready()
		TRY
			loSh = CREATEOBJECT("WScript.Shell")
			loSh.RegDelete(This.cRegRoot + tcKey)
		CATCH TO loErr
		ENDTRY
	ENDPROC

	*==============================================================
	* El menú: FoxDock > Themes
	*==============================================================

	PROCEDURE BuildMenu
		LPARAMETERS toMenu
		*-- El título y las barras, en el idioma de FoxDock (ThemesStrings.prg).
		This.cTitle = This.oHost.Translate("themes.title")
		toMenu.FillWith("FillMenu")
	ENDPROC

	PROCEDURE FillMenu
		LPARAMETERS tcPopup
		LOCAL loList, lnI, loT, lcCur, lcCmd, lnBar, lcName
		loList = This.ThemeList()
		lcCur = This.CurrentTheme()
		lnBar = 0
		FOR lnI = 1 TO loList.Count
			loT = loList.Item(lnI)
			lnBar = lnBar + 1
			lcName = CHRTRAN(This.oHost.oJson.Get(loT, "name", ""), "[]", "()")
			lcCmd = "DEFINE BAR " + TRANSFORM(lnBar) + " OF " + tcPopup + " PROMPT [" + ;
				IIF(loT.Item("#id") == lcCur, TH_MARK, "") + lcName + "] MESSAGE [" + ;
				CHRTRAN(This.oHost.Translate("themes.apply.message", lcName), "[]", "()") + "]"
			&lcCmd
			lcCmd = [ON SELECTION BAR ] + TRANSFORM(lnBar) + [ OF ] + tcPopup + [ DO "] + This.oHost.cAppPath + ;
				[" WITH "bar", "themes", "SelectTheme", "] + loT.Item("#id") + ["]
			&lcCmd
			This.oHost.oMenu.Remember(lcCmd)
		ENDFOR
		IF lnBar = 0
			lnBar = 1
			lcCmd = "DEFINE BAR 1 OF " + tcPopup + " PROMPT [" + ;
				CHRTRAN(This.oHost.Translate("themes.none", This.cFolder), "[]", "()") + "] SKIP FOR .T."
			&lcCmd
		ENDIF
		lnBar = lnBar + 1
		lcCmd = "DEFINE BAR " + TRANSFORM(lnBar) + " OF " + tcPopup + " PROMPT [\-]"
		&lcCmd
		lnBar = lnBar + 1
		lcCmd = "DEFINE BAR " + TRANSFORM(lnBar) + " OF " + tcPopup + " PROMPT [" + This.oHost.Translate("themes.restore") + "]" + ;
			" MESSAGE [" + This.oHost.Translate("themes.restore.message") + "]"
		&lcCmd
		lcCmd = [ON SELECTION BAR ] + TRANSFORM(lnBar) + [ OF ] + tcPopup + [ DO "] + This.oHost.cAppPath + ;
			[" WITH "bar", "themes", "RestoreColors"]
		&lcCmd
		This.oHost.oMenu.Remember(lcCmd)
		lnBar = lnBar + 1
		lcCmd = "DEFINE BAR " + TRANSFORM(lnBar) + " OF " + tcPopup + " PROMPT [" + This.oHost.Translate("themes.folder") + "]" + ;
			" MESSAGE [" + CHRTRAN(This.cFolder, "[]", "()") + "]"
		&lcCmd
		lcCmd = [ON SELECTION BAR ] + TRANSFORM(lnBar) + [ OF ] + tcPopup + [ DO "] + This.oHost.cAppPath + ;
			[" WITH "bar", "themes", "OpenFolder"]
		&lcCmd
		This.oHost.oMenu.Remember(lcCmd)
	ENDPROC

	*-- Las tres acciones de las barras: sin diálogos, el resultado en la barra
	*-- de estado (Notify) y en el log.
	PROCEDURE SelectTheme
		LPARAMETERS tcId
		IF This.Apply(tcId)
			This.oHost.NotifyKey(IIF(This.cEditorFont == "overriddenByResource", "themes.appliedNoFont", "themes.applied"), ;
				This.oHost.oJson.Get(This.Find(tcId), "name", tcId))
		ELSE
			This.oHost.NotifyQuoted("themes.notApplied", This.cLastError)
		ENDIF
	ENDPROC

	PROCEDURE RestoreColors
		IF This.Restore()
			This.oHost.NotifyKey("themes.restored")
		ELSE
			This.oHost.NotifyQuoted("themes.notRestored", This.cLastError)
		ENDIF
	ENDPROC

	PROCEDURE OpenFolder
		LOCAL loSh, loErr
		IF !DIRECTORY(This.cFolder, 1)
			This.oHost.NotifyKey("themes.noFolder", This.cFolder)
			RETURN
		ENDIF
		TRY
			loSh = CREATEOBJECT("WScript.Shell")
			loSh.Run('explorer.exe "' + This.cFolder + '"', 1, .F.)
		CATCH TO loErr
			This.oHost.NotifyQuoted("themes.folderFailed", loErr.Message)
		ENDTRY
	ENDPROC

	*==============================================================
	* Las tools (ThemesTools.prg)
	*==============================================================

	PROCEDURE GetAgentTools
		LPARAMETERS toTools
		IF !("\IDETOOLS." $ UPPER(SET("PROCEDURE")))
			RETURN 0
		ENDIF
		This.EnsureProcedures()
		toTools.Add(CREATEOBJECT("IdeListThemesTool"))
		toTools.Add(CREATEOBJECT("IdeSetThemeTool"))
		RETURN 2
	ENDPROC

	PROCEDURE OnIdle
		This.EnsureProcedures()
	ENDPROC

	PROCEDURE EnsureProcedures
		LOCAL lcTools, loErr
		lcTools = This.CodeFile("ThemesTools.prg")
		IF !EMPTY(This.cHome) AND !("\THEMESTOOLS." $ UPPER(SET("PROCEDURE"))) AND FILE(lcTools)
			TRY
				SET PROCEDURE TO (lcTools) ADDITIVE
			CATCH TO loErr
				This.oHost.LogWarn("themes: " + lcTools + " not loaded: " + loErr.Message)
			ENDTRY
		ENDIF
	ENDPROC
ENDDEFINE
