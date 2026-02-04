-- sv_pet_ai.lua
if not SERVER then return end

function HLRPG_SetupPetRelationships(pet, ply)
    if not IsValid(pet) or not IsValid(ply) then return end

    if pet:IsNPC() then
        pet:SetKeyValue("squadname", "")
        pet:Fire("ClearSquad")
    end

    pet.Classify = function() return CLASS_PLAYER_ALLY end
    pet:AddEntityRelationship(ply, D_LI, 99)

    for _, otherPly in ipairs(player.GetAll()) do
        if otherPly == ply then continue end
        pet:AddEntityRelationship(otherPly, D_LI, 99)
    end

    for _, ent in ipairs(ents.FindInSphere(pet:GetPos(), 1000)) do
        if not IsValid(ent) or ent == pet or ent == ply or not ent:IsNPC() then continue end
        
        if ent.IsHLRPGPet then
            pet:AddEntityRelationship(ent, D_LI, 99)
            ent:AddEntityRelationship(pet, D_LI, 99)
            continue
        end

        local disposition = ent:Disposition(ply)
        
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
        if IsValid(pet) then
            HLRPG_SetupPetRelationships(pet, ply)
            
            ply:SetNWInt("HLRPG_Pet_CurHP", pet:Health())
            ply:SetNWInt("HLRPG_Pet_MaxHP", pet:GetMaxHealth())
            
            local enemy = pet:GetEnemy()
            
            if not IsValid(enemy) then
                if pet:GetPos():Distance(ply:GetPos()) > 250 then
                    pet:SetTarget(ply)
                    pet:SetSchedule(SCHED_TARGET_CHASE)
                end
            end

            local stage = ply:GetNWInt("PetStage_" .. pet.PetID, 0)
            local pData = HLRPG.PetData[pet.PetID]
            local evo = pData and pData.Evolutions[stage]
            if evo and evo.OnThink then
                evo.OnThink(pet, ply)
            end
        end
    end
end)