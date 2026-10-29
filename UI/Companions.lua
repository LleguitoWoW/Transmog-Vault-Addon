local addon, ns = ...
local UI = ns.UI
local C = UI.color
local Data = ns.Data

-- Pestanas "Monturas" y "Mascotas": catalogo + estado aprendido, vista 3D,
-- filtro y busqueda. Doble clic invoca/retira.

local ROW_H = 42
local VISIBLE = 12
local VIEW_W = 470

local function buildCompanionTab(page, ctype, emptyKey)
    local S = ns.db.settings
    local filter, search = "all", ""
    local data = {}          -- lista filtrada
    local learnedCount, total = 0, 0
    local offset = 0
    local selected

    -- ---- visor 3D ----
    local view = UI.Panel(page, C.bg, C.border)
    view:SetPoint("TOPLEFT", 0, 0)
    view:SetPoint("BOTTOMLEFT", 0, 0)
    view:SetWidth(VIEW_W)
    local model = CreateFrame("PlayerModel", nil, view)
    model:SetPoint("TOPLEFT", 1, -1); model:SetPoint("BOTTOMRIGHT", -1, 1)
    model:SetFacing(0.4)
    local mname = UI.Text(view, 13, C.accent, "CENTER")
    mname:SetPoint("BOTTOM", 0, 36)
    mname:SetWidth(VIEW_W - 20)
    local hint = UI.Text(view, 10, C.dim, "CENTER")
    hint:SetPoint("BOTTOM", 0, 12)
    hint:SetWidth(VIEW_W - 16)
    ns.Bind(hint, "PREVIEW_HINT")

    local drag
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function() drag = GetCursorPosition() end)
    model:SetScript("OnMouseUp", function() drag = nil end)
    model:SetScript("OnUpdate", function(self)
        if drag then
            local x = GetCursorPosition()
            self:SetFacing(self:GetFacing() + (x - drag) * 0.012)
            drag = x
        end
    end)

    local zoom = 1
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseWheel", function(self, d)
        zoom = math.max(0.4, math.min(2.5, zoom + d * 0.1))
        self:SetModelScale(zoom)
    end)

    local function showModel(item)
        selected = item
        zoom = 1
        model:SetModelScale(1)
        if item and item.creatureId then
            model:SetCreature(item.creatureId)
            mname:SetText(item.name or "")
        else
            model:ClearModel()
            mname:SetText(item and item.name or "")
            if item and not item.learned then mname:SetText((item.name or "") .. "\n|cff8c93a6" .. ns.L.NOT_LEARNED .. "|r") end
        end
    end

    -- ---- cabecera ----
    local x0 = VIEW_W + 14
    local bar = UI.Bar(page, 240, 18)
    bar:SetPoint("TOPRIGHT", 0, -2)

    local prev
    local filterBtns = {}
    for _, f in ipairs({ { "all", "FILTER_ALL" }, { "unlocked", "FILTER_UNLOCKED" }, { "locked", "FILTER_LOCKED" } }) do
        local b
        b = UI.Button(page, "", 96, 24, function()
            filter = f[1]
            for _, o in pairs(filterBtns) do o:SetActive(o.mode == filter) end
            page.refresh()
        end)
        b.mode = f[1]
        ns.Bind(b, f[2], "SetLabel")
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 6, 0) else b:SetPoint("TOPLEFT", x0, 0) end
        prev = b
        filterBtns[f[1]] = b
        b:SetActive(f[1] == filter)
    end

    local searchBox = UI.Search(page, 300, function(t) search = t or ""; page.refresh() end)
    searchBox:SetPoint("TOPLEFT", x0, -34)
    ns.Bind(searchBox, "SEARCH", "SetHint")

    -- ---- lista con scroll por filas ----
    local list = CreateFrame("Frame", nil, page)
    list:SetPoint("TOPLEFT", x0, -70)
    list:SetPoint("BOTTOMRIGHT", -20, 0)
    list:EnableMouseWheel(true)

    local emptyText = UI.Text(list, 13, C.dim, "CENTER")
    emptyText:SetPoint("CENTER", 0, 0)
    ns.Bind(emptyText, emptyKey)

    local scrollbar = CreateFrame("Slider", nil, page)
    scrollbar:SetPoint("TOPRIGHT", 0, -70)
    scrollbar:SetPoint("BOTTOMRIGHT", 0, 0)
    scrollbar:SetWidth(10)
    scrollbar:SetOrientation("VERTICAL")
    UI.Flat(scrollbar, C.panel, C.border)
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetSize(8, 40)
    thumb:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
    scrollbar:SetThumbTexture(thumb)
    scrollbar:SetMinMaxValues(0, 0)
    scrollbar:SetValueStep(1)

    local rows = {}
    local function paint()
        for i = 1, VISIBLE do
            local r, item = rows[i], data[offset + i]
            if item then
                r.item = item
                local icon = item.icon
                if not icon and item.itemId then
                    icon = select(10, GetItemInfo(item.itemId))
                    if not icon and not item._queried then
                        item._queried = true
                        ns.Query(item.itemId, function() if list:IsVisible() then paint() end end)
                    end
                end
                r.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                r.icon:SetDesaturated(not item.learned)
                r.name:SetText(item.name)
                r:SetAlpha(item.learned and 1 or 0.5)
                if item.summoned then
                    r.state:SetText(ns.L.ACTIVE); r.state:SetTextColor(C.good[1], C.good[2], C.good[3])
                elseif not item.learned then
                    r.state:SetText(ns.L.NOT_LEARNED); r.state:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
                else
                    r.state:SetText("")
                end
                r:Show()
            else
                r.item = nil
                r:Hide()
            end
        end
    end

    scrollbar:SetScript("OnValueChanged", function(self, v)
        offset = math.floor(v + 0.5)
        paint()
    end)
    list:SetScript("OnMouseWheel", function(_, d)
        scrollbar:SetValue(scrollbar:GetValue() - d * 2)
    end)

    for i = 1, VISIBLE do
        local r = CreateFrame("Button", nil, list)
        r:SetHeight(ROW_H - 4)
        r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        r:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
        UI.Flat(r, C.panel, C.border)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(32, 32)
        r.icon:SetPoint("LEFT", 6, 0)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        r.name = UI.Text(r, 13, C.text, "LEFT")
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 10, 0)
        r.state = UI.Text(r, 11, C.dim, "RIGHT")
        r.state:SetPoint("RIGHT", -12, 0)
        r.name:SetPoint("RIGHT", r.state, "LEFT", -10, 0)
        r:RegisterForClicks("LeftButtonUp")
        r.last = 0
        r:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
        r:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1) end)
        r:SetScript("OnClick", function(self)
            local item = self.item
            if not item then return end
            showModel(item)
            local now = GetTime()
            if item.learned and item.index and now - self.last < 0.4 then
                if item.summoned then DismissCompanion(ctype) else CallCompanion(ctype, item.index) end
            end
            self.last = now
        end)
        rows[i] = r
    end

    function page.refresh()
        local all, learned = Data.GetCompanions(ctype)
        learnedCount, total = learned, #all
        data = {}
        local q = search:lower()
        for _, it in ipairs(all) do
            local ok = (filter == "all") or ((filter == "unlocked") == it.learned)
            if ok and q ~= "" then ok = (it.name or ""):lower():find(q, 1, true) ~= nil end
            if ok then data[#data + 1] = it end
        end
        bar:SetProgress(learnedCount, total, ns.L.PROGRESS:format(learnedCount, total))
        scrollbar:SetMinMaxValues(0, math.max(0, #data - VISIBLE))
        scrollbar:SetValue(0)
        offset = 0
        if #data == 0 then emptyText:Show() else emptyText:Hide() end
        paint()
        if not selected and data[1] then showModel(data[1]) end
    end

    page:RegisterEvent("COMPANION_UPDATE")
    page:SetScript("OnEvent", function(self)
        if self:IsVisible() then
            -- solo repinta estado (invocada / no) sin perder la posicion
            local keep = scrollbar:GetValue()
            self.refresh()
            scrollbar:SetValue(keep)
        end
    end)
end

ns.RegisterTab({
    key = "mounts", label = "TAB_MOUNTS", order = 3, model = false,
    build = function(page) buildCompanionTab(page, "MOUNT", "MOUNTS_EMPTY") end,
    onShow = function(page) page.refresh() end,
})

ns.RegisterTab({
    key = "pets", label = "TAB_PETS", order = 4, model = false,
    build = function(page) buildCompanionTab(page, "CRITTER", "PETS_EMPTY") end,
    onShow = function(page) page.refresh() end,
})
