local addon, ns = ...

-- Adaptador a los archivos de db/. Todo lo que la UI necesita del catalogo
-- pasa por aqui, con cache y orden estable.

local Data = {}
ns.Data = Data

local _, raceFile = UnitRace("player")
local _, classFile = UnitClass("player")
local sex = UnitSex("player")
Data.raceFile, Data.classFile, Data.sex = raceFile, classFile, sex

-- Orden de huecos (NO cambiar: compatible con los looks guardados antiguos)
Data.SLOT_ORDER = { "Head", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist",
    "Hands", "Waist", "Legs", "Feet", "Main Hand", "Off-hand", "Ranged" }

-- Hueco -> nombre de inventario y icono vacio
Data.SLOT_INFO = {
    ["Head"]      = { inv = "HeadSlot",          icon = "ui-paperdoll-slot-head" },
    ["Shoulder"]  = { inv = "ShoulderSlot",      icon = "ui-paperdoll-slot-shoulder" },
    ["Back"]      = { inv = "BackSlot",          icon = "ui-paperdoll-slot-chest" },
    ["Chest"]     = { inv = "ChestSlot",         icon = "ui-paperdoll-slot-chest" },
    ["Shirt"]     = { inv = "ShirtSlot",         icon = "ui-paperdoll-slot-shirt" },
    ["Tabard"]    = { inv = "TabardSlot",        icon = "ui-paperdoll-slot-tabard" },
    ["Wrist"]     = { inv = "WristSlot",         icon = "ui-paperdoll-slot-wrists" },
    ["Hands"]     = { inv = "HandsSlot",         icon = "ui-paperdoll-slot-hands" },
    ["Waist"]     = { inv = "WaistSlot",         icon = "ui-paperdoll-slot-waist" },
    ["Legs"]      = { inv = "LegsSlot",          icon = "ui-paperdoll-slot-legs" },
    ["Feet"]      = { inv = "FeetSlot",          icon = "ui-paperdoll-slot-feet" },
    ["Main Hand"] = { inv = "MainHandSlot",      icon = "ui-paperdoll-slot-mainhand" },
    ["Off-hand"]  = { inv = "SecondaryHandSlot", icon = "ui-paperdoll-slot-secondaryhand" },
    ["Ranged"]    = { inv = "RangedSlot",        icon = "ui-paperdoll-slot-ranged" },
}

