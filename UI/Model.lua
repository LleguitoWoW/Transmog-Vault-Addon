local addon, ns = ...
local UI = ns.UI

-- Visor 3D principal: rotar (clic izq), mover (clic der), zoom (rueda).
-- Limites de camara por raza/sexo (valores del addon original).

local X_MIN = -0.75
local X_MAX = {
    Dwarf = { 2.6, 1.55 }, Draenei = { 3.2, 3.0 }, Gnome = { 1.44, 1.1 }, Human = { 2.10, 1.9 },
    NightElf = { 3.3, 3.2 }, BloodElf = { 2.9, 2.2 }, Orc = { 2.2, 2.35 }, Scourge = { 2.0, 3.0 },
    Tauren = { 2.90, 2.4 }, Troll = { 3.0, 3.0 },
}
local Z_MIN = {
    Dwarf = { -0.80, -0.60 }, Draenei = { -1.15, -0.97 }, Gnome = { -0.30, -0.32 }, Human = { -1.05, -1.76 },
    NightElf = { -1.05, -0.87 }, BloodElf = { -1.00, -0.75 }, Orc = { -0.75, -0.75 }, Scourge = { -0.80, -0.67 },
    Tauren = { -0.80, -0.50 }, Troll = { -0.75, -0.75 },
}
local Z_MAX = {
    Dwarf = { 0.52, 0.75 }, Draenei = { 1.15, 0.92 }, Gnome = { 0.48, 0.47 }, Human = { 0.78, 0.77 },
    NightElf = { 0.96, 0.96 }, BloodElf = { 0.75, 0.80 }, Orc = { 0.95, 0.9 }, Scourge = { 0.75, 0.85 },
    Tauren = { 0.90, 1.35 }, Troll = { 1.25, 1.25 },
}

local FACING_STEP = math.rad(0.75)  -- por pixel
local Z_STEP = 0.003                -- por pixel
local X_STEP = 0.2                  -- por rueda

local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end

function UI.CreateModelView(parent)
    local f = CreateFrame("Frame", nil, parent)
    UI.Flat(f, ns.db and ns.db.settings.bgColor or UI.color.bg, UI.color.border)
    f:EnableMouseWheel(true)

    local model = CreateFrame("DressUpModel", nil, f)
    model:SetPoint("TOPLEFT", 1, -1)
    model:SetPoint("BOTTOMRIGHT", -1, 1)
    f.model = model

    model:SetUnit("player")
    f._init = true

    local race, sexId = ns.Data.raceFile, ns.Data.sex
    local si = (sexId == 3) and 2 or 1
    local function limits()
        local xmax = (X_MAX[race] or { 2.5, 2.5 })[si]
        local zmin = (Z_MIN[race] or { -1, -1 })[si]
        local zmax = (Z_MAX[race] or { 1, 1 })[si]
        return X_MIN, xmax, zmin, zmax
    end

    local unit = "player"
    local function resetView()
        model:SetPosition(0, 0, 0)
        model:SetFacing(0)
    end

    function f:Reset()
        local x, y, z = model:GetPosition()
        local facing = model:GetFacing()
        model:ClearModel()
        model:SetUnit("player")
        unit = "player"
        race = ns.Data.raceFile; si = (ns.Data.sex == 3) and 2 or 1
        local xmin, xmax, zmin, zmax = limits()
        model:SetPosition(clamp(x, xmin, xmax), y, clamp(z, zmin, zmax))
        model:SetFacing(facing)
    end

    function f:SetTarget()
        if UnitIsPlayer("target") and CheckInteractDistance("target", 1) then
            model:ClearModel()
            model:SetUnit("target")
            unit = "target"
            local _, r = UnitRace("target")
            race = r or race
            si = (UnitSex("target") == 3) and 2 or 1
            resetView()
            return true
        end
        return false
    end

    function f:Undress() model:Undress() end
    function f:TryOn(id) model:TryOn(id) end
    function f:ResetCamera() resetView() end

    function f:SetBackground(c)
        self:SetBackdropColor(c[1], c[2], c[3], c[4] or 1)
    end

    -- Arrastre: izquierdo rota, derecho sube/baja
    local anim            -- animacion de camara en curso (FocusCamera)
    local drag
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self, button)
        local x, y = GetCursorPosition()
        anim = nil
        drag = { button = button, x = x, y = y }
    end)
    model:SetScript("OnMouseUp", function() drag = nil end)
    f:SetScript("OnHide", function() drag = nil end)
    model:SetScript("OnUpdate", function(self, el)
        if anim then
            anim.t = anim.t + el
            local k = math.min(1, anim.t / anim.dur)
            k = k * k * (3 - 2 * k)                       -- suavizado
            local _, y = self:GetPosition()
            self:SetPosition(anim.fx + (anim.tx - anim.fx) * k, y, anim.fz + (anim.tz - anim.fz) * k)
            self:SetFacing(anim.ff + anim.df * k)
            if anim.t >= anim.dur then anim = nil end
        end
        if not drag then return end
        if not IsMouseButtonDown(drag.button) then drag = nil return end
        local x, y = GetCursorPosition()
        if drag.button == "LeftButton" then
            self:SetFacing(self:GetFacing() + (x - drag.x) * FACING_STEP)
        else
            local px, py, pz = self:GetPosition()
            local _, _, zmin, zmax = limits()
            self:SetPosition(px, py, clamp(pz + (y - drag.y) * Z_STEP, zmin, zmax))
        end
        drag.x, drag.y = x, y
    end)

    f:SetScript("OnMouseWheel", function(_, delta)
        anim = nil
        local x, y, z = model:GetPosition()
        local xmin, xmax = limits()
        model:SetPosition(clamp(x + delta * X_STEP, xmin, xmax), y, z)
    end)
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseWheel", f:GetScript("OnMouseWheel"))

    -- Acerca la camara a la zona del hueco, con los datos de camara de las previews
    function f:FocusCamera(setup)
        if type(setup) ~= "table" then return end
        local xmin, xmax, zmin, zmax = limits()
        local k = (ns.db and ns.db.settings.zoomFactor) or 0.85
        local fx, _, fz = model:GetPosition()
        local ff = model:GetFacing()
        local tf = setup.facing or 0
        local df = ((tf - ff + math.pi) % (2 * math.pi)) - math.pi   -- giro por el lado corto
        anim = { t = 0, dur = 0.3, fx = fx, fz = fz, ff = ff, df = df,
            tx = clamp((setup.x or 0) * k, xmin, xmax),
            tz = clamp(setup.z or 0, zmin, zmax) }
    end

    -- Si el cliente descarto el modelo mientras estaba oculto, lo recarga al mostrarse
    f:SetScript("OnShow", function()
        if not f._dressed then model:SetUnit(unit) end
    end)
    local baseTryOn, baseUndress = f.TryOn, f.Undress
    function f:TryOn(id) f._dressed = true; model:TryOn(id) end
    function f:Undress() f._dressed = true; model:Undress() end
    return f
end