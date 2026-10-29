local addon, ns = ...

local T = {}

T.en = {
    TITLE = "Transmog Vault",
    TAB_COLLECTION = "Collection",
    TAB_LOOKS = "Outfits",
    TAB_MOUNTS = "Mounts",
    TAB_PETS = "Pets",
    TAB_SETTINGS = "Settings",

    RESET = "Reset",
    UNDRESS = "Undress",
    USE_TARGET = "Target",
    USE_TARGET_TIP = "Use your target's model (must be in inspect range).",
    ROOM_TIP = "Drag: rotate  |  Right-drag: move  |  Wheel: zoom",

    FILTER_ALL = "All",
    FILTER_UNLOCKED = "Collected",
    FILTER_LOCKED = "Missing",
    SEARCH = "Search...",
    PAGE = "Page %d / %d",
    PROGRESS = "%d / %d collected",
    NO_RESULTS = "Nothing to show here.",
    LOADING = "Loading...",
    QUERY_FAILED = "Not found on server",

    LOCKED_TIP = "Not collected yet",
    COLLECTED_TIP = "Collected",
    PROVIDED_BY = "Provided by:",
    CLICK_TRY = "|cff59a0ffClick:|r try on",
    TAB_CYCLE = "|cff59a0ffTab:|r switch item",
    SHIFT_LINK = "|cff59a0ffShift+Click:|r link item",
    CTRL_URL = "|cff59a0ffAlt+Click:|r Wowhead link",
    SLOT_CLEAR = "|cff59a0ffRight-click:|r clear slot",
    NOT_TRANSMOGGABLE = "That item cannot be used for transmogrification.",

    LOOKS_NEW = "Save current",
    LOOKS_APPLY = "Try on",
    LOOKS_DELETE = "Delete",
    LOOKS_OVERWRITE = "Overwrite",
    LOOKS_NAME = "Outfit name:",
    LOOKS_EMPTY = "No saved outfits.\nDress the model and press \"Save current\".",
    LOOKS_CONFIRM_DELETE = "Delete outfit \"%s\"?",
    SAVE = "Save",
    CANCEL = "Cancel",
    YES = "Yes",
    NO = "No",

    MOUNTS_EMPTY = "No mounts to show.",
    PETS_EMPTY = "No pets to show.",
    SUMMON = "Summon / dismiss",
    PREVIEW_HINT = "Click: preview  |  Double-click: summon",
    ACTIVE = "Active",
    NOT_LEARNED = "Not learned",

    SET_APPEARANCE = "Appearance",
    SET_LANGUAGE = "Language",
    SET_AUTO = "Automatic",
    SET_BG = "Model background",
    SET_SETUP = "Model pack",
    SET_SETUP_TIP = "Use \"modern\" only if your client has the HD (Warlords) models mod.",
    SET_SCALE = "Window scale",
    SET_BEHAVIOUR = "Behaviour",
    SET_MINIMAP = "Show minimap button",
    SET_NOTIFY = "Chat message on new appearance",
    SET_TOOLTIP = "\"New appearance\" line in item tooltips",
    SET_AUTOSYNC = "Sync collection with server on login",
    SET_DEBUG = "Debug messages",
    SET_SYNC_NOW = "Sync now",
    SET_RESET_POS = "Reset window position",

    CHAT_UNLOCK = "New appearance: %s",
    CHAT_SYNCED = "Collection synced: %d appearances.",
    CHAT_SYNCING = "Syncing collection...",
    TIP_NEW = "|cff59a0ffNew appearance|r",


    FAV_TIP = "|cff59a0ffRight-click:|r favorite",
    FAV_TAG = "|cffffd100Favorite|r",
    FAV_ONLY = "Favorites only",

    LOOKS_EXPORT = "Export",
    LOOKS_IMPORT = "Import",
    LOOKS_EXPORT_TEXT = "Copy this text (Ctrl+C) and share it:",
    LOOKS_IMPORT_TEXT = "Paste the outfit text here:",
    LOOKS_IMPORT_BAD = "That text is not a valid outfit.",
    LOOKS_IMPORTED = "Outfit imported: %s",

    SET_CTRLCLICK = "Ctrl+click on any item previews it here",
    SET_AUTOZOOM = "Zoom to the selected slot",
    SET_ZOOMFACTOR = "Zoom strength",

    MM_TITLE = "Transmog Vault",
    MM_CLICK = "Click: open / close",
    MM_DRAG = "Drag: move button",
}

