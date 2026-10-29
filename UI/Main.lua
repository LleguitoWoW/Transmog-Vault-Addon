local addon, ns = ...
local UI = ns.UI
local C = UI.color
local Data = ns.Data

-- ================================================================
-- Ventana principal: cabecera con pestanas + panel izquierdo (modelo y
-- huecos) + zona derecha donde cada pestana pinta su pagina.
-- ================================================================

local W, H = 1140, 640
local LEFT_W = 392

-- --------------------------------------------------------------
-- Textos enlazados a idioma: ns.Bind(obj, "CLAVE" | funcion, "SetText")
-- --------------------------------------------------------------
local binds = {}
function ns.Bind(obj, key, method)
    method = method or "SetText"
    table.insert(binds, { obj = obj, key = key, method = method })
    local text = type(key) == "function" and key() or ns.L[key]
    obj[method](obj, text)
end
ns:On("LOCALE_CHANGED", function()
    for _, b in ipairs(binds) do
        local text = type(b.key) == "function" and b.key() or ns.L[b.key]
        b.obj[b.method](b.obj, text)
    end
end)

-- --------------------------------------------------------------
-- Registro de pestanas
-- --------------------------------------------------------------
local tabDefs = {}
function ns.RegisterTab(def) table.insert(tabDefs, def) end

local Win = {}
ns.Window = Win
Win.tabs = {}

local frame

local function selectTab(key)
    for k, t in pairs(Win.tabs) do
        local on = (k == key)
        t.button:SetActive(on)
        if on then
            t.page:Show()
            if t.def.onShow then t.def.onShow(t.page) end
        else
            t.page:Hide()
        end
    end
    local def = Win.tabs[key].def
    if def.model then Win.left:Show() else Win.left:Hide() end
    Win.content:ClearAllPoints()
    Win.content:SetPoint("TOPLEFT", def.model and (LEFT_W + 20) or 10, -56)
    Win.content:SetPoint("BOTTOMRIGHT", -10, 10)
    Win.currentTab = key
    ns.db.settings.lastTab = key
end
Win.SelectTab = function(_, key) selectTab(key) end

-- --------------------------------------------------------------
-- Huecos del muneco
-- --------------------------------------------------------------
local slots = {}
Win.slots = slots

