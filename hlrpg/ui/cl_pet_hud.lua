-- cl_pet_hud.lua
hook.Add("HUDPaint", "HLRPG_PetHUD_Final", function()
    local ply = LocalPlayer()
    local activeID = ply:GetNWString("HLRPG_ActivePet", "none")
    if activeID == "none" then return end

    local curHP = ply:GetNWInt("HLRPG_Pet_CurHP", 0)
    local maxHP = ply:GetNWInt("HLRPG_Pet_MaxHP", 100)
    if maxHP <= 0 then maxHP = 100 end

    local curXP = ply:GetNWInt("PetXP_" .. activeID, 0)
    local reqXP = HLRPG_GetPlayerPetRequiredXP(ply, activeID)

    local hpPerc = math.Clamp(curHP / maxHP, 0, 1)
    local xpPerc = math.Clamp(curXP / reqXP, 0, 1)

    local x, y = 30, ScrH() / 2 - 100
    local w, h = 12, 200

    draw.RoundedBox(4, x, y, w, h, Color(0, 0, 0, 200))
    draw.RoundedBox(4, x + 18, y, w, h, Color(0, 0, 0, 200))

    draw.RoundedBox(4, x, y + h * (1 - hpPerc), w, h * hpPerc, Color(255, 140, 0))
    
    draw.RoundedBox(4, x + 18, y + h * (1 - xpPerc), w, h * xpPerc, Color(0, 150, 255))
    
    -- Level Yazısı
    local stage = ply:GetNWInt("PetStage_" .. activeID, 0)
    local level = ply:GetNWInt("PetLevel_" .. activeID, 1)
    draw.SimpleText("LVL " .. (stage + level), "DermaDefaultBold", x, y - 20, Color(255, 255, 255))
end)