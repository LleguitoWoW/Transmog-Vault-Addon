local addon, ns = ...
local UI = ns.UI
local C = UI.color
local Data = ns.Data

-- Pestana "Conjuntos": guardar el atuendo actual y volver a probarlo.
-- Formato (compatible con el addon antiguo):
--   db.looks = { { name = "...", items = { 14 ids en orden de Data.SLOT_ORDER, 0 = vacio } } }

local ROW_H = 40

local function currentItems()
    local items = {}
    for i, slot in ipairs(Data.SLOT_ORDER) do
        items[i] = ns.Window.slots[slot].itemId or 0
    end
    return items
end

local function applyLook(look)
    local Win = ns.Window
    Win.model:Undress()
    for i, slot in ipairs(Data.SLOT_ORDER) do
        local id = look.items[i]
        if id and id ~= 0 then
            Win.slots[slot]:Apply(id)
        else
            Win.slots[slot]:Wipe()
        end
    end
end

-- Formato de texto:  TV1:<nombre>:<id,id,...>   (14 ids, 0 = hueco vacio)
local function encodeLook(look)
    local name = (look.name or ""):gsub("[:|]", "-")
    return "TV1:" .. name .. ":" .. table.concat(look.items, ",")
end

local function decodeLook(text)
    local name, ids = (text or ""):match("^TV1:([^:]+):([%d,]+)$")
    if not name then return nil end
    local items = {}
    for n in ids:gmatch("%d+") do
        local v = tonumber(n)
        if not v or v > 9999999 then return nil end
        items[#items + 1] = v
    end
    if #items ~= #Data.SLOT_ORDER then return nil end
    return { name = name, items = items }
end

local function uniqueName(name)
    local taken = {}
    for _, l in ipairs(ns.db.looks) do taken[l.name] = true end
    if not taken[name] then return name end
    local i = 2
    while taken[name .. " (" .. i .. ")"] do i = i + 1 end
    return name .. " (" .. i .. ")"
end

ns.RegisterTab({
    key = "looks", label = "TAB_LOOKS", order = 2, model = true,

    build = function(page)
        local rows = {}

        local newBtn = UI.Button(page, "", 170, 28, function()
            ns.PromptName(ns.L.LOOKS_NAME, "", function(name)
                local looks = ns.db.looks
                for _, l in ipairs(looks) do
                    if l.name == name then l.items = currentItems(); ns:Fire("LOOKS_CHANGED") return end
                end
                table.insert(looks, { name = name, items = currentItems() })
                table.sort(looks, function(a, b) return a.name:lower() < b.name:lower() end)
                ns:Fire("LOOKS_CHANGED")
            end)
        end)
        newBtn:SetPoint("TOPLEFT", 0, 0)
        ns.Bind(newBtn, "LOOKS_NEW", "SetLabel")

        local importBtn = UI.Button(page, "", 120, 28, function()
            ns.PromptImport(ns.L.LOOKS_IMPORT_TEXT, function(text)
                local look = decodeLook(text)
                if not look then
                    UIErrorsFrame:AddMessage(ns.L.LOOKS_IMPORT_BAD, 1, 0.3, 0.3)
                    return
                end
                look.name = uniqueName(look.name)
                table.insert(ns.db.looks, look)
                table.sort(ns.db.looks, function(a, b) return a.name:lower() < b.name:lower() end)
                ns:Fire("LOOKS_CHANGED")
                ns.Print(ns.L.LOOKS_IMPORTED:format(look.name))
            end)
        end)
        importBtn:SetPoint("LEFT", newBtn, "RIGHT", 8, 0)
        ns.Bind(importBtn, "LOOKS_IMPORT", "SetLabel")

        local scroll = CreateFrame("ScrollFrame", nil, page)
        scroll:SetPoint("TOPLEFT", 0, -40)
        scroll:SetPoint("BOTTOMRIGHT", 0, 0)
        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(700, 10)
        scroll:SetScrollChild(child)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(self, d)
            local max = math.max(0, child:GetHeight() - self:GetHeight())
            local v = math.max(0, math.min(max, self:GetVerticalScroll() - d * ROW_H))
            self:SetVerticalScroll(v)
        end)

        local empty = UI.Text(page, 13, C.dim, "CENTER")
        empty:SetPoint("CENTER", 0, 40)
        empty:SetJustifyV("MIDDLE")
        ns.Bind(empty, "LOOKS_EMPTY")

        local function makeRow(i)
            local r = CreateFrame("Button", nil, child)
            r:SetSize(700, ROW_H - 4)
            r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
            UI.Flat(r, C.panel, C.border)
            r.name = UI.Text(r, 14, C.text, "LEFT")
            r.name:SetPoint("LEFT", 14, 0)
            r.name:SetWidth(280)
            r.del = UI.Button(r, "x", 26, 26)
            r.del:SetPoint("RIGHT", -10, 0)
            r.over = UI.Button(r, "", 96, 26, function()
                ns.db.looks[r.index].items = currentItems()
            end)
            r.over:SetPoint("RIGHT", r.del, "LEFT", -6, 0)
            ns.Bind(r.over, "LOOKS_OVERWRITE", "SetLabel")
            r.exp = UI.Button(r, "", 80, 26, function()
                ns.ShowExport(ns.L.LOOKS_EXPORT_TEXT, encodeLook(ns.db.looks[r.index]))
            end)
            r.exp:SetPoint("RIGHT", r.over, "LEFT", -6, 0)
            ns.Bind(r.exp, "LOOKS_EXPORT", "SetLabel")
            r.apply = UI.Button(r, "", 80, 26, function() applyLook(ns.db.looks[r.index]) end)
            r.apply:SetPoint("RIGHT", r.exp, "LEFT", -6, 0)
            ns.Bind(r.apply, "LOOKS_APPLY", "SetLabel")
            r.del:SetScript("OnClick", function()
                local look = ns.db.looks[r.index]
                ns.Confirm(ns.L.LOOKS_CONFIRM_DELETE:format(look.name), function()
                    table.remove(ns.db.looks, r.index)
                    ns:Fire("LOOKS_CHANGED")
                end)
            end)
            r:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
            r:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1) end)
            r:SetScript("OnClick", function(self) applyLook(ns.db.looks[self.index]) end)
            return r
        end

        local function rebuild()
            local looks = ns.db.looks
            for i = 1, #looks do
                rows[i] = rows[i] or makeRow(i)
                rows[i].index = i
                rows[i].name:SetText(looks[i].name)
                rows[i]:Show()
            end
            for i = #looks + 1, #rows do rows[i]:Hide() end
            child:SetHeight(math.max(10, #looks * ROW_H))
            if #looks == 0 then empty:Show() else empty:Hide() end
        end

        ns:On("LOOKS_CHANGED", rebuild)
        page.rebuild = rebuild
    end,

    onShow = function(page) page.rebuild() end,
})