local function makeSlot(parent, slotName)
    local info = Data.SLOT_INFO[slotName]
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(42, 42)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    UI.Flat(b, C.panel2, C.border)
    b.slotName = slotName

    b.empty = b:CreateTexture(nil, "ARTWORK")
    b.empty:SetPoint("TOPLEFT", 3, -3); b.empty:SetPoint("BOTTOMRIGHT", -3, 3)
    b.empty:SetTexture("Interface\\Paperdoll\\" .. info.icon)
    b.empty:SetAlpha(0.45)
    b.icon = b:CreateTexture(nil, "OVERLAY")
    b.icon:SetPoint("TOPLEFT", 2, -2); b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.icon:Hide()

    function b:SetSelected(v)
        self.selected = v
        if v then self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        else self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1) end
    end

    function b:Wipe()
        self.itemId, self.displayId, self.itemName = nil, nil, nil
        self.icon:Hide(); self.empty:Show()
    end

    function b:SetItemVisual(texture)
        self.icon:SetTexture(texture); self.icon:Show(); self.empty:Hide()
    end

    -- Vestir un objeto (itemId elegido dentro de su grupo de apariencia)
    -- force = true: probar aunque el objeto no este en el catalogo (Ctrl+clic desde el juego)
    function b:Apply(itemId, force)
        local ids, names, index = Data.GetGroup(itemId, slotName)
        if not ids then
            if not force then
                UIErrorsFrame:AddMessage(ns.L.NOT_TRANSMOGGABLE, 1, 0.3, 0.3)
                return false
            end
            ids, names, index = { itemId }, { (GetItemInfo(itemId)) or ("item " .. itemId) }, 1
        end
        self.itemId, self.displayId, self.itemName = itemId, ids[1], names[index or 1]
        ns.Query(itemId, function(id, ok)
            if not ok or self.itemId ~= id then return end
            local _, _, quality, _, _, _, _, _, _, tex = GetItemInfo(id)
            if tex then self:SetItemVisual(tex) end
            Win.model:TryOn(id)
        end)
        return true
    end

    -- Quitar solo este hueco: se desviste y se rehace el resto
    function b:Clear()
        if not self.itemId then return end
        self:Wipe()
        Win.model:Undress()
        for _, s in pairs(slots) do
            if s.itemId then Win.model:TryOn(s.itemId) end
        end
    end

    function b:FromEquipped()
        local slotId = GetInventorySlotInfo(info.inv)
        local id = slotId and GetInventoryItemID("player", slotId)
        if id then
            local name, link, quality, _, _, _, _, _, _, tex = GetItemInfo(id)
            if name and (quality >= 2 or slotName == "Shirt" or slotName == "Tabard") then
                self.itemId, self.displayId, self.itemName = id, id, name
                self:SetItemVisual(tex)
                return
            end
        end
        self:Wipe()
    end

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.slotName, 1, 1, 1)
        if self.itemName then
            GameTooltip:AddLine(self.itemName, C.accent[1], C.accent[2], C.accent[3])
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(ns.L.SHIFT_LINK)
            GameTooltip:AddLine(ns.L.CTRL_URL)
            GameTooltip:AddLine(ns.L.SLOT_CLEAR)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnClick", function(self, button)
        if button == "RightButton" then self:Clear() return end
        if IsShiftKeyDown() and self.itemId then
            local _, link = GetItemInfo(self.itemId)
            if link and not ChatEdit_InsertLink(link) then DEFAULT_CHAT_FRAME:AddMessage(link) end
        elseif IsAltKeyDown() and self.itemId then
            ns.ShowURL(self.itemId)
        else
            ns:Fire("SLOT_SELECTED", self.slotName)
            ns:Fire("CAMERA_FOCUS", self.slotName)
        end
    end)
    return b
end

-- Marca visualmente el hueco activo
ns:On("SLOT_SELECTED", function(slot)
    for name, s in pairs(slots) do s:SetSelected(name == slot) end
end)