T.es = {
    TITLE = "Transmog Vault",
    TAB_COLLECTION = "Colección",
    TAB_LOOKS = "Conjuntos",
    TAB_MOUNTS = "Monturas",
    TAB_PETS = "Mascotas",
    TAB_SETTINGS = "Ajustes",

    RESET = "Reiniciar",
    UNDRESS = "Desvestir",
    USE_TARGET = "Objetivo",
    USE_TARGET_TIP = "Usa el modelo de tu objetivo (a distancia de inspección).",
    ROOM_TIP = "Arrastrar: rotar  |  Clic dcho: mover  |  Rueda: zoom",

    FILTER_ALL = "Todo",
    FILTER_UNLOCKED = "Conseguidas",
    FILTER_LOCKED = "Pendientes",
    SEARCH = "Buscar...",
    PAGE = "Página %d / %d",
    PROGRESS = "%d / %d conseguidas",
    NO_RESULTS = "No hay nada que mostrar.",
    LOADING = "Cargando...",
    QUERY_FAILED = "No existe en el servidor",

    LOCKED_TIP = "Aún no conseguida",
    COLLECTED_TIP = "Conseguida",
    PROVIDED_BY = "Aportada por:",
    CLICK_TRY = "|cff59a0ffClic:|r probar",
    TAB_CYCLE = "|cff59a0ffTab:|r cambiar objeto",
    SHIFT_LINK = "|cff59a0ffMayús+Clic:|r enlazar objeto",
    CTRL_URL = "|cff59a0ffAlt+Clic:|r enlace de Wowhead",
    SLOT_CLEAR = "|cff59a0ffClic dcho:|r vaciar hueco",
    NOT_TRANSMOGGABLE = "Ese objeto no se puede usar para transmogrificar.",

    LOOKS_NEW = "Guardar actual",
    LOOKS_APPLY = "Probar",
    LOOKS_DELETE = "Borrar",
    LOOKS_OVERWRITE = "Sobrescribir",
    LOOKS_NAME = "Nombre del conjunto:",
    LOOKS_EMPTY = "No hay conjuntos guardados.\nVista al modelo y pulsa \"Guardar actual\".",
    LOOKS_CONFIRM_DELETE = "¿Borrar el conjunto \"%s\"?",
    SAVE = "Guardar",
    CANCEL = "Cancelar",
    YES = "Sí",
    NO = "No",

    MOUNTS_EMPTY = "No hay monturas que mostrar.",
    PETS_EMPTY = "No hay mascotas que mostrar.",
    SUMMON = "Invocar / retirar",
    PREVIEW_HINT = "Clic: vista previa  |  Doble clic: invocar",
    ACTIVE = "Activa",
    NOT_LEARNED = "No aprendida",

    SET_APPEARANCE = "Apariencia",
    SET_LANGUAGE = "Idioma",
    SET_AUTO = "Automático",
    SET_BG = "Fondo del modelo",
    SET_SETUP = "Pack de modelos",
    SET_SETUP_TIP = "Usa \"modern\" solo si tu cliente tiene el mod de modelos HD (Warlords).",
    SET_SCALE = "Escala de la ventana",
    SET_BEHAVIOUR = "Comportamiento",
    SET_MINIMAP = "Mostrar botón del minimapa",
    SET_NOTIFY = "Mensaje en el chat al conseguir apariencia",
    SET_TOOLTIP = "Línea \"Nueva apariencia\" en los tooltips",
    SET_AUTOSYNC = "Sincronizar con el servidor al entrar",
    SET_DEBUG = "Mensajes de depuración",
    SET_SYNC_NOW = "Sincronizar ahora",
    SET_RESET_POS = "Restablecer posición de la ventana",

    CHAT_UNLOCK = "Nueva apariencia: %s",
    CHAT_SYNCED = "Colección sincronizada: %d apariencias.",
    CHAT_SYNCING = "Sincronizando colección...",
    TIP_NEW = "|cff59a0ffNueva apariencia|r",


    FAV_TIP = "|cff59a0ffClic derecho:|r favorita",
    FAV_TAG = "|cffffd100Favorita|r",
    FAV_ONLY = "Solo favoritas",

    LOOKS_EXPORT = "Exportar",
    LOOKS_IMPORT = "Importar",
    LOOKS_EXPORT_TEXT = "Copia este texto (Ctrl+C) y compártelo:",
    LOOKS_IMPORT_TEXT = "Pega aquí el texto del conjunto:",
    LOOKS_IMPORT_BAD = "Ese texto no es un conjunto válido.",
    LOOKS_IMPORTED = "Conjunto importado: %s",

    SET_CTRLCLICK = "Ctrl+clic en cualquier objeto lo prueba aquí",
    SET_AUTOZOOM = "Zoom al hueco seleccionado",
    SET_ZOOMFACTOR = "Intensidad del zoom",

    MM_TITLE = "Transmog Vault",
    MM_CLICK = "Clic: abrir / cerrar",
    MM_DRAG = "Arrastrar: mover botón",
}

ns.LOCALES = { "en", "es" }
ns.locale = "en"

-- ns.L.KEY -> texto; si falta en el idioma activo cae a ingles, y luego a la clave.
ns.L = setmetatable({}, {
    __index = function(_, k)
        local v = (T[ns.locale] and T[ns.locale][k]) or T.en[k]
        return v or k
    end,
})

local function detect()
    local loc = GetLocale and GetLocale() or "enUS"
    if loc == "esES" or loc == "esMX" then return "es" end
    return "en"
end

function ns.SetLocale(code)
    if code ~= "en" and code ~= "es" then code = detect() end
    ns.locale = code
    ns:Fire("LOCALE_CHANGED", code)
end
