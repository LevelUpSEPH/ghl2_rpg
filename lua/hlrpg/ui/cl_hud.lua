-- hlrpg/ui/cl_hud.lua
-- XP bar along the bottom of the screen and the current world difficulty.

surface.CreateFont("HLRPG_HUD_Bold", { font = "Verdana", size = 14, weight = 800, antialias = true })
surface.CreateFont("HLRPG_HUD_XP", { font = "Verdana", size = 12, weight = 700, antialias = true })

local XP_BAR_HEIGHT = 18

hook.Add("HUDPaint", "HLRPG_StrictHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local xp = ply:GetNWInt("HLRPG_XP", 0)
    local lvl = ply:GetNWInt("HLRPG_Level", 1)
    local maxXP = ply:GetNWInt("HLRPG_MaxXP", lvl * 100)
    if maxXP <= 0 then maxXP = 100 end

    local xpPercent = math.Clamp(xp / maxXP, 0, 1)
    local xpY = ScrH() - XP_BAR_HEIGHT

    surface.SetDrawColor(0, 0, 0, 180)
    surface.DrawRect(0, xpY, ScrW(), XP_BAR_HEIGHT)

    surface.SetDrawColor(50, 200, 50, 150)
    surface.DrawRect(0, xpY, ScrW() * xpPercent, XP_BAR_HEIGHT)

    local xpText = "LEVEL " .. lvl .. " - PROGRESS: %" .. math.floor(xpPercent * 100) .. " (" .. xp .. "/" .. maxXP .. ")"
    draw.SimpleText(xpText, "HLRPG_HUD_XP", (ScrW() / 2) + 1, xpY + 3, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER)
    draw.SimpleText(xpText, "HLRPG_HUD_XP", ScrW() / 2, xpY + 2, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER)

    local diffData = HLRPG.GetDifficulty()
    draw.SimpleText("MODE: " .. diffData.name, "HLRPG_HUD_Bold", 20, ScrH() - 40, diffData.color, TEXT_ALIGN_LEFT)
end)