-- --------------------------------------------------------------
-- Construccion
-- --------------------------------------------------------------
local function build()
    local S = ns.db.settings

    frame = CreateFrame("Frame", "TransmogVaultFrame", UIParent)
    Win.frame = frame
    frame:SetSize(W, H)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetScale(S.scale or 1)
    UI.Flat(frame, C.bg, C.border)
    frame:Hide()
    table.insert(UISpecialFrames, "TransmogVaultFrame")

    if S.pos then
        frame:SetPoint(S.pos[1], UIParent, S.pos[2], S.pos[3], S.pos[4])
    else
        frame:SetPoint("CENTER")
    end

    -- Cabecera arrastrable
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 0, 0); header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(46)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local p, _, rp, x, y = frame:GetPoint()
        S.pos = { p, rp, x, y }
    end)
    local hbg = header:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints(); hbg:SetTexture("Interface\\Buttons\\WHITE8X8")
    hbg:SetVertexColor(C.panel[1], C.panel[2], C.panel[3], 1)
    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetHeight(2); line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.9)

    -- Emblema redondo con aro dorado junto al titulo
    local emblem = CreateFrame("Frame", nil, header)
    emblem:SetSize(36, 36)
    emblem:SetPoint("LEFT", 12, 0)
    local ebg = emblem:CreateTexture(nil, "BACKGROUND")
    ebg:SetSize(23, 23); ebg:SetPoint("TOPLEFT", 8, -6)
    ebg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    local eicon = emblem:CreateTexture(nil, "ARTWORK")
    eicon:SetSize(23, 23); eicon:SetPoint("TOPLEFT", 8, -6)
    eicon:SetTexture("Interface\\Icons\\INV_Chest_Cloth_17")
    eicon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local ering = emblem:CreateTexture(nil, "OVERLAY")
    ering:SetSize(62, 62); ering:SetPoint("TOPLEFT")
    ering:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local title = UI.Text(header, 16, C.text, "LEFT")
    title:SetPoint("LEFT", emblem, "RIGHT", 10, 1)
    ns.Bind(title, "TITLE")

    local close = UI.Button(header, "x", 28, 28, function() frame:Hide() end)
    close:SetPoint("RIGHT", -10, 1)

    -- Pestanas
    table.sort(tabDefs, function(a, b) return (a.order or 99) < (b.order or 99) end)
    local prev
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", LEFT_W + 20, -56)
    content:SetPoint("BOTTOMRIGHT", -10, 10)
    Win.content = content

    for _, def in ipairs(tabDefs) do
        local btn = UI.Button(header, "", 116, 28, function() selectTab(def.key) end)
        ns.Bind(btn, def.label, "SetLabel")
        if prev then btn:SetPoint("LEFT", prev, "RIGHT", 6, 0)
        else btn:SetPoint("LEFT", title, "RIGHT", 40, -1) end
        prev = btn
        local page = CreateFrame("Frame", nil, content)
        page:SetAllPoints()
        page:Hide()
        Win.tabs[def.key] = { def = def, button = btn, page = page }
    end

    -- Panel izquierdo: modelo + huecos
    local left = CreateFrame("Frame", nil, frame)
    left:SetPoint("TOPLEFT", 10, -56)
    left:SetSize(LEFT_W, H - 66)
    Win.left = left

    local model = UI.CreateModelView(left)
    model:SetPoint("TOPLEFT", 50, 0)
    model:SetSize(LEFT_W - 100, 470)
    Win.model = model

    local tip = UI.Text(left, 10, C.dim, "CENTER")
    tip:SetPoint("TOP", model, "BOTTOM", 0, -6)
    tip:SetWidth(LEFT_W - 100)
    ns.Bind(tip, "ROOM_TIP")

    for _, name in ipairs(Data.SLOT_ORDER) do slots[name] = makeSlot(left, name) end
    for i, name in ipairs(Data.LEFT_SLOTS) do
        slots[name]:SetPoint("TOPLEFT", left, "TOPLEFT", 0, -(i - 1) * 48)
    end
    for i, name in ipairs(Data.RIGHT_SLOTS) do
        slots[name]:SetPoint("TOPRIGHT", left, "TOPRIGHT", 0, -(i - 1) * 48)
    end
    local bottom = Data.BOTTOM_SLOTS
    for i, name in ipairs(bottom) do
        slots[name]:SetPoint("TOP", left, "TOP", (i - 2) * 56, -490)
    end

    local bw = (LEFT_W - 2 * 8) / 3
    local bReset = UI.Button(left, "", bw, 28, function()
        model:Reset()
        model:ResetCamera()          -- vuelve a cuerpo completo
        for _, s in pairs(slots) do s:FromEquipped() end
    end)
    bReset:SetPoint("BOTTOMLEFT", 0, 0)
    ns.Bind(bReset, "RESET", "SetLabel")

    local bUndress = UI.Button(left, "", bw, 28, function()
        model:Undress()
        for _, s in pairs(slots) do s:Wipe() end
    end)
    bUndress:SetPoint("LEFT", bReset, "RIGHT", 8, 0)
    ns.Bind(bUndress, "UNDRESS", "SetLabel")

    local bTarget = UI.Button(left, "", bw, 28, function()
        if model:SetTarget() then for _, s in pairs(slots) do s:Wipe() end end
    end)
    bTarget:SetPoint("LEFT", bUndress, "RIGHT", 8, 0)
    ns.Bind(bTarget, "USE_TARGET", "SetLabel")
    UI.Tip(bTarget, function() return ns.L.USE_TARGET end, function() return ns.L.USE_TARGET_TIP end)

    -- Construir paginas
    for _, def in ipairs(tabDefs) do
        if def.build then def.build(Win.tabs[def.key].page) end
    end

    frame:SetScript("OnShow", function()
        PlaySound("igCharacterInfoOpen")
        for _, s in pairs(slots) do if not s.itemId then s:FromEquipped() end end
        local t = Win.tabs[Win.currentTab]
        if t and t.def.onShow then t.def.onShow(t.page) end
    end)
    frame:SetScript("OnHide", function() PlaySound("igCharacterInfoClose") end)

    for _, s in pairs(slots) do s:FromEquipped() end
    selectTab(S.lastTab and Win.tabs[S.lastTab] and S.lastTab or tabDefs[1].key)
