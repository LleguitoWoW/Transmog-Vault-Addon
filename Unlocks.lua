local addon, ns = ...

-- Coleccion de apariencias desbloqueadas.
--  Fuentes: db/UnlockedAppearances.lua (estatico), lista guardada por
--  personaje, mensajes TRANSMOG_SYNC del servidor y equipar objetos.
--  ns.UnlockedAppearances se mantiene como set { [itemId]=true } para
--  seguir siendo compatible con los archivos de db/.

local Unlocks = {}
ns.Unlocks = Unlocks

ns.UnlockedAppearances = ns.UnlockedAppearances or {}
local set = ns.UnlockedAppearances

local count = 0
for _ in pairs(set) do count = count + 1 end

local saved             -- set persistente del personaje
local syncing = false
local lastSyncMsg = 0
local syncAdded = 0
local manualSync = false

-- --------------------------------------------------------------
-- Debounce: cientos de mensajes de sync => un solo aviso a la UI
-- --------------------------------------------------------------
local dirty = CreateFrame("Frame")
dirty:Hide()
dirty.t = 0
dirty:SetScript("OnUpdate", function(self, el)
    self.t = self.t + el
    if self.t < 0.4 then return end
    self.t = 0
    self:Hide()
    ns:Fire("UNLOCKS_CHANGED")
end)
local function markDirty() dirty:Show() end

-- --------------------------------------------------------------
-- API
-- --------------------------------------------------------------
function Unlocks.Has(id)
    return set[id] == true
end

function Unlocks.HasAny(ids)
    if type(ids) ~= "table" then return false end
    for i = 1, #ids do
        local id = tonumber(ids[i])
        if id and set[id] then return true end
    end
    return false
end

function Unlocks.Count() return count end

-- Devuelve true si era nueva.
function Unlocks.Add(id)
    id = tonumber(id)
    if not id then return false end
    local isNew = not set[id]
    if isNew then
        set[id] = true
        count = count + 1
    end
    if saved and not saved[id] then saved[id] = true end
    if isNew then markDirty() end
    return isNew
end

function Unlocks.RequestSync()
    manualSync = true
    syncing = true
    lastSyncMsg = GetTime()
    syncAdded = 0
    ns.Print(ns.L.CHAT_SYNCING)
    SendChatMessage(".transmog sync", "SAY")
end

-- Compatibilidad con los archivos de db/
ns.UnlockAppearance = Unlocks.Add
ns.IsAppearanceUnlocked = Unlocks.Has
ns.IsAnyIdUnlocked = Unlocks.HasAny
function ns.ClearUnlockedAppearances()
    for k in pairs(set) do set[k] = nil end
    count = 0
end

-- --------------------------------------------------------------
-- Objetos equipables que cuentan como apariencia
-- --------------------------------------------------------------
local TRACKED = {
    INVTYPE_HEAD = true, INVTYPE_SHOULDER = true, INVTYPE_CLOAK = true,
    INVTYPE_CHEST = true, INVTYPE_ROBE = true, INVTYPE_BODY = true,
    INVTYPE_TABARD = true, INVTYPE_WRIST = true, INVTYPE_HAND = true,
    INVTYPE_WAIST = true, INVTYPE_LEGS = true, INVTYPE_FEET = true,
    INVTYPE_WEAPON = true, INVTYPE_2HWEAPON = true,
    INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true,
    INVTYPE_SHIELD = true, INVTYPE_HOLDABLE = true,
    INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true,
}
ns.TRACKED_EQUIPLOC = TRACKED

function Unlocks.IsTrackable(itemId)
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemId)
    return equipLoc ~= nil and TRACKED[equipLoc] == true
end

-- --------------------------------------------------------------
-- Eventos
-- --------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
ev:SetScript("OnEvent", function(_, event, slot)
    local id = GetInventoryItemID("player", slot)
    if not id or not Unlocks.IsTrackable(id) then return end
    if Unlocks.Add(id) and not syncing and ns.db and ns.db.settings.notifyUnlock then
        local _, link = GetItemInfo(id)
        ns.Print(ns.L.CHAT_UNLOCK:format(link or ("item " .. id)))
    end
end)

-- Mensajes del servidor: TRANSMOG_SYNC:<id> (se ocultan del chat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, msg)
    if type(msg) ~= "string" then return end
    local id = msg:match("TRANSMOG_SYNC:(%d+)")
    if not id then return end
    if Unlocks.Add(id) then syncAdded = syncAdded + 1 end
    syncing = true
    lastSyncMsg = GetTime()
    return true
end)

-- Detecta el fin de la sync (3 s sin mensajes) y avisa una sola vez
local watcher = CreateFrame("Frame")
watcher.t = 0
watcher:SetScript("OnUpdate", function(self, el)
    if not syncing then return end
    self.t = self.t + el
    if self.t < 0.5 then return end
    self.t = 0
    if GetTime() - lastSyncMsg >= 3 then
        syncing = false
        if manualSync or syncAdded > 0 then
            ns.Print(ns.L.CHAT_SYNCED:format(count))
        end
        manualSync = false
        syncAdded = 0
    end
end)

ns:On("DB_READY", function() end)

ns:On("LOGIN", function()
    local key = ns.CharKey()
    ns.db.collection[key] = ns.db.collection[key] or {}
    saved = ns.db.collection[key]
    -- Vuelca lo guardado: la rejilla ya no depende de que el servidor responda
    for id in pairs(saved) do
        if not set[id] then
            set[id] = true
            count = count + 1
        end
    end
    -- Migracion del addon antiguo (TransmogTipDB[key] = lista de ids)
    local old = TransmogTipDB and TransmogTipDB[key]
    if type(old) == "table" then
        for k, v in pairs(old) do
            local id = (type(v) == "number") and v or ((v == true) and k or nil)
            if id and id > 0 then
                saved[id] = true
                if not set[id] then set[id] = true; count = count + 1 end
            end
        end
    end
    markDirty()
    if ns.db.settings.autoSync then
        ns.After(4, function()
            syncing = true
            lastSyncMsg = GetTime()
            SendChatMessage(".transmog sync", "SAY")
        end)
    end
end)
