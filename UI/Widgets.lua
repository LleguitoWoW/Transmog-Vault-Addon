local addon, ns = ...

-- Kit de widgets planos y oscuros (sin plantillas Blizzard para el estilo).
local UI = {}
ns.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function setShown(o, v) if v then o:Show() else o:Hide() end end
UI.SetShown = setShown

UI.color = {
    bg      = { 0.055, 0.06, 0.075, 0.98 },
    panel   = { 0.09, 0.10, 0.125, 1 },
    panel2  = { 0.12, 0.135, 0.165, 1 },
    border  = { 0.20, 0.22, 0.27, 1 },
    text    = { 0.90, 0.92, 0.96 },
    dim     = { 0.55, 0.58, 0.65 },
    accent  = { 0.35, 0.62, 1.0 },
    good    = { 0.35, 0.80, 0.50 },
    warn    = { 1.0, 0.78, 0.30 },
}
local C = UI.color

local FLAT = { bgFile = WHITE, edgeFile = WHITE, tile = false, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 } }

function UI.Flat(f, bg, border)
    f:SetBackdrop(FLAT)
    bg = bg or C.panel
    border = border or C.border
    f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    f:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

function UI.Text(parent, size, color, justify, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size or 12)
    color = color or C.text
    fs:SetTextColor(color[1], color[2], color[3])
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

function UI.Panel(parent, bg, border)
    local f = CreateFrame("Frame", nil, parent)
    UI.Flat(f, bg, border)
    return f
end

-- --------------------------------------------------------------
-- Boton
-- --------------------------------------------------------------
function UI.Button(parent, text, w, h, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w or 90, h or 24)
    UI.Flat(b, C.panel2, C.border)
    b.label = UI.Text(b, 12, C.text, "CENTER")
    b.label:SetPoint("CENTER", 0, 0)
    b.label:SetText(text or "")
    b.active = false

    local function paint(hover)
        if not b:IsEnabled() then
            b:SetBackdropColor(C.panel[1], C.panel[2], C.panel[3], 1)
            b.label:SetTextColor(0.4, 0.42, 0.48)
            return
        end
        if b.active then
            b:SetBackdropColor(C.accent[1] * 0.35, C.accent[2] * 0.35, C.accent[3] * 0.35, 1)
            b:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
            b.label:SetTextColor(1, 1, 1)
        else
            local k = hover and 1.35 or 1
            b:SetBackdropColor(C.panel2[1] * k, C.panel2[2] * k, C.panel2[3] * k, 1)
            b:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            b.label:SetTextColor(C.text[1], C.text[2], C.text[3])
        end
    end
    b._paint = paint
    b:SetScript("OnEnter", function() paint(true) end)
    b:SetScript("OnLeave", function() paint(false) end)
    b:SetScript("OnClick", function(self, ...)
        PlaySound("igMainMenuOptionCheckBoxOn")
        if onClick then onClick(self, ...) end
    end)
    hooksecurefunc(b, "Enable", function() paint(false) end)
    hooksecurefunc(b, "Disable", function() paint(false) end)
    function b:SetActive(v) self.active = v and true or false; paint(false) end
    function b:SetLabel(t) self.label:SetText(t) end
    paint(false)
    return b
end

-- --------------------------------------------------------------
-- Checkbox con texto
-- --------------------------------------------------------------
function UI.Checkbox(parent, text, getter, setter)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(300, 22)
    local box = CreateFrame("Frame", nil, b)
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    UI.Flat(box, C.panel2, C.border)
    local tick = box:CreateTexture(nil, "OVERLAY")
    tick:SetTexture(WHITE)
    tick:SetPoint("TOPLEFT", 4, -4)
    tick:SetPoint("BOTTOMRIGHT", -4, 4)
    tick:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
    b.text = UI.Text(b, 12, C.text, "LEFT")
    b.text:SetPoint("LEFT", box, "RIGHT", 8, 0)
    b.text:SetText(text)
    function b:Refresh() setShown(tick, getter()) end
    b:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        setter(not getter())
        b:Refresh()
    end)
    b:SetScript("OnShow", b.Refresh)
    function b:SetLabel(t) self.text:SetText(t) end
    return b
end

-- --------------------------------------------------------------
-- Barra de progreso
-- --------------------------------------------------------------
function UI.Bar(parent, w, h)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(w or 160, h or 14)
    UI.Flat(f, C.panel, C.border)
    local fill = f:CreateTexture(nil, "ARTWORK")
    fill:SetTexture(WHITE)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", 1, 1)
    fill:SetWidth(1)
    fill:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.9)
    f.text = UI.Text(f, 11, C.text, "CENTER")
    f.text:SetPoint("CENTER", 0, 0)
    function f:SetProgress(have, total, text)
        local p = (total and total > 0) and (have / total) or 0
        local inner = f:GetWidth() - 2
        fill:SetWidth(math.max(1, inner * p))
        if p >= 1 then fill:SetVertexColor(C.good[1], C.good[2], C.good[3], 0.9)
        else fill:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.9) end
        f.text:SetText(text or (have .. " / " .. total))
    end
    return f
end

