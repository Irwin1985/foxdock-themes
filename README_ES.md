# foxdock-themes

El plugin `themes` de FoxDock, el sistema de plugins para el IDE de Visual FoxPro 9. Temas de color para el IDE: los colores de sintaxis, la fuente del editor, y la fuente y los colores de la ventana principal.

> También en inglés ([README.md](README.md)) y en alemán ([README_DE.md](README_DE.md)).

## Instalar

Hacen falta FoxDock y [FoxPack](https://irwinrodriguez.dev/products/foxpack).

- En FoxDock: **FoxDock > Plugins > Centro de plugins...**, **Disponibles**, elige `themes` y pulsa **Instalar**.
- Desde una consola: `foxpack plugin add themes`.

Si `themes` vino con tu instalador de FoxDock, el centro de plugins enseña sus versiones nuevas en **Actualizaciones**.

## El plugin `themes`

Cambia de una vez los colores de sintaxis, la fuente del editor de programas y la fuente y los
colores de la ventana principal (`_SCREEN`), desde **FoxDock > Temas** (FoxDock > Themes).

```
VFP classic
• Dark                 (el tema puesto lleva «•»)
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
Restaurar los colores de VFP
Abrir la carpeta de temas
```

**Qué cubre un tema, y cuándo se ve.**

| Parte | Dónde se escribe | Cuándo se ve |
|---|---|---|
| Los colores de sintaxis: comentario, palabra reservada, constante, normal, operador, cadena y variable, cada uno con su letra y su fondo | el registro (la clave del VFP en el que corre: `HKCU\Software\Microsoft\VisualFoxPro\9.0\Options` en VFP 9, `...\VisualFoxPro\10.2\Options` o `...\VisualFoxPro64\10.2\Options` en VFP Advanced; los siete valores `Editor*Color`) y `SYS(3056, 1)` | **al momento**, en los editores abiertos y en los nuevos |
| La fuente del editor de programas | `Options\IDE\ProgramFont`, después de releer (la relectura la pisaría) | en los editores de programas que abras **después**; el que ya está abierto se queda con la suya |
| La fuente y los colores de `_SCREEN` | por código | al momento. VFP guarda la fuente al salir, pero no los colores: el plugin los pone en cada arranque |

**Lo que no cubre.** Cada tema lo dice en su `notCovered`, e `ide_set_theme` lo devuelve:
- **La fuente del editor, si tu fichero de recursos (`FOXUSER.DBF`) tiene su propia fuente por defecto**
  (Edit › Properties › «Use as default»): gana la del recurso. Tampoco llega a un fichero que ya tiene su
  ventana guardada en el recurso. **FoxDock no escribe tu fichero de recursos.** Al aplicar el tema, el log
  lo avisa, e `ide_set_theme` contesta `editorFont: overriddenByResource`.
- Las ventanas del depurador, la ventana de comandos, los editores de métodos de los diseñadores y los
  editores de texto y de memo: no se han probado con un tema.
- VFP Advanced: cada versión tiene su clave, su copia de seguridad (`backup-10.2.json`, `backup-10.2-x64.json`) y su tema puesto; un tema que pones en VFP Advanced no cambia VFP 9.

**La copia de seguridad y «Restaurar los colores de VFP» (Restore VFP colors).** Antes del primer tema, el plugin guarda en
`<themes folder>\backup\backup.json` (la carpeta de temas) lo que había en cada valor que puede escribir (o que no existía),
y la fuente y los colores de `_SCREEN`. «Restaurar los colores de VFP» vuelve a eso, **también en los editores
abiertos**, y deja la copia donde está. Si después del primer tema cambias colores a mano en Options,
«Restore» vuelve a lo que había antes del primer tema, no a tus cambios.

**Desinstalar con un tema puesto.** VFP pinta los editores y la ventana de comandos con los colores que lee
del registro al abrirse, así que seguirían ahí después de desinstalar FoxDock. Mientras hay un tema puesto, el
plugin deja junto a la copia un `restore.reg` (`restore-10.2.reg` en VFP Advanced) con los valores de antes,
y el desinstalador lo importa: los colores vuelven a como los dejaría «Restaurar los colores de VFP». «Restaurar los colores de VFP»
lo borra, porque entonces no hay nada que deshacer.

El plugin escribe **solo sus propios valores**. Nunca llama a `SYS(3056, 2)`, que escribiría todas tus
opciones de golpe (es lo mismo que «Set As Default»).

**Las opciones** (`"options": { "themes": { ... } }`):
- `current`: el tema puesto (su id, el nombre del fichero). Se aplica al arrancar el IDE, y solo se
  escribe lo que no está ya.
- `folder`: otra carpeta de temas en vez de `plugins\themes\themes\`.

**Un tema** es un `.json` plano, en UTF-8, en esa carpeta. Su id es el nombre del fichero:

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

- Los elementos son `comment`, `keyword`, `constant`, `normal`, `operator`, `string` y `variable`, cada
  uno con `Fore` (la letra) y `Back` (el fondo), en `#RRGGBB`.
- **Un color que el tema no da queda en «automático»**, como en un VFP recién instalado. Por eso
  `vfp-classic.json` solo da el verde de los comentarios y el azul de las palabras reservadas, y deja los
  valores de fábrica.
- `editorFont` y `editorFontSize` (10 si falta): la fuente del editor de programas.
- `screenFont`, `screenFontSize`, `screenBack` y `screenFore`: los de `_SCREEN`. Lo que falte no se
  toca.

Un `.json` que no es un tema (no es un objeto, un color no es `#RRGGBB`, o no trae ni colores ni
fuentes) no sale en la lista, y el log dice por qué, una vez.

Para el agente hay dos tools, `ide_list_themes` e `ide_set_theme`:
AGENT-TOOLS_ES.md § 7.

## Sobre este manual

Este texto es la sección sobre `themes` del manual de plugins de FoxDock. Las referencias a otras secciones (§) y a AGENT-TOOLS apuntan a los documentos que FoxDock instala en su carpeta `docs`.

## Licencia

MIT. Está en [LICENSE](LICENSE).
