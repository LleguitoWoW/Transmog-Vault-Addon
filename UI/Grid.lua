local addon, ns = ...
local UI = ns.UI
local C = UI.color

-- Rejilla paginada de previews 3D.
--  * Las celdas se reutilizan.
--  * El vestido de cada modelo se reparte en el tiempo (2 por tick)
--    para que cambiar de pagina no congele el cliente.

local WORK_PER_TICK = 2

local tabDummy = CreateFrame("Button", "TransmogVaultTabDummy")
local hoverCell

local function fillTooltip(cell)
    local e = cell.entry
    if not e then return end
    local names = e[2] or {}
    local L = ns.L
    GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(names[cell.selected] or names[1] or "?", 1, 1, 1)
    if cell.unlocked then
        GameTooltip:AddLine(L.COLLECTED_TIP, C.good[1], C.good[2], C.good[3])
    else
        GameTooltip:AddLine(L.LOCKED_TIP, 1, 0.45, 0.4)
    end
    if #names > 1 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L.PROVIDED_BY, C.dim[1], C.dim[2], C.dim[3])
        for i = 1, #names do
            GameTooltip:AddLine((i == cell.selected and "> " or "- ") .. names[i],
                i == cell.selected and 1 or 0.8, i == cell.selected and 1 or 0.8, i == cell.selected and 1 or 0.8)
        end
        GameTooltip:AddLine(L.TAB_CYCLE)
    end
    if ns.db.favorites[e[1][1]] then GameTooltip:AddLine(L.FAV_TAG) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.CLICK_TRY)
    GameTooltip:AddLine(L.FAV_TIP)
    GameTooltip:AddLine(L.SHIFT_LINK)
    GameTooltip:AddLine(L.CTRL_URL)
    GameTooltip:Show()
end

tabDummy:SetScript("OnClick", function()
    local cell = hoverCell
    if not cell or not cell.entry then return end
    local n = #(cell.entry[2] or {})
    if n > 1 then
        cell.selected = cell.selected % n + 1
        fillTooltip(cell)
    end
end)

-- Reaplica la camara de las miniaturas durante ~1.5 s tras vestirlas: el cliente puede
-- reiniciarla mientras termina de cargar el modelo de forma asincrona.
local watching = {}
local watcher = CreateFrame("Frame")
watcher:Hide()
watcher:SetScript("OnUpdate", function(self)
    local now, any = GetTime(), false
    for c in pairs(watching) do
        if c.entry and c.camCfg and now < c.camUntil then
            local cfg = c.camCfg
            c.model:SetPosition(cfg.x or 0, cfg.y or 0, cfg.z or 0)
            c.model:SetFacing(cfg.facing or 0)
            any = true
        else
            watching[c] = nil
        end
    end
    if not any then self:Hide() end
end)

