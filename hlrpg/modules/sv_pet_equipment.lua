-- hlrpg/modules/sv_pet_equipment.lua
-- Which pet is active. Spawning and leveling live in sv_pet_core.lua, behaviour in sv_pet_ai.lua.

function HLRPG.DismissPet(ply)
    if IsValid(ply.CurrentRPGPet) then ply.CurrentRPGPet:Remove() end
    ply:SetNWString("HLRPG_ActivePet", "none")
    ply:ChatPrint("[PET] Pet dismissed.")
end

function HLRPG.TogglePet(ply, petID)
    if not IsValid(ply) then return end

    if ply:GetNWString("HLRPG_ActivePet", "none") == petID then
        HLRPG.DismissPet(ply)
        return
    end

    ply:SetNWString("HLRPG_ActivePet", petID)
    HLRPG.SummonPet(ply, petID)
end

HLRPG.AddChatCommand("!petsummon", function(ply)
    local activeID = ply:GetNWString("HLRPG_ActivePet", "none")
    if activeID ~= "none" then
        HLRPG.SummonPet(ply, activeID)
    end
end)
