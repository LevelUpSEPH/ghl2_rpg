-- sv_pet_ai.lua
if not SERVER then return end

function HLRPG_SetupPetRelationships(pet, ply)
    if not IsValid(pet) or not IsValid(ply) then return end

    pet.Classify = function() return CLASS_PLAYER_ALLY end
    pet:AddRelationship("player D_LI 99")

    for _, ent in ipairs(ents.FindInSphere(pet:GetPos(), 800)) do
        if not IsValid(ent) or ent == pet or ent == ply or not ent:IsNPC() then continue end
        
        local disposition = ent:Disposition(ply)
        
        if disposition == D_LI then
            pet:AddRelationship(ent:GetClass() .. " D_LI 99") -- Pet Alyx'e saldırmaz
            ent:AddRelationship(pet:GetClass() .. " D_LI 99") -- Alyx pete saldırmaz
        elseif disposition == D_HT or disposition == D_FRIGHT then
            pet:AddRelationship(ent:GetClass() .. " D_HT 99") -- Pet Zombiye saldırır
            ent:AddRelationship(pet:GetClass() .. " D_HT 99") -- Zombi pete saldırır
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
            if not IsValid(enemy) and pet:GetPos():Distance(ply:GetPos()) > 200 then
                pet:SetTarget(ply)
                pet:SetSchedule(SCHED_TARGET_CHASE)
            end
        end
    end
end)