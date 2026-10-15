-- hlrpg/ui/cl_implants.lua
-- Implants on the client: the activation key, the cooldown readout, and the neon glow players have while
-- their implant's active runs (in the implant's colour, seen by everyone).

local keyVar = CreateClientConVar("hlrpg_implant_key", "g", true, false, "Key that activates your implant's active ability")

local function GetImplant(ply)
    local kind = ply:GetNWString("HLRPG_ImplantKind", "")
    if kind == "" then return nil end
    return HLRPG.Gear.GetImplantValues(kind, ply:GetNWInt("HLRPG_ImplantRarity", 1), ply:GetNWFloat("HLRPG_ImplantRoll", 0.5))
end

-- Seconds the active has left, or nil when it isn't running
local function ActiveRemaining(ply, implant)
    local started = ply:GetNWFloat("HLRPG_ImplantActiveStart", 0)
    if started <= 0 or not implant or not implant.active then return nil end
    local left = implant.active.duration - (CurTime() - started)
    return left > 0 and left or nil
end

hook.Add("PlayerButtonDown", "HLRPG_ImplantKey", function(ply, button)
    if not IsFirstTimePredicted() or ply ~= LocalPlayer() then return end
    if button ~= input.GetKeyCode(keyVar:GetString()) then return end
    if gui.IsGameUIVisible() or vgui.CursorVisible() or ply:IsTyping() then return end

    local implant = GetImplant(ply)
    if not implant or not implant.active then return end
    net.Start("HLRPG_ImplantActivate")
    net.SendToServer()
end)

