local addon, ns = ...
local UI = ns.UI
local C = UI.color

ns.RegisterTab({
    key = "settings", label = "TAB_SETTINGS", order = 5, model = false,

    build = function(root)
        local page = CreateFrame("Frame", nil, root)
        page:SetSize(740, 420)
        page:SetPoint("TOP", 0, -30)
        local S = ns.db.settings

        local function section(title, x)
            local fs = UI.Text(page, 13, C.accent, "LEFT")
            fs:SetPoint("TOPLEFT", x, -4)
            ns.Bind(fs, title)
            local ln = page:CreateTexture(nil, "ARTWORK")
            ln:SetTexture("Interface\\Buttons\\WHITE8X8")
            ln:SetVertexColor(C.border[1], C.border[2], C.border[3], 1)
            ln:SetHeight(1)
            ln:SetPoint("TOPLEFT", x, -24)
            ln:SetWidth(330)
        end
        local function label(key, x, y)
            local fs = UI.Text(page, 12, C.text, "LEFT")
            fs:SetPoint("TOPLEFT", x, y)
            ns.Bind(fs, key)
            return fs
        end

        -- ============ Columna 1: apariencia ============
        section("SET_APPEARANCE", 0)

        label("SET_LANGUAGE", 0, -40)
        local langs = { { "auto", function() return ns.L.SET_AUTO end }, { "en", function() return "English" end }, { "es", function() return "Español" end } }
        local langDrop
        local function langName()
            local cur = S.locale or "auto"
            for _, l in ipairs(langs) do if l[1] == cur then return l[2]() end end
        end
        langDrop = UI.Dropdown(page, 170, function()
            local items = {}
            for _, l in ipairs(langs) do
                items[#items + 1] = { text = l[2](), value = l[1], active = (l[1] == (S.locale or "auto")) }
            end
            return items
        end, function(value)
            S.locale = (value ~= "auto") and value or nil
            ns.SetLocale(S.locale)
        end)
        langDrop:SetPoint("TOPLEFT", 160, -36)
        ns:On("LOCALE_CHANGED", function() langDrop:SetLabel(langName()) end)
        langDrop:SetLabel(langName())

        label("SET_SETUP", 0, -80)
        local setupDrop = UI.Dropdown(page, 170, function()
            return {
                { text = "classic", value = "classic", active = S.previewSetup == "classic" },
                { text = "modern", value = "modern", active = S.previewSetup == "modern" },
            }
        end, function(value)
            S.previewSetup = value
            setupDrop:SetLabel(value)
            if ns.CollectionState then ns.CollectionState.Refresh(true) end
        end)
        setupDrop:SetPoint("TOPLEFT", 160, -76)
        setupDrop:SetLabel(S.previewSetup)
        UI.Tip(setupDrop, function() return ns.L.SET_SETUP end, function() return ns.L.SET_SETUP_TIP end, "ANCHOR_RIGHT")

        label("SET_BG", 0, -120)
        local swatch = CreateFrame("Button", nil, page)
        swatch:SetSize(60, 24)
        swatch:SetPoint("TOPLEFT", 160, -116)
        UI.Flat(swatch, S.bgColor, C.border)
        local function setBg(r, g, b)
            S.bgColor = { r, g, b, 1 }
            swatch:SetBackdropColor(r, g, b, 1)
            if ns.Window.model then ns.Window.model:SetBackground(S.bgColor) end
        end
        swatch:SetScript("OnClick", function()
            local c = S.bgColor
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.previousValues = { r = c[1], g = c[2], b = c[3] }
            ColorPickerFrame.func = function() setBg(ColorPickerFrame:GetColorRGB()) end
            ColorPickerFrame.cancelFunc = function(p) setBg(p.r, p.g, p.b) end
            ColorPickerFrame:SetColorRGB(c[1], c[2], c[3])
            ColorPickerFrame:Hide(); ColorPickerFrame:Show()
        end)
        local resetBg = UI.Button(page, "R", 24, 24, function()
            local d = ns.defaults.bgColor
            setBg(d[1], d[2], d[3])
        end)
        resetBg:SetPoint("LEFT", swatch, "RIGHT", 6, 0)

        label("SET_SCALE", 0, -160)
        -- La escala se aplica al SOLTAR el raton: el deslizador esta dentro de la ventana y
        -- reescalarla mientras se arrastra lo movia bajo el cursor (saltaba a min/max).
        local scale = UI.Slider(page, 150, 0.7, 1.3, 0.05, function(v) S.scale = v end)
        scale:HookScript("OnMouseUp", function() ns.Window.ApplyScale() end)
        scale:SetPoint("TOPLEFT", 160, -162)
        scale:SetValue(S.scale or 1)
        scale._ready = true

        local resetPos = UI.Button(page, "", 200, 26, function() ns.Window.ResetPosition() end)
        resetPos:SetPoint("TOPLEFT", 0, -200)
        ns.Bind(resetPos, "SET_RESET_POS", "SetLabel")

        label("SET_ZOOMFACTOR", 0, -250)
        local zf = UI.Slider(page, 150, 0.5, 1.2, 0.05, function(v) S.zoomFactor = v end)
        zf:SetPoint("TOPLEFT", 160, -252)
        zf:SetValue(S.zoomFactor or 0.85)
        zf._ready = true

        -- ============ Columna 2: comportamiento ============
        local x2 = 370
        section("SET_BEHAVIOUR", x2)

        local function check(key, field, y, after)
            local cb = UI.Checkbox(page, ns.L[key], function() return S[field] end, function(v)
                S[field] = v
                if after then after(v) end
            end)
            cb:SetPoint("TOPLEFT", x2, y)
            ns:On("LOCALE_CHANGED", function() cb:SetLabel(ns.L[key]) end)
            return cb
        end
        check("SET_MINIMAP", "showMinimap", -40, function() ns:Fire("MINIMAP_VISIBILITY") end)
        check("SET_NOTIFY", "notifyUnlock", -68)
        check("SET_TOOLTIP", "tooltipTag", -96)
        check("SET_AUTOSYNC", "autoSync", -124)
        check("SET_CTRLCLICK", "ctrlClick", -152)
        check("SET_DEBUG", "debug", -180)
        check("SET_AUTOZOOM", "autoZoom", -208)

        local syncBtn = UI.Button(page, "", 200, 26, function() ns.Unlocks.RequestSync() end)
        syncBtn:SetPoint("TOPLEFT", x2, -248)
        ns.Bind(syncBtn, "SET_SYNC_NOW", "SetLabel")

        -- ============ Pie ============
        local credits = UI.Text(page, 11, C.dim, "LEFT")
        credits:SetPoint("BOTTOMLEFT", 0, 6)
        credits:SetText("Transmog Vault v" .. ns.VERSION ..
            "  |  Based on DressMe (GetLocalPlayer) and TransmogTip (ZhengPeiRu21)  |  Lleguito")
    end,
})
