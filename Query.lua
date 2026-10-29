local addon, ns = ...

-- Cola de consultas de items al servidor.
--   ns.Query(itemId, function(itemId, ok) ... end)
-- * Reparte las peticiones (max. por tick) para no inundar al servidor.
-- * Tiempo maximo corto: un item inexistente falla en pocos segundos.

local TICK = 0.12          -- segundos entre comprobaciones
local TIMEOUT = 12         -- segundos hasta dar un item por fallido
local MAX_REQUESTS_PER_TICK = 6

local tip = CreateFrame("GameTooltip", "TransmogVaultScanTip", UIParent, "GameTooltipTemplate")
tip:SetOwner(UIParent, "ANCHOR_NONE")

local pending = {}     -- [itemId] = { handlers = {}, left = TIMEOUT, requested = false }
local order = {}       -- ids en orden de llegada
local frame = CreateFrame("Frame")
frame:Hide()
local acc = 0

local function finish(id, ok)
    local q = pending[id]
    if not q then return end
    pending[id] = nil
    for i = #order, 1, -1 do
        if order[i] == id then table.remove(order, i) break end
    end
    for i = 1, #q.handlers do
        local h = q.handlers[i]
        h(id, ok)
    end
end

frame:SetScript("OnUpdate", function(self, el)
    acc = acc + el
    if acc < TICK then return end
    local dt = acc
    acc = 0

    local requests = 0
    local snapshot = {}
    for i = 1, #order do snapshot[i] = order[i] end

    for i = 1, #snapshot do
        local id = snapshot[i]
        local q = pending[id]
        if q then
            if GetItemInfo(id) then
                finish(id, true)
            else
                if not q.requested and requests < MAX_REQUESTS_PER_TICK then
                    q.requested = true
                    requests = requests + 1
                    tip:SetOwner(UIParent, "ANCHOR_NONE")
                    tip:SetHyperlink("item:" .. id .. ":0:0:0:0:0:0:0")
                end
                if q.requested then
                    q.left = q.left - dt
                    if q.left <= 0 then finish(id, false) end
                end
            end
        end
    end

    if #order == 0 then self:Hide() end
end)

function ns.Query(itemId, handler)
    if GetItemInfo(itemId) then
        handler(itemId, true)
        return
    end
    local q = pending[itemId]
    if not q then
        q = { handlers = {}, left = TIMEOUT, requested = false }
        pending[itemId] = q
        table.insert(order, itemId)
    end
    table.insert(q.handlers, handler)
    frame:Show()
end

-- Descarta las consultas aun no lanzadas (al cambiar de pagina rapido).
function ns.QueryDropPending()
    for i = #order, 1, -1 do
        local id = order[i]
        local q = pending[id]
        if q and not q.requested then
            pending[id] = nil
            table.remove(order, i)
        end
    end
end