-- Readout above the XP bar: key, active name, and ready / running / cooldown
hook.Add("HUDPaint", "HLRPG_ImplantHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local implant = GetImplant(ply)
    if not implant or not implant.active then return end

    local c = ply:GetNWVector("HLRPG_ImplantColor", Vector(1, 1, 1))
    local neon = Color(c.x * 255, c.y * 255, c.z * 255)
    local left = ActiveRemaining(ply, implant)
    local cooldown = ply:GetNWFloat("HLRPG_ImplantReady", 0) - CurTime()

    local status, statusColor
    if left then
        status, statusColor = string.format("ACTIVE %.1fs", left), neon
    elseif cooldown > 0 then
        status, statusColor = string.format("%ds", math.ceil(cooldown)), Color(150, 150, 150)
    else
        status, statusColor = "READY", Color(120, 230, 140)
    end

    local key = string.upper(keyVar:GetString())
    local text = "[" .. key .. "]  " .. string.upper(implant.active.name) .. "   " .. status
    surface.SetFont("DermaDefaultBold")
    local tw = surface.GetTextSize(text)
    local x, y = ScrW() / 2 - tw / 2 - 12, ScrH() - 58
    draw.RoundedBox(4, x, y, tw + 24, 22, Color(0, 0, 0, 170))
    surface.SetDrawColor(neon.r, neon.g, neon.b, 220)
    surface.DrawRect(x, y + 20, (tw + 24) * (left and left / implant.active.duration or (cooldown > 0 and 1 - cooldown / implant.active.cooldown or 1)), 2)
    draw.SimpleText(text, "DermaDefaultBold", ScrW() / 2, y + 11, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

-- Neon glow while an active runs: the player's models get a bright, unlit overlay in the implant colour, plus a
-- halo. With a suit, the suit models carry it (the player model itself is invisible then).
local neonMat = Material("models/debug/debug_white")

local function IsGlowing(ply)
    return ply:Alive() and ActiveRemaining(ply, GetImplant(ply)) ~= nil
end

local function GlowColor(ply)
    local c = ply:GetNWVector("HLRPG_ImplantColor", Vector(1, 1, 1))
    return c.x, c.y, c.z
end

local function DrawNeonPass(ent, ply)
    local r, g, b = GlowColor(ply)
    local pulse = 0.45 + math.abs(math.sin(CurTime() * 4)) * 0.25
    render.SuppressEngineLighting(true)
    render.MaterialOverride(neonMat)
    render.SetColorModulation(r, g, b)
    render.SetBlend(pulse)
    ent:DrawModel()
    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride(nil)
    render.SuppressEngineLighting(false)
end

local function NeonRenderOverride(self)
    self:DrawModel()
    local ply = self.HLRPG_GlowOwner
    if IsValid(ply) and IsGlowing(ply) then DrawNeonPass(self, ply) end
end

local drawingNeon = false
hook.Add("PostPlayerDraw", "HLRPG_ImplantNeon", function(ply)
    if drawingNeon or not IsGlowing(ply) then return end
    if #HLRPG.GetSuitVisualEntities(ply) > 0 then return end -- the suit models glow instead
    drawingNeon = true
    DrawNeonPass(ply, ply)
    drawingNeon = false
end)

-- Suit models get the overlay through their render override (set once per model)
timer.Create("HLRPG_ImplantNeonSuits", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        for _, ent in ipairs(HLRPG.GetSuitVisualEntities(ply)) do
            if not ent.HLRPG_GlowOwner then
                ent.HLRPG_GlowOwner = ply
                ent.RenderOverride = NeonRenderOverride
            end
        end
    end
end)

hook.Add("PreDrawHalos", "HLRPG_ImplantHalo", function()
    for _, ply in ipairs(player.GetAll()) do
        if IsGlowing(ply) and (ply ~= LocalPlayer() or ply:ShouldDrawLocalPlayer()) then
            local ents = HLRPG.GetSuitVisualEntities(ply)
            if #ents == 0 then ents = { ply } end
            local r, g, b = GlowColor(ply)
            halo.Add(ents, Color(r * 255, g * 255, b * 255), 3, 3, 2, true, false)
        end
    end
end)

-- Vortal Blast: green lightning between the chain's points, flickering for a moment
local chains = {}
local CHAIN_TIME = 0.4
local beamMat = Material("sprites/physbeam")

net.Receive("HLRPG_VortalChain", function()
    local points = {}
    for i = 1, net.ReadUInt(4) do points[i] = net.ReadVector() end
    chains[#chains + 1] = { points = points, born = CurTime() }
    for _, point in ipairs(points) do
        local light = DynamicLight(math.random(10000, 20000))
        if light then
            light.pos, light.r, light.g, light.b = point, 90, 255, 120
            light.brightness, light.size, light.decay, light.dietime = 3, 200, 600, CurTime() + CHAIN_TIME
        end
    end
end)

-- A jagged bolt from a to b: the straight line split into pieces, each joint knocked sideways a little
local function DrawBolt(a, b, alpha)
    local pieces, last = 7, a
    for i = 1, pieces do
        local point = LerpVector(i / pieces, a, b)
        if i < pieces then point = point + VectorRand() * 14 end
        render.DrawBeam(last, point, 6, 0, 1, Color(120, 255, 150, alpha))
        render.DrawBeam(last, point, 2, 0, 1, Color(230, 255, 235, alpha))
        last = point
    end
end

-- Canister Strike: a pulsing red ring where it will land, with a countdown, seen by everyone
local strikes = {}

net.Receive("HLRPG_StrikeMarker", function()
    strikes[#strikes + 1] = { pos = net.ReadVector(), radius = net.ReadFloat(), hits = CurTime() + net.ReadFloat() }
    surface.PlaySound("npc/scanner/scanner_siren1.wav")
end)

hook.Add("PostDrawTranslucentRenderables", "HLRPG_ImplantEffects", function(depth, skybox)
    if skybox then return end
    local now = CurTime()

    render.SetMaterial(beamMat)
    for i = #chains, 1, -1 do
        local chain = chains[i]
        local age = now - chain.born
        if age > CHAIN_TIME then
            table.remove(chains, i)
        else
            local alpha = 255 * (1 - age / CHAIN_TIME)
            for j = 1, #chain.points - 1 do DrawBolt(chain.points[j], chain.points[j + 1], alpha) end
        end
    end

    for i = #strikes, 1, -1 do
        local strike = strikes[i]
        local left = strike.hits - now
        if left < -0.2 then
            table.remove(strikes, i)
        else
            local pulse = 0.85 + math.abs(math.sin(now * 8)) * 0.15
            cam.Start3D2D(strike.pos + Vector(0, 0, 2), Angle(0, 0, 0), 1)
                surface.DrawCircle(0, 0, strike.radius * pulse, 255, 40, 30, 220)
                surface.DrawCircle(0, 0, strike.radius * 0.5 * pulse, 255, 40, 30, 160)
                surface.DrawCircle(0, 0, 12, 255, 40, 30, 255)
            cam.End3D2D()
            local ang = (EyePos() - strike.pos):Angle()
            cam.Start3D2D(strike.pos + Vector(0, 0, 60), Angle(0, ang.y - 90, 90), 0.5)
                draw.SimpleText(string.format("%.1f", math.max(left, 0)), "DermaLarge", 0, 0, Color(255, 60, 40), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end)
