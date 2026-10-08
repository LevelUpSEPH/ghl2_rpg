-- hlrpg/modules/sv_pet_ai.lua

local FOLLOW_DISTANCE = 250
local RELATIONSHIP_RADIUS = 1000

-- Pets like their owner, all players and other pets, and copy their owner's enemies
function HLRPG.SetupPetRelationships(pet, ply)
    if not IsValid(pet) or not IsValid(ply) then return end

    if pet:IsNPC() then
        pet:SetKeyValue("squadname", "")
        pet:Fire("ClearSquad")
    end

    pet.Classify = function() return CLASS_PLAYER_ALLY end

    for _, otherPly in ipairs(player.GetAll()) do
        pet:AddEntityRelationship(otherPly, D_LI, 99)
    end

    for _, ent in ipairs(ents.FindInSphere(pet:GetPos(), RELATIONSHIP_RADIUS)) do
        if not IsValid(ent) or ent == pet or ent == ply or not ent:IsNPC() then continue end

        local disposition = ent.IsHLRPGPet and D_LI or ent:Disposition(ply)

        if disposition == D_LI then
            pet:AddEntityRelationship(ent, D_LI, 99)
            ent:AddEntityRelationship(pet, D_LI, 99)
        elseif disposition == D_HT or disposition == D_FRIGHT then
            pet:AddEntityRelationship(ent, D_HT, 99)
            ent:AddEntityRelationship(pet, D_HT, 99)
        end
    end
end

timer.Create("HLRPG_Pet_Logic_Think", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local pet = ply.CurrentRPGPet
        if not IsValid(pet) then continue end

        HLRPG.SetupPetRelationships(pet, ply)

        ply:SetNWInt("HLRPG_Pet_CurHP", pet:Health())
        ply:SetNWInt("HLRPG_Pet_MaxHP", pet:GetMaxHealth())

        if not IsValid(pet:GetEnemy()) and pet:GetPos():Distance(ply:GetPos()) > FOLLOW_DISTANCE then
            pet:SetTarget(ply)
            pet:SetSchedule(SCHED_TARGET_CHASE)
        end

        local evo = HLRPG.GetPetEvolution(pet.PetID, ply:GetNWInt("PetLevel_" .. pet.PetID, 1))
        if evo and evo.OnThink then
            evo.OnThink(pet, ply)
        end
    end
end)