function UI.CreateGrid(parent)
    local grid = CreateFrame("Frame", nil, parent)
    local cells, free = {}, {}
    local list, setup = {}, nil
    local perPage, pageCount, page = 0, 1, 1
    local work = {}          -- cola de celdas por vestir

    -- ---------- trabajo repartido ----------
    local worker = CreateFrame("Frame")
    worker:Hide()
    worker:SetScript("OnUpdate", function(self)
        for _ = 1, WORK_PER_TICK do
            local job = table.remove(work, 1)
            if not job then self:Hide() return end
            if job.cell.token == job.token and job.cell.entry then
                local c, m, s = job.cell, job.cell.model, setup
                local function cam(mm)
                    mm:SetPosition(s.x or 0, s.y or 0, s.z or 0)
                    mm:SetFacing(s.facing or 0)
                end
                -- Misma secuencia que el addon original: reset + undress + camara + TryOn
                m:SetPosition(0, 0, 0)
                m:SetFacing(0)
                m:ClearModel()
                m:SetUnit("player")
                cam(m)
                m:Undress()
                cam(m)
                m:TryOn(job.itemId)
                cam(m)
                c.camCfg = s
                c.camUntil = GetTime() + 1.5
                watching[c] = true
                watcher:Show()
                m:SetScript("OnUpdateModel", function(mm)
                    if s.sequence then mm:SetSequence(s.sequence) end
                end)
                if ns.db.settings.debug and grid._loggedToken ~= grid.token then
                    grid._loggedToken = grid.token
                    ns.After(0.8, function()
                        local x, y, z = m:GetPosition()
                        ns.Debug(string.format("camara miniatura: pedida x=%.2f y=%.2f z=%.2f | actual x=%.2f y=%.2f z=%.2f",
                            s.x or 0, s.y or 0, s.z or 0, x or 0, y or 0, z or 0))
                    end)
                end
                c.status:Hide()
            end
        end
    end)

    -- ---------- celda ----------
    local function newCell()
        local c = CreateFrame("Button", nil, grid)
        UI.Flat(c, C.panel, C.border)
        c.model = CreateFrame("DressUpModel", nil, c)
        c.model:SetPoint("TOPLEFT", 1, -1)
        c.model:SetPoint("BOTTOMRIGHT", -1, 1)
        c.model:SetUnit("player")        -- como el original: el modelo se carga al crearlo

        c.overlay = CreateFrame("Frame", nil, c)       -- por encima del modelo
        c.overlay:SetAllPoints()
        c.overlay:SetFrameLevel(c.model:GetFrameLevel() + 2)

        -- Velo oscuro para las apariencias no conseguidas (SetAlpha no afecta de forma fiable a los modelos 3D)
        c.shade = c.overlay:CreateTexture(nil, "BACKGROUND")
        c.shade:SetPoint("TOPLEFT", 1, -1)
        c.shade:SetPoint("BOTTOMRIGHT", -1, 1)
        c.shade:SetTexture(0.02, 0.025, 0.04, 0.62)
        c.shade:Hide()

        c.status = UI.Text(c.overlay, 11, C.dim, "CENTER")
        c.status:SetPoint("CENTER")
        c.badge = c.overlay:CreateTexture(nil, "OVERLAY")
        c.badge:SetSize(18, 18)
        c.badge:SetPoint("TOPRIGHT", -4, -4)
        c.badge:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        c.lock = c.overlay:CreateTexture(nil, "OVERLAY")
        c.lock:SetSize(14, 14)
        c.lock:SetPoint("TOPLEFT", 4, -4)
        c.lock:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        c.lock:SetAlpha(0.85)

        c.fav = c.overlay:CreateTexture(nil, "OVERLAY")
        c.fav:SetSize(16, 16)
        c.fav:SetPoint("BOTTOMRIGHT", -4, 4)
        c.fav:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        c.fav:Hide()

        c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        c:SetScript("OnEnter", function(self)
            hoverCell = self
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
            self.selected = self.selected or 1
            fillTooltip(self)
            if self.entry and #(self.entry[2] or {}) > 1 then
                SetOverrideBindingClick(tabDummy, true, "TAB", "TransmogVaultTabDummy")
            end
        end)
        c:SetScript("OnLeave", function(self)
            hoverCell = nil
            ClearOverrideBindings(tabDummy)
            self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            GameTooltip:Hide()
        end)
        c:SetScript("OnClick", function(self, button)
            if self.entry and grid.onClick then
                grid.onClick(self, self.entry, self.entry[1][self.selected or 1], button)
            end
        end)
        c:SetScript("OnHide", function(self)
            if hoverCell == self then hoverCell = nil; ClearOverrideBindings(tabDummy) end
        end)
        return c
    end

    local function paintState(c)
        local u = ns.Unlocks.HasAny(c.entry[1])
        c.unlocked = u
        c.model:SetAlpha(u and 1 or 0.6)
        if u then c.shade:Hide() else c.shade:Show() end
        if u then c.badge:Show(); c.lock:Hide() else c.badge:Hide(); c.lock:Show() end
        if ns.db.favorites[c.entry[1][1]] then c.fav:Show() else c.fav:Hide() end
    end

    local function loadCell(c, entry)
        c.entry, c.selected, c.token = entry, 1, grid.token
        c:Show()
        c.model:Show()
        c.model:ClearModel()             -- vacio (sin personaje) hasta que se vista
        c.badge:Hide(); c.lock:Hide(); c.fav:Hide(); c.shade:Hide()
        c.status:SetText(ns.L.LOADING); c.status:Show()
        c:Show()
        local id = entry[1][1]
        ns.Query(id, function(itemId, ok)
            if c.entry ~= entry or c.token ~= grid.token then return end
            if ok then
                paintState(c)
                work[#work + 1] = { cell = c, token = c.token, itemId = itemId }
                worker:Show()
            else
                c.status:SetText(ns.L.QUERY_FAILED)
            end
        end)
    end

    -- ---------- distribucion ----------
    function grid:Layout()
        local s = setup
        local w, h = s.width or 110, s.height or 150
        local gap = 6
        local cols = math.max(1, math.floor((self:GetWidth() + gap) / (w + gap)))
        local rows = math.max(1, math.floor((self:GetHeight() + gap) / (h + gap)))
        perPage = cols * rows
        local usedW = cols * (w + gap) - gap
        local offX = math.floor((self:GetWidth() - usedW) / 2)
        for i = 1, perPage do
            local c = cells[i]
            if not c then c = table.remove(free) or newCell(); cells[i] = c end
            c:SetSize(w, h)
            c:ClearAllPoints()
            local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
            c:SetPoint("TOPLEFT", self, "TOPLEFT", offX + col * (w + gap), -row * (h + gap))
        end
        for i = #cells, perPage + 1, -1 do
            local c = table.remove(cells)
            c.entry = nil; c:Hide(); c.model:ClearModel()
            table.insert(free, c)
        end
    end

    function grid:SetData(newList, newSetup, newPage)
        list, setup = newList or {}, newSetup or setup or {}
        self:Layout()
        pageCount = math.max(1, math.ceil(#list / math.max(perPage, 1)))
        self:SetPage(newPage or 1)
    end

    function grid:SetPage(p)
        p = math.max(1, math.min(p or 1, pageCount))
        page = p
        self.token = (self.token or 0) + 1
        for i = #work, 1, -1 do work[i] = nil end
        ns.QueryDropPending()
        for i = 1, #cells do
            local c = cells[i]
            local entry = list[(p - 1) * perPage + i]
            if entry then
                loadCell(c, entry)
            else
                c.entry = nil; c:Hide()
            end
        end
        if self.onPageChanged then self.onPageChanged(page, pageCount, #list) end
    end

    -- Solo repinta el estado (sin recargar modelos) cuando cambian los desbloqueos
    function grid:RefreshStates()
        for i = 1, #cells do
            local c = cells[i]
            if c.entry and c:IsShown() then paintState(c) end
        end
    end

    function grid:GetPage() return page end
    function grid:GetPageCount() return pageCount end
    function grid:GetPerPage() return perPage end
    function grid:NextPage(d) self:SetPage(page + d) end

    grid:EnableMouseWheel(true)
    grid:SetScript("OnMouseWheel", function(self, d) self:NextPage(-d) end)
    return grid
end
