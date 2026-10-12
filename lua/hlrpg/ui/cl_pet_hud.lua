-- hlrpg/ui/cl_pet_hud.lua
-- Active pet's health (orange) and XP (blue) as two vertical bars on the left.

local BAR_W, BAR_H = 12, 200

hook.Add("HUDPaint", "HLRPG_PetHUD_Final", function()
    local ply = LocalPlayer()
    local activeID = ply:GetNWString("HLRPG_ActivePet", "none")
    if activeID == "none" then return end

    local maxHP = ply:GetNWInt("HLRPG_Pet_MaxHP", 100)
    if maxHP <= 0 then maxHP = 100 end
    local hpPerc = math.Clamp(ply:GetNWInt("HLRPG_Pet_CurHP", 0) / maxHP, 0, 1)

    local level = ply:GetNWInt("PetLevel_" .. activeID, 1)
    local xpPerc = math.Clamp(ply:GetNWInt("PetXP_" .. activeID, 0) / HLRPG.GetPetRequiredXP(activeID, level), 0, 1)

    local x, y = 30, ScrH() / 2 - 100

    draw.RoundedBox(4, x, y, BAR_W, BAR_H, Color(0, 0, 0, 200))
    draw.RoundedBox(4, x + 18, y, BAR_W, BAR_H, Color(0, 0, 0, 200))

    draw.RoundedBox(4, x, y + BAR_H * (1 - hpPerc), BAR_W, BAR_H * hpPerc, Color(255, 140, 0))
    draw.RoundedBox(4, x + 18, y + BAR_H * (1 - xpPerc), BAR_W, BAR_H * xpPerc, Color(0, 150, 255))

    draw.SimpleText("LVL " .. level, "DermaDefaultBold", x, y - 20, Color(255, 255, 255))
end)