-- Columna izquierda / derecha del paperdoll
Data.LEFT_SLOTS  = { "Head", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist" }
Data.RIGHT_SLOTS = { "Hands", "Waist", "Legs", "Feet" }
Data.BOTTOM_SLOTS = { "Main Hand", "Off-hand", "Ranged" }

local ARMOR = { "Cloth", "Leather", "Mail", "Plate", "Miscellaneous" }  -- las vacias se ocultan (GetSubclasses)
Data.SUBCLASSES = {
    Head = ARMOR, Shoulder = ARMOR, Chest = ARMOR, Wrist = ARMOR,
    Hands = ARMOR, Waist = ARMOR, Legs = ARMOR, Feet = ARMOR,
    Back = ARMOR,
    Shirt = { "Miscellaneous" },
    Tabard = { "Miscellaneous" },
    ["Main Hand"] = {
        "1H Axe", "1H Mace", "1H Sword", "1H Dagger", "1H Fist",
        "MH Axe", "MH Mace", "MH Sword", "MH Dagger", "MH Fist",
        "2H Axe", "2H Mace", "2H Sword", "Polearm", "Staff",
    },
    ["Off-hand"] = {
        "OH Axe", "OH Mace", "OH Sword", "OH Dagger", "OH Fist",
        "1H Axe", "1H Mace", "1H Sword", "1H Dagger", "1H Fist",   -- armas 1M tambien en mano izquierda
        "Shield", "Held in Off-hand",
    },
    ["Ranged"] = { "Bow", "Crossbow", "Gun", "Wand", "Thrown" },
}

local DEFAULT_ARMOR = {
    MAGE = "Cloth", PRIEST = "Cloth", WARLOCK = "Cloth",
    DRUID = "Leather", ROGUE = "Leather",
    HUNTER = "Mail", SHAMAN = "Mail",
    PALADIN = "Plate", WARRIOR = "Plate", DEATHKNIGHT = "Plate",
}

-- Subclases con contenido real (cacheado). Siempre devuelve al menos una.
local subCache = {}
function Data.GetSubclasses(slot)
    local c = subCache[slot]
    if c then return c end
    c = {}
    local cand = Data.SUBCLASSES[slot] or {}
    for _, sub in ipairs(cand) do
        if #Data.GetCatalog(slot, sub) > 0 then c[#c + 1] = sub end
    end
    if #c == 0 and cand[1] then c[1] = cand[1] end
    subCache[slot] = c
    return c
end

function Data.DefaultSubclass(slot)
    local list = Data.GetSubclasses(slot)
    if #list == 0 then return nil end
    local want = DEFAULT_ARMOR[classFile]
    if want then
        for _, sub in ipairs(list) do if sub == want then return want end end
    end
    return list[1]
end

-- --------------------------------------------------------------
-- Catalogo: array de { {ids...}, {names...} } ordenado por primer id
-- --------------------------------------------------------------
local catalogCache = {}

local function rawCatalog(slot, subclass)
    -- Items.lua guarda su tabla en una variable LOCAL, asi que la unica via es
    -- ns.GetSubclassAppearances. Esa funcion filtra por desbloqueados salvo que
    -- ns.UnlockedAppearances este vacio, asi que lo vaciamos un instante (sincrono,
    -- dentro de pcall) y lo restauramos. El resultado se cachea abajo.
    if type(ns.GetSubclassAppearances) == "function" then
        local saved = ns.UnlockedAppearances
        ns.UnlockedAppearances = {}
        local ok, r = pcall(ns.GetSubclassAppearances, slot, subclass)
        ns.UnlockedAppearances = saved
        if ok and type(r) == "table" then return r end
    end
    local items = ns.itemsData
    if type(items) == "table" then
        local s = items[slot] or (type(items.Armor) == "table" and items.Armor[slot])
        if type(s) == "table" and type(s[subclass]) == "table" then return s[subclass] end
    end
    return {}
end

function Data.GetCatalog(slot, subclass)
    local key = slot .. "|" .. subclass
    local c = catalogCache[key]
    if c then return c end
    c = {}
    for _, entry in pairs(rawCatalog(slot, subclass)) do
        if type(entry) == "table" and type(entry[1]) == "table" and entry[1][1] then
            c[#c + 1] = entry
        end
    end
    table.sort(c, function(a, b) return (a[1][1] or 0) < (b[1][1] or 0) end)
    catalogCache[key] = c
    return c
end

-- Cuenta conseguidas/total de una lista (con cache invalidada por cambios)
local countCache = {}
ns:On("UNLOCKS_CHANGED", function() countCache = {} end)

function Data.GetCounts(slot, subclass)
    local key = slot .. "|" .. subclass
    local c = countCache[key]
    if c then return c[1], c[2] end
    local list = Data.GetCatalog(slot, subclass)
    local have = 0
    for i = 1, #list do
        if ns.Unlocks.HasAny(list[i][1]) then have = have + 1 end
    end
    countCache[key] = { have, #list }
    return have, #list
end

-- Lista filtrada ("all" | "unlocked" | "locked") y por texto (nombre)
function Data.GetFiltered(slot, subclass, filter, search, favOnly)
    local list = Data.GetCatalog(slot, subclass)
    search = search and search:lower() or ""
    if filter == "all" and search == "" and not favOnly then return list end
    local favs = ns.db and ns.db.favorites or {}
    local function plain(t) return (t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()) end
    local out = {}
    for i = 1, #list do
        local e = list[i]
        local ok = true
        if favOnly and not favs[e[1][1]] then ok = false end
        if ok and filter ~= "all" then
            local u = ns.Unlocks.HasAny(e[1])
            ok = (filter == "unlocked") == u
        end
        if ok and search ~= "" then
            ok = false
            for n = 1, #(e[2] or {}) do
                if e[2][n] and plain(e[2][n]):find(search, 1, true) then ok = true break end
            end
        end
        if ok then out[#out + 1] = e end
    end
    return out
end

-- Datos de camara de cada preview pequeno
local DEFAULT_SETUP = { width = 100, height = 120, x = 2.8, y = 0, z = 0.1, facing = 0, sequence = 3 }
function Data.GetPreviewSetup(slot, subclass)
    if type(ns.GetPreviewSetup) ~= "function" then return DEFAULT_SETUP end
    local version = ns.db and ns.db.settings.previewSetup or "classic"
    local ok, r = pcall(ns.GetPreviewSetup, version, raceFile, sex, slot, subclass)
    if ok and type(r) == "table" then return r end
    return DEFAULT_SETUP
end

-- ids, names, index, subclassName del grupo de apariencia de un item
function Data.GetGroup(itemId, slot)
    if type(ns.GetOtherAppearances) ~= "function" then return nil end
    local ok, ids, names, index, sub = pcall(ns.GetOtherAppearances, itemId, slot)
    if ok and ids then return ids, names, index, sub end
end

-- --------------------------------------------------------------
-- Companeros
-- --------------------------------------------------------------
Data.COMPANION_TYPES = { mounts = "MOUNT", pets = "CRITTER" }

function Data.GetCompanions(ctype)
    local learned, learnedCount = {}, 0
    for i = 1, (GetNumCompanions(ctype) or 0) do
        local creatureId, name, spellId, icon, summoned = GetCompanionInfo(ctype, i)
        if spellId then
            learned[spellId] = { index = i, creatureId = creatureId, name = name,
                spellId = spellId, icon = icon, summoned = summoned and true or false }
            learnedCount = learnedCount + 1
        end
    end
    local catalog = (ns.CompanionCatalog and ns.CompanionCatalog[ctype]) or {}
    local list, seen = {}, {}
    for _, e in ipairs(catalog) do
        if e.spellId then
            seen[e.spellId] = true
            local u = learned[e.spellId]
            list[#list + 1] = {
                spellId = e.spellId,
                name = (u and u.name) or e.name or ("#" .. e.spellId),
                creatureId = u and u.creatureId,   -- solo las aprendidas tienen modelo
                itemId = e.itemId,
                icon = u and u.icon,               -- el resto se resuelve por itemId en la UI
                index = u and u.index,
                learned = u ~= nil,
                summoned = u and u.summoned or false,
            }
        end
    end
    -- Aprendidas que no estan en el catalogo
    for spellId, u in pairs(learned) do
        if not seen[spellId] then
            list[#list + 1] = { spellId = spellId, name = u.name, creatureId = u.creatureId,
                icon = u.icon, index = u.index, learned = true, summoned = u.summoned }
        end
    end
    table.sort(list, function(a, b)
        if a.learned ~= b.learned then return a.learned end
        return (a.name or "") < (b.name or "")
    end)
    return list, learnedCount
end

-- --------------------------------------------------------------
-- Tipo de equipo -> huecos posibles (para Ctrl+clic desde el juego)
-- --------------------------------------------------------------
Data.SLOTS_FOR_EQUIPLOC = {
    INVTYPE_HEAD = { "Head" }, INVTYPE_SHOULDER = { "Shoulder" }, INVTYPE_CLOAK = { "Back" },
    INVTYPE_CHEST = { "Chest" }, INVTYPE_ROBE = { "Chest" }, INVTYPE_BODY = { "Shirt" },
    INVTYPE_TABARD = { "Tabard" }, INVTYPE_WRIST = { "Wrist" }, INVTYPE_HAND = { "Hands" },
    INVTYPE_WAIST = { "Waist" }, INVTYPE_LEGS = { "Legs" }, INVTYPE_FEET = { "Feet" },
    INVTYPE_WEAPON = { "Main Hand", "Off-hand" }, INVTYPE_2HWEAPON = { "Main Hand" },
    INVTYPE_WEAPONMAINHAND = { "Main Hand" }, INVTYPE_WEAPONOFFHAND = { "Off-hand" },
    INVTYPE_SHIELD = { "Off-hand" }, INVTYPE_HOLDABLE = { "Off-hand" },
    INVTYPE_RANGED = { "Ranged" }, INVTYPE_RANGEDRIGHT = { "Ranged" }, INVTYPE_THROWN = { "Ranged" },
}