-- --------------------------------------------------------------
-- Caja de busqueda con texto de ayuda
-- --------------------------------------------------------------
function UI.Search(parent, w, onChange)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetSize(w or 160, 24)
    e:SetAutoFocus(false)
    e:SetFont("Fonts\\FRIZQT__.TTF", 12)
    e:SetTextColor(C.text[1], C.text[2], C.text[3])
    e:SetTextInsets(8, 8, 0, 0)
    e:SetMaxLetters(40)
    UI.Flat(e, C.panel, C.border)
    e.hint = UI.Text(e, 12, C.dim, "LEFT")
    e.hint:SetPoint("LEFT", 8, 0)
    local function upd() setShown(e.hint, e:GetText() == "" and not e:HasFocus()) end
    e:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1); upd()
    end)
    e:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1); upd()
    end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    -- Pequeno retardo para no refiltrar en cada tecla
    local wait = CreateFrame("Frame")
    wait:Hide()
    wait.t = 0
    wait:SetScript("OnUpdate", function(self, el)
        self.t = self.t + el
        if self.t >= 0.25 then self:Hide(); if onChange then onChange(e:GetText()) end end
    end)
    e:SetScript("OnTextChanged", function(self, user)
        upd()
        if user then wait.t = 0; wait:Show() end
    end)
    function e:SetHint(t) self.hint:SetText(t) end
    upd()
    return e
end

-- --------------------------------------------------------------
-- Desplegable propio (sin UIDropDownMenu)
--   getItems() -> { {text=, value=}, ... }
-- --------------------------------------------------------------
local menu, catcher
local function ensureMenu()
    if menu then return end
    catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:Hide()
    catcher:SetScript("OnClick", function() catcher:Hide(); menu:Hide() end)
    menu = CreateFrame("Frame", nil, UIParent)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetFrameLevel(catcher:GetFrameLevel() + 2)
    UI.Flat(menu, C.panel, C.accent)
    menu:Hide()
    menu.rows = {}
    menu:SetScript("OnHide", function() catcher:Hide() end)
end

function UI.Dropdown(parent, w, getItems, onSelect)
    ensureMenu()
    local b = UI.Button(parent, "", w or 130, 24)
    b.arrow = UI.Text(b, 10, C.dim, "RIGHT")
    b.arrow:SetPoint("RIGHT", -6, 0)
    b.arrow:SetText("v")
    b.label:ClearAllPoints()
    b.label:SetPoint("LEFT", 8, 0)
    b.label:SetPoint("RIGHT", -18, 0)
    b.label:SetJustifyH("LEFT")

    b:SetScript("OnClick", function(self)
        if menu:IsShown() and menu.owner == self then menu:Hide() return end
        PlaySound("igMainMenuOptionCheckBoxOn")
        local items = getItems()
        for _, r in ipairs(menu.rows) do r:Hide() end
        local rowH = 22
        for i, it in ipairs(items) do
            local r = menu.rows[i]
            if not r then
                r = UI.Button(menu, "", 10, rowH)
                r:SetBackdrop(nil)
                r.label:ClearAllPoints()
                r.label:SetPoint("LEFT", 8, 0)
                menu.rows[i] = r
            end
            r:SetParent(menu)
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", 1, -1 - (i - 1) * rowH)
            r:SetPoint("TOPRIGHT", -1, -1 - (i - 1) * rowH)
            r:SetLabel(it.text)
            r.label:SetTextColor(it.active and C.accent[1] or C.text[1], it.active and C.accent[2] or C.text[2], it.active and C.accent[3] or C.text[3])
            r:SetScript("OnEnter", function(s) s.label:SetTextColor(1, 1, 1) end)
            r:SetScript("OnLeave", function(s)
                if it.active then s.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
                else s.label:SetTextColor(C.text[1], C.text[2], C.text[3]) end
            end)
            r:SetScript("OnClick", function()
                menu:Hide()
                if onSelect then onSelect(it.value, it.text) end
            end)
            r:Show()
        end
        menu.owner = self
        menu:SetWidth(math.max(self:GetWidth(), 120))
        menu:SetHeight(#items * rowH + 2)
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        catcher:Show()
        menu:Show()
    end)
    return b
end

-- --------------------------------------------------------------
-- Deslizador con etiqueta
-- --------------------------------------------------------------
function UI.Slider(parent, w, minV, maxV, step, onChange)
    local s = CreateFrame("Slider", nil, parent)
    s:SetSize(w or 180, 14)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    UI.Flat(s, C.panel, C.border)
    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE)
    thumb:SetSize(10, 14)
    thumb:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
    s:SetThumbTexture(thumb)
    s.value = UI.Text(s, 11, C.dim, "RIGHT")
    s.value:SetPoint("LEFT", s, "RIGHT", 8, 0)
    s:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        self.value:SetText(string.format("%.2f", v))
        if self._ready and onChange then onChange(v) end
    end)
    return s
end

-- --------------------------------------------------------------
-- Tooltip de ayuda
-- --------------------------------------------------------------
function UI.Tip(frame, title, body, anchor)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, anchor or "ANCHOR_TOP")
        GameTooltip:AddLine(type(title) == "function" and title() or title, 1, 1, 1)
        local b = type(body) == "function" and body() or body
        if b then GameTooltip:AddLine(b, 0.75, 0.78, 0.85, true) end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end
