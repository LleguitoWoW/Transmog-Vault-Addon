local addon, ns = ...

ns.addon = addon
ns.VERSION = "2.1.5"

-- ---------------------------------------------------------------
-- Ajustes y base de datos guardada
-- ---------------------------------------------------------------
local defaults = {
    locale = nil,            -- nil = automatico segun cliente
    scale = 1.0,
    bgColor = { 0.05, 0.055, 0.07, 1 },
    accent = { 0.35, 0.62, 1.0 },
    previewSetup = "classic", -- "classic" | "modern"
    showMinimap = true,
    minimapAngle = 215,
    notifyUnlock = true,
    tooltipTag = true,
    autoSync = true,
    autoZoom = true,         -- zoom de camara al seleccionar un hueco
    zoomFactor = 0.85,       -- intensidad (se multiplica por el zoom de la preview)
    ctrlClick = true,        -- Ctrl+clic en cualquier objeto lo prueba en el Vault
    favOnly = false,
    debug = false,
    filter = "all",          -- "all" | "unlocked" | "locked"
}
ns.defaults = defaults

local function copyDefault(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = copyDefault(x) end
    return t
end

local function mergeDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then dst[k] = copyDefault(v) end
    end
end

-- ---------------------------------------------------------------
-- Pequeno bus de eventos interno: ns:On("X", fn) / ns:Fire("X", ...)
-- ---------------------------------------------------------------
local listeners = {}
function ns:On(name, fn)
    listeners[name] = listeners[name] or {}
    table.insert(listeners[name], fn)
end
function ns:Fire(name, ...)
    local l = listeners[name]
    if not l then return end
    for i = 1, #l do l[i](...) end
end

-- ---------------------------------------------------------------
-- Utilidades
-- ---------------------------------------------------------------
function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff59a0ff[Transmog Vault]|r " .. tostring(msg))
end

function ns.Debug(...)
    if not (ns.db and ns.db.settings and ns.db.settings.debug) then return end
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    DEFAULT_CHAT_FRAME:AddMessage("|cff888888[TV debug]|r " .. table.concat(parts, " "))
end

function ns.CharKey()
    return (GetRealmName() or "?") .. "::" .. (UnitName("player") or "?")
end

-- Reloj ligero: ns.After(seg, fn)
do
    local timers = {}
    local f = CreateFrame("Frame")
    f:Hide()
    f:SetScript("OnUpdate", function(self, el)
        for i = #timers, 1, -1 do
            local t = timers[i]
            t.left = t.left - el
            if t.left <= 0 then
                table.remove(timers, i)
                t.fn()
            end
        end
        if #timers == 0 then self:Hide() end
    end)
    function ns.After(seconds, fn)
        table.insert(timers, { left = seconds, fn = fn })
        f:Show()
    end
end

-- ---------------------------------------------------------------
-- Carga
-- ---------------------------------------------------------------
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addon then
        TransmogVaultDB = TransmogVaultDB or {}
        local db = TransmogVaultDB
        db.settings = db.settings or {}
        db.looks = db.looks or {}
        db.collection = db.collection or {}
        db.favorites = db.favorites or {}      -- [primer id del grupo] = true
        mergeDefaults(db.settings, defaults)

        -- Migracion desde el addon antiguo (si se copio su SavedVariables)
        if type(TransmogACSavedLooks) == "table" and #db.looks == 0 then
            for _, l in ipairs(TransmogACSavedLooks) do
                if l.name and l.items then
                    table.insert(db.looks, { name = l.name, items = l.items })
                end
            end
        end
        ns.db = db
        ns:Fire("DB_READY")
    elseif event == "PLAYER_LOGIN" then
        ns.SetLocale(ns.db.settings.locale)
        ns:Fire("LOGIN")
    end
end)

SLASH_TRANSMOGVAULT1 = "/transmog"
SLASH_TRANSMOGVAULT2 = "/tv"
SlashCmdList["TRANSMOGVAULT"] = function(msg)
    msg = (msg or ""):lower()
    if msg == "sync" then
        ns.Unlocks.RequestSync()
    elseif msg == "minimap" then
        ns.db.settings.showMinimap = not ns.db.settings.showMinimap
        ns:Fire("MINIMAP_VISIBILITY")
    elseif msg == "debug" then
        ns.db.settings.debug = not ns.db.settings.debug
        ns.Print("debug = " .. tostring(ns.db.settings.debug))
    else
        ns:Fire("TOGGLE_WINDOW")
    end
end