end

function Win.Toggle()
    if not frame then return end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function Win.ApplyScale()
    if frame then frame:SetScale(ns.db.settings.scale or 1) end
end

function Win.ResetPosition()
    if not frame then return end
    ns.db.settings.pos = nil
    frame:ClearAllPoints()
    frame:SetPoint("CENTER")
end

-- Prueba un objeto del juego: abre la ventana, lo viste en su hueco y salta a su subclase.
function Win.TryOnItem(itemId)
    if not frame then return false end
    local equipLoc = select(9, GetItemInfo(itemId))
    local cands = equipLoc and Data.SLOTS_FOR_EQUIPLOC[equipLoc]
    ns.Debug("Ctrl+click item", itemId, "equipLoc =", equipLoc, "slots =", cands and table.concat(cands, "/") or "none")
    if not cands then return false end

    -- 1) hueco donde el catalogo conoce el objeto; 2) si no, el primer hueco posible
    local slot, sub, known = cands[1], nil, false
    for _, s in ipairs(cands) do
        local ids, _, _, sc = Data.GetGroup(itemId, s)
        if ids then slot, sub, known = s, sc, true break end
    end
    ns.Debug("  -> hueco", slot, known and ("subclase " .. tostring(sub)) or "(fuera del catalogo)")

    local st = ns.CollectionState
    if st then
        st.slot = slot
        if sub then st.sub[slot] = sub end
    end
    selectTab("collection")
    frame:Show()
    slots[slot]:Apply(itemId, true)
    ns:Fire("CAMERA_FOCUS", slot)
    return true
end

ns:On("LOGIN", build)
ns:On("TOGGLE_WINDOW", Win.Toggle)

-- Ctrl+clic (bolsas, banco, vendedor, subasta, enlaces del chat).
-- Se engancha por dos vias para que funcione aunque el cliente use una distinta:
--   1) DressUpItemLink (la normal)   2) DressUpModel:TryOn (red de seguridad)
ns:On("LOGIN", function()
    local function handle(link)
        if not (ns.db.settings.ctrlClick and type(link) == "string") then return false end
        local id = tonumber(link:match("item:(%d+)"))
        if not id then return false end
        if not GetItemInfo(id) then
            -- aun no esta en cache (p. ej. enlace del chat): se consulta y se prueba al llegar
            ns.Query(id, function(_, ok) if ok then pcall(Win.TryOnItem, id) end end)
            return true
        end
        local ok, handled = pcall(Win.TryOnItem, id)
        if not ok then
            ns.Print("Ctrl+clic: error interno: " .. tostring(handled))   -- visible, no silencioso
            return false
        end
        return handled and true or false
    end

    if type(DressUpItemLink) == "function" then
        local original = DressUpItemLink
        DressUpItemLink = function(link, ...)
            ns.Debug("DressUpItemLink", tostring(link))
            if handle(link) then return end
            return original(link, ...)
        end
    end

    if DressUpModel and type(DressUpModel.TryOn) == "function" then
        hooksecurefunc(DressUpModel, "TryOn", function(_, link)
            ns.Debug("DressUpModel:TryOn", tostring(link))
            if type(link) == "number" then link = "item:" .. link end
            if handle(link) and DressUpFrame and DressUpFrame:IsShown() then HideUIPanel(DressUpFrame) end
        end)
    end
end)
