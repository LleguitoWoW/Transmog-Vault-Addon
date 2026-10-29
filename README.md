# Transmog Vault

**English** · [Español](#español)

An appearance collection album for **World of Warcraft 3.3.5a (WotLK)** private servers running **AzerothCore** with a transmog module. Every item you equip, or that the server syncs, unlocks its appearance in your collection. Browse, preview and combine looks in a clean dark interface.

> Interface `30300` · Version `2.1.5`

---

## Features

- **Collection album**: a 3D dressing room with equipment slots on both sides and a paginated grid of appearances for the selected slot.
  - Per-slot **zoomed previews**: each thumbnail shows only the relevant piece (gloves, shoulders, etc.), not the full character.
  - Collected appearances show a green check. Missing ones are darkened with a red cross.
  - Filters: All / Collected / Missing, search by name, armor/weapon type selector and a progress bar.
- **Ctrl+click any item** (bags, bank, vendors, auction house, chat links) to try it on in the Vault, even if it is not unlocked or not in the catalog.
- **Favorites**: right-click an appearance to star it. A star button filters favorites only.
- **Outfits**: save the current look, try it on, overwrite it or delete it. **Export / import** outfits as a short text (`TV1:name:ids`) to share with friends.
- **Mounts and Pets** tabs: catalog with learned / not learned state, 3D preview, filters and search. Double-click to summon or dismiss.
- **Zoom to slot**: clicking a slot smoothly zooms the main model to that area (adjustable or can be disabled).
- **Wowhead links**: Alt+click an appearance or slot to get the Wowhead link.
- **"New appearance" tooltip line** and optional chat notification on unlock.
- **Auto-sync** with the server on login (`.transmog sync`), hidden from chat.
- Settings: language (English / Spanish), model pack (classic / modern), background color, window scale, minimap button and more.
- Optimized: throttled item queries, time-sliced model dressing, debounced updates.

## Installation

1. Copy the `TransmogVault` folder into `World of Warcraft\Interface\AddOns\`.
2. Make sure your `db\` folder is inside `TransmogVault\db\` with these files:
   - `UnlockedAppearances.lua`
   - `Items.lua`
   - `Companions.lua`
   - `PreviewSetup.lua`
3. Start the game, or type `/reload`.

## Commands

| Command | Action |
|---|---|
| `/transmog` or `/tv` | Open / close the window |
| `/tv sync` | Ask the server for your collection (`.transmog sync`) |
| `/tv minimap` | Show / hide the minimap button |
| `/tv debug` | Toggle debug messages |

## Controls

| Input | Action |
|---|---|
| Click on an appearance | Try it on |
| Right-click on an appearance | Toggle favorite |
| Shift+click | Link the item in chat |
| Alt+click | Show the Wowhead link |
| Tab (while hovering) | Cycle between items sharing the same appearance |
| Ctrl+click on any item in the game | Preview it in the Vault |
| Drag / Right-drag / Wheel on the model | Rotate / move / zoom |

## How appearances are unlocked

1. `TRANSMOG_SYNC:<itemId>` messages from the server (hidden from chat).
2. Equipping an item (wearable items and weapons only).
3. A per-character saved list, restored on login without relying on the sync.
4. Static entries from `db\UnlockedAppearances.lua`.

## Troubleshooting

- **Previews look the same or empty**: check that the `db\` files are present and use `/reload`. If your client uses HD models, set *Model pack* to `modern` in Settings.
- **Ctrl+click does nothing**: enable `/tv debug`, Ctrl+click an item and check the grey chat lines. If another addon intercepts the click, disable it to test.
- **Collection looks empty**: run `/tv sync`.

## Project structure

```text
TransmogVault/
├── TransmogVault.toc
├── Core.lua        settings, events, slash commands
├── Locale.lua      en / es
├── Query.lua       throttled item query queue
├── Unlocks.lua     collection, sync, debounce
├── Data.lua        adapter for db/ (catalog, filters, companions)
├── Tooltip.lua     "New appearance" line
├── db/             your existing data folder
└── UI/
    ├── Widgets.lua  buttons, checkboxes, dropdowns, bars
    ├── Model.lua    3D viewer
    ├── Grid.lua     paginated grid
    ├── Dialogs.lua  URL, name, confirm, export, import
    ├── Main.lua     window, tabs, slots
    ├── Collection.lua / Looks.lua / Companions.lua / Settings.lua
    └── Minimap.lua
```

## Migrating from the old addon

To keep your saved outfits, before launching the game copy
`WTF\Account\<ACCOUNT>\SavedVariables\TransmogAzerothCore.lua`
to `TransmogVault.lua` in the same folder. They are imported automatically the first time.

## Credits

Based on DressMe (GetLocalPlayer) and TransmogTip (ZhengPeiRu21). Rewritten by Lleguito.

---

<a id="español"></a>

# Transmog Vault (Español)

[English](#transmog-vault) · **Español**

Álbum de apariencias para servidores privados de **World of Warcraft 3.3.5a (WotLK)** con **AzerothCore** y módulo de transmogrificación. Cada objeto que te equipas, o que el servidor sincroniza, desbloquea su apariencia en tu colección. Explora, prueba y combina looks en una interfaz oscura y limpia.

> Interface `30300` · Versión `2.1.5`

## Características

- **Álbum de colección**: probador 3D con los huecos de equipo a los lados y una rejilla paginada con las apariencias del hueco seleccionado.
  - **Miniaturas con zoom por hueco**: cada miniatura muestra solo la pieza (guantes, hombreras...), no el personaje completo.
  - Las apariencias conseguidas llevan un check verde. Las pendientes se ven oscurecidas con una cruz roja.
  - Filtros: Todo / Conseguidas / Pendientes, búsqueda por nombre, selector de tipo de armadura o arma y barra de progreso.
- **Ctrl+clic en cualquier objeto** (bolsas, banco, vendedores, subasta, enlaces del chat) para probarlo en el Vault, aunque no esté desbloqueado ni en el catálogo.
- **Favoritos**: clic derecho sobre una apariencia para marcarla con una estrella. Un botón de estrella muestra solo las favoritas.
- **Conjuntos**: guarda el atuendo actual, pruébalo, sobrescríbelo o bórralo. **Exporta / importa** conjuntos con un texto corto (`TV1:nombre:ids`) para compartirlos.
- Pestañas de **Monturas y Mascotas**: catálogo con estado aprendida / no aprendida, vista 3D, filtros y búsqueda. Doble clic para invocar o retirar.
- **Zoom al hueco**: al pulsar un hueco, el modelo central se acerca suavemente a esa zona (ajustable o desactivable).
- **Enlaces de Wowhead**: Alt+clic sobre una apariencia o un hueco.
- Línea **"Nueva apariencia"** en los tooltips y aviso opcional en el chat al desbloquear.
- **Sincronización automática** con el servidor al entrar (`.transmog sync`), oculta del chat.
- Ajustes: idioma (inglés / español), pack de modelos (classic / modern), color de fondo, escala de la ventana, botón del minimapa y más.
- Optimizado: consultas de objetos con límite, vestido de modelos repartido en el tiempo y actualizaciones agrupadas.

## Instalación

1. Copia la carpeta `TransmogVault` en `World of Warcraft\Interface\AddOns\`.
2. Comprueba que tu carpeta `db\` está dentro de `TransmogVault\db\` con estos archivos:
   - `UnlockedAppearances.lua`
   - `Items.lua`
   - `Companions.lua`
   - `PreviewSetup.lua`
3. Inicia el juego o escribe `/reload`.

## Comandos

| Comando | Acción |
|---|---|
| `/transmog` o `/tv` | Abrir / cerrar la ventana |
| `/tv sync` | Pedir al servidor tu colección (`.transmog sync`) |
| `/tv minimap` | Mostrar / ocultar el botón del minimapa |
| `/tv debug` | Activar / desactivar mensajes de depuración |

## Controles

| Acción | Resultado |
|---|---|
| Clic en una apariencia | Probarla |
| Clic derecho en una apariencia | Marcar / quitar favorita |
| Mayús+clic | Enlazar el objeto en el chat |
| Alt+clic | Mostrar el enlace de Wowhead |
| Tab (con el ratón encima) | Alternar entre objetos con la misma apariencia |
| Ctrl+clic en cualquier objeto del juego | Previsualizarlo en el Vault |
| Arrastrar / clic derecho arrastrar / rueda sobre el modelo | Rotar / mover / zoom |

## Cómo se desbloquean las apariencias

1. Mensajes `TRANSMOG_SYNC:<itemId>` del servidor (ocultos del chat).
2. Equipar un objeto (solo prendas y armas).
3. Lista guardada por personaje, que se restaura al entrar sin depender de la sincronización.
4. Entradas estáticas de `db\UnlockedAppearances.lua`.

## Solución de problemas

- **Las miniaturas salen iguales o vacías**: comprueba que los archivos de `db\` están y haz `/reload`. Si tu cliente usa modelos HD, pon *Pack de modelos* en `modern` en Ajustes.
- **Ctrl+clic no hace nada**: activa `/tv debug`, haz Ctrl+clic en un objeto y mira las líneas grises del chat. Si otro addon intercepta el clic, desactívalo para probar.
- **La colección sale vacía**: ejecuta `/tv sync`.

## Estructura del proyecto

```text
TransmogVault/
├── TransmogVault.toc
├── Core.lua        ajustes, eventos, comandos
├── Locale.lua      en / es
├── Query.lua       cola de consultas de objetos con límite
├── Unlocks.lua     colección, sync, agrupación de eventos
├── Data.lua        adaptador a db/ (catálogo, filtros, compañeros)
├── Tooltip.lua     línea "Nueva apariencia"
├── db/             tu carpeta de datos actual
└── UI/
    ├── Widgets.lua  botones, checks, desplegables, barras
    ├── Model.lua    visor 3D
    ├── Grid.lua     rejilla paginada
    ├── Dialogs.lua  URL, nombre, confirmar, exportar, importar
    ├── Main.lua     ventana, pestañas, huecos
    ├── Collection.lua / Looks.lua / Companions.lua / Settings.lua
    └── Minimap.lua
```

## Migración desde el addon antiguo

Para conservar tus conjuntos guardados, antes de abrir el juego copia
`WTF\Account\<CUENTA>\SavedVariables\TransmogAzerothCore.lua`
a `TransmogVault.lua` en esa misma carpeta. Se importan solos la primera vez.

## Créditos

Basado en DressMe (GetLocalPlayer) y TransmogTip (ZhengPeiRu21). Reescrito por Lleguito.
