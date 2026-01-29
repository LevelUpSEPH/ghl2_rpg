-- addons/halflife_rpg/lua/hlrpg/modules/sv_pet_equipment.lua
if not SERVER then return end

function HLRPG_ApplyPet(ply, petID)
    if not IsValid(ply) then return end

    if ply:GetNWString("HLRPG_ActivePet") == petID then
        if IsValid(ply.CurrentRPGPet) then ply.CurrentRPGPet:Remove() end
        ply:SetNWString("HLRPG_ActivePet", "none")
        ply:ChatPrint("[PET] Pet geri gönderildi.")
        return
    end

    ply:SetNWString("HLRPG_ActivePet", petID)
    HLRPG_SummonPet(ply, petID)
end

hook.Add("PlayerSay", "HLRPG_PetSummon_Chat", function(ply, text)
    if text == "!petsummon" then
        local activeID = ply:GetNWString("HLRPG_ActivePet", "none")
        if activeID ~= "none" then
            HLRPG_SummonPet(ply, activeID)
        end
        return ""
    end
end)