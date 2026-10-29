local addon, ns = ...
local UI = ns.UI
local C = UI.color
local Data = ns.Data

-- Pestana "Coleccion": rejilla de apariencias del hueco seleccionado.

local PAGE_W, PAGE_H = 708, 574

ns.RegisterTab({
    key = "collection", label = "TAB_COLLECTION", order = 1, model = true,

    build = function(page)
        local S = ns.db.settings
        local state = { slot = "Chest", sub = {}, pages = {}, search = "" }
        ns.CollectionState = state

        -- ---- fila 1: titulo + progreso ----
        local title = UI.Text(page, 15, C.text, "LEFT")
        title:SetPoint("TOPLEFT", 2, -4)

        local bar = UI.Bar(page, 260, 18)
        bar:SetPoint("TOPRIGHT", 0, -2)

        -- ---- fila 2: subclase, filtros, busqueda ----
        local drop, filterBtns = nil, {}
        local grid = UI.CreateGrid(page)
        grid:SetPoint("TOPLEFT", 0, -70)
        grid:SetSize(PAGE_W, PAGE_H - 70 - 38)

        local empty = UI.Text(page, 13, C.dim, "CENTER")
        empty:SetPoint("CENTER", grid, "CENTER")
        ns.Bind(empty, "NO_RESULTS")
        empty:Hide()

        local function subclassOf(slot)
            if not state.sub[slot] then state.sub[slot] = Data.DefaultSubclass(slot) end
            return state.sub[slot]
        end

        -- Zoom de camara del modelo central hacia el hueco / tipo actual
        local function focus()
            if not S.autoZoom then return end
            ns.Window.model:FocusCamera(Data.GetPreviewSetup(state.slot, subclassOf(state.slot)))
        end
        ns:On("CAMERA_FOCUS", function(slot) if slot == state.slot then focus() end end)

        local function updateHeader()
            local slot = state.slot
            local sub = subclassOf(slot)
            local have, total = Data.GetCounts(slot, sub)
            bar:SetProgress(have, total, ns.L.PROGRESS:format(have, total))
            title:SetText(slot .. (#Data.GetSubclasses(slot) > 1 and ("  |cff8c93a6/  " .. sub .. "|r") or ""))
            drop:SetLabel(sub)
            if #Data.GetSubclasses(slot) <= 1 then drop:Disable() else drop:Enable() end
        end

        local function refresh(keepPage)
            local slot = state.slot
            local sub = subclassOf(slot)
            local list = Data.GetFiltered(slot, sub, S.filter, state.search, S.favOnly)
            local key = slot .. "|" .. sub
            local p = keepPage and (state.pages[key] or 1) or 1
            grid:SetData(list, Data.GetPreviewSetup(slot, sub), p)
            if #list == 0 then empty:Show() else empty:Hide() end
            updateHeader()
        end
        state.Refresh = refresh

        drop = UI.Dropdown(page, 160, function()
            local items = {}
            for _, s in ipairs(Data.GetSubclasses(state.slot)) do
                items[#items + 1] = { text = s, value = s, active = (s == subclassOf(state.slot)) }
            end
            return items
        end, function(value)
            state.sub[state.slot] = value
            refresh(true)
            ns:Fire("SUBCLASS_CHANGED", state.slot, value)
            focus()
        end)
        drop:SetPoint("TOPLEFT", 0, -34)

        local filters = {
            { "all", "FILTER_ALL" }, { "unlocked", "FILTER_UNLOCKED" }, { "locked", "FILTER_LOCKED" },
        }
        local prev
        for _, f in ipairs(filters) do
            local b = UI.Button(page, "", 100, 24, function()
                S.filter = f[1]
                for _, o in pairs(filterBtns) do o:SetActive(o.mode == S.filter) end
                refresh(false)
            end)
            b.mode = f[1]
            ns.Bind(b, f[2], "SetLabel")
            if prev then b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
            else b:SetPoint("LEFT", drop, "RIGHT", 14, 0) end
            prev = b
            filterBtns[f[1]] = b
            b:SetActive(f[1] == S.filter)
        end

        -- Boton estrella: mostrar solo favoritas
        local favBtn = UI.Button(page, "", 30, 24, function(self)
            S.favOnly = not S.favOnly
            self:SetActive(S.favOnly)
            refresh(false)
        end)
        favBtn:SetPoint("LEFT", prev, "RIGHT", 6, 0)
        favBtn:SetActive(S.favOnly)
        local star = favBtn:CreateTexture(nil, "OVERLAY")
        star:SetSize(16, 16)
        star:SetPoint("CENTER")
        star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        UI.Tip(favBtn, function() return ns.L.FAV_ONLY end, nil, "ANCHOR_RIGHT")

        local search = UI.Search(page, 150, function(text)
            state.search = text or ""
            refresh(false)
        end)
        search:SetPoint("TOPRIGHT", 0, -34)
        ns.Bind(search, "SEARCH", "SetHint")

        -- ---- pie: paginador ----
        local prevB = UI.Button(page, "<", 34, 26, function() grid:NextPage(-1) end)
        prevB:SetPoint("BOTTOM", page, "BOTTOM", -90, 4)
        local nextB = UI.Button(page, ">", 34, 26, function() grid:NextPage(1) end)
        nextB:SetPoint("BOTTOM", page, "BOTTOM", 90, 4)
        local pageText = UI.Text(page, 12, C.text, "CENTER")
        pageText:SetPoint("CENTER", page, "BOTTOM", 0, 17)

        local function paintPager(p, count)
            pageText:SetText(ns.L.PAGE:format(p, count))
            if p <= 1 then prevB:Disable() else prevB:Enable() end
            if p >= count then nextB:Disable() else nextB:Enable() end
        end
        grid.onPageChanged = function(p, count)
            state.pages[state.slot .. "|" .. subclassOf(state.slot)] = p
            paintPager(p, count)
        end
        ns:On("LOCALE_CHANGED", function() paintPager(grid:GetPage(), grid:GetPageCount()) end)

        -- ---- interaccion ----
        grid.onClick = function(cell, entry, itemId, button)
            if button == "RightButton" then
                local key = entry[1][1]
                if ns.db.favorites[key] then ns.db.favorites[key] = nil else ns.db.favorites[key] = true end
                PlaySound("igMainMenuOptionCheckBoxOn")
                if S.favOnly then refresh(true) else grid:RefreshStates() end
                if GameTooltip:IsOwned(cell) then GameTooltip:Hide(); cell:GetScript("OnEnter")(cell) end
                return
            end
            if IsShiftKeyDown() then
                local _, link = GetItemInfo(itemId)
                if link and not ChatEdit_InsertLink(link) then DEFAULT_CHAT_FRAME:AddMessage(link) end
            elseif IsAltKeyDown() then
                ns.ShowURL(itemId)
            elseif not cell.unlocked then
                UIErrorsFrame:AddMessage(ns.L.LOCKED_TIP, 1, 0.4, 0.4)
            else
                PlaySound("igMainMenuOptionCheckBoxOn")
                ns.Window.slots[state.slot]:Apply(itemId)
            end
        end

        ns:On("SLOT_SELECTED", function(slot)
            if not Data.SUBCLASSES[slot] then return end
            state.slot = slot
            if page:IsVisible() then refresh(true) end
        end)

        ns:On("UNLOCKS_CHANGED", function()
            if not page:IsVisible() then return end
            if S.filter == "all" and state.search == "" then
                grid:RefreshStates()
                updateHeader()
            else
                refresh(true)
            end
        end)

        ns:On("LOCALE_CHANGED", function() if page:IsVisible() then updateHeader() end end)

        page.refresh = function()
            for name, sl in pairs(ns.Window.slots) do sl:SetSelected(name == state.slot) end
            refresh(true)
        end
    end,

    onShow = function(page)
        page.refresh()
    end,
})
