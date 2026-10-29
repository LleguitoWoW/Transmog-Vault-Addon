local addon, ns = ...

-- Boton del minimapa (arrastrable alrededor del borde).

local btn

local function place()
    local angle = math.rad(ns.db.settings.minimapAngle or 215)
    local r = (Minimap:GetWidth() / 2) + 5
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function build()
    btn = CreateFrame("Button", "TransmogVaultMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20); bg:SetPoint("TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20); icon:SetPoint("TOPLEFT", 7, -5)
    icon:SetTexture("Interface\\Icons\\INV_Chest_Cloth_17")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53); border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    btn:SetScript("OnClick", function() ns:Fire("TOGGLE_WINDOW") end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(ns.L.MM_TITLE, 0.35, 0.62, 1)
        GameTooltip:AddLine(ns.L.MM_CLICK, 1, 1, 1)
        GameTooltip:AddLine(ns.L.MM_DRAG, 0.6, 0.6, 0.6)
        GameTooltip:AddLine(ns.Unlocks.Count() .. " " .. ns.L.COLLECTED_TIP:lower(), 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            ns.db.settings.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx)) % 360
            place()
        end)
    end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    place()
    if not ns.db.settings.showMinimap then btn:Hide() end
end

ns:On("LOGIN", build)
ns:On("MINIMAP_VISIBILITY", function()
    if not btn then return end
    if ns.db.settings.showMinimap then btn:Show() else btn:Hide() end
end)
