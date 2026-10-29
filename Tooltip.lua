local addon, ns = ...

-- Linea "Nueva apariencia" en los tooltips de objetos equipables que aun no
-- estan en la coleccion. Marca cada tooltip para no duplicar la linea.

local SLOT_BY_EQUIPLOC = {
    INVTYPE_HEAD = "Head", INVTYPE_SHOULDER = "Shoulder", INVTYPE_CLOAK = "Back",
    INVTYPE_CHEST = "Chest", INVTYPE_ROBE = "Chest", INVTYPE_BODY = "Shirt",
    INVTYPE_TABARD = "Tabard", INVTYPE_WRIST = "Wrist", INVTYPE_HAND = "Hands",
    INVTYPE_WAIST = "Waist", INVTYPE_LEGS = "Legs", INVTYPE_FEET = "Feet",
    INVTYPE_WEAPON = "Main Hand", INVTYPE_2HWEAPON = "Main Hand", INVTYPE_WEAPONMAINHAND = "Main Hand",
    INVTYPE_SHIELD = "Off-hand", INVTYPE_HOLDABLE = "Off-hand", INVTYPE_WEAPONOFFHAND = "Off-hand",
    INVTYPE_RANGED = "Ranged", INVTYPE_RANGEDRIGHT = "Ranged", INVTYPE_THROWN = "Ranged",
}

local groupCache = {}   -- [itemId] = ids | false

local function groupOf(id, slot)
    local g = groupCache[id]
    if g == nil then
        local ids = ns.Data.GetGroup(id, slot)
        g = ids or false
        groupCache[id] = g
    end
    return g
end

local function isNew(id)
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(id)
    local slot = equipLoc and SLOT_BY_EQUIPLOC[equipLoc]
    if not slot then return false end
    if ns.Unlocks.Has(id) then return false end
    local g = groupOf(id, slot)
    if g and ns.Unlocks.HasAny(g) then return false end
    return true
end

local function onItem(self)
    if self._tvTagged then return end
    if not (ns.db and ns.db.settings.tooltipTag) then return end
    local _, link = self:GetItem()
    if not link then return end
    local id = tonumber(link:match("item:(%d+)"))
    if id and isNew(id) then
        self._tvTagged = true
        self:AddLine(ns.L.TIP_NEW)
        self:Show()
    end
end

local function onCleared(self) self._tvTagged = nil end

for _, name in ipairs({ "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
    "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2" }) do
    local tip = _G[name]
    if tip then
        tip:HookScript("OnTooltipSetItem", onItem)
        tip:HookScript("OnTooltipCleared", onCleared)
    end
end

ns:On("UNLOCKS_CHANGED", function() groupCache = {} end)
