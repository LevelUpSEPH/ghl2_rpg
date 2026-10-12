-- hlrpg/ui/cl_boss_hud.lua
-- Health bars for nearby bosses (HLRPG.BossNPCs), stacked on the right side of the screen.

surface.CreateFont("HLRPG_BossName", { font = "Verdana", size = 13, weight = 800, antialias = true })
surface.CreateFont("HLRPG_BossPerc", { font = "Verdana", size = 11, weight = 700, antialias = true })

local SCAN_RADIUS = 3000
local FORGET_DISTANCE = 2000
local BAR_W, BAR_H = 180, 30
local START_Y = 120

local activeBosses = {}

local function IsTrackableBoss(ent)
    return IsValid(ent) and ent:IsNPC() and ent:GetNWBool("HLRPG_IsBoss")
        and not ent:GetNWBool("HLRPG_ISPET", false) and ent:Health() > 0
end

local function DrawBossBar(boss, x, y)
    local hpPerc = math.Clamp(boss:Health() / boss:GetMaxHealth(), 0, 1)
    local displayPerc = math.ceil(hpPerc * 100)

    draw.RoundedBox(4, x, y, BAR_W, BAR_H, Color(0, 0, 0, 180))

    surface.SetDrawColor(40, 0, 0, 200)
    surface.DrawRect(x + 5, y + 18, BAR_W - 10, 7)

    surface.SetDrawColor(200, 30, 30, 255)
    surface.DrawRect(x + 5, y + 18, (BAR_W - 10) * hpPerc, 7)

    draw.SimpleText(HLRPG.GetNPCName(boss), "HLRPG_BossName", x + 5, y + 3, Color(255, 255, 255, 255))

    local percColor = displayPerc <= 20 and Color(255, 50, 50) or Color(255, 255, 255)
    draw.SimpleText("%" .. displayPerc, "HLRPG_BossPerc", x + BAR_W - 5, y + 3, percColor, TEXT_ALIGN_RIGHT)
end

hook.Add("HUDPaint", "HLRPG_MultiBossHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), SCAN_RADIUS)) do
        if IsTrackableBoss(ent) then
            activeBosses[ent:EntIndex()] = ent
        end
    end

    local x = ScrW() - BAR_W - 25
    local y = START_Y

    for id, boss in pairs(activeBosses) do
        if not IsTrackableBoss(boss) or boss:GetPos():DistToSqr(ply:GetPos()) > FORGET_DISTANCE * FORGET_DISTANCE then
            activeBosses[id] = nil
            continue
        end

        DrawBossBar(boss, x, y)
        y = y + BAR_H + 8
    end
end)
