-- addons/halflife_rpg/lua/hlrpg/modules/sv_pet_core.lua
if not SERVER then return end

local function GetEvoData(petID, stage)
    return HLRPG.PetData[petID] and HLRPG.PetData[petID].Evolutions[stage]
end

function HLRPG_GetPetStats(ply, petID)
    local pData = HLRPG.PetData[petID]
    if not pData then return nil end

    local stage = ply:GetNWInt("PetStage_" .. petID, 0)
    local level = ply:GetNWInt("PetLevel_" .. petID, 1)
    
    local evo = pData.Evolutions[stage]
    if not evo then return nil end

    return {
        class = evo.class,
        name = evo.name,
        maxHealth = evo.baseHealth + ((level - 1) * evo.healthPerLevel),
        dmgMultiplier = evo.dmgMultiplier, 
        level = level,
        stage = stage,
        threshold = evo.evolutionThreshold,
        reqXP = HLRPG_GetPlayerPetRequiredXP(ply, petID) 
    }
end

function HLRPG_SummonPet(ply, petID)
    if not IsValid(ply) or petID == "none" then return end
    
    local stats = HLRPG_GetPetStats(ply, petID)
    if not stats then return end

    if IsValid(ply.CurrentRPGPet) then 
        ply.CurrentRPGPet:Remove() 
    end

    local pet = ents.Create(stats.class)
    if not IsValid(pet) then return end

    local spawnPos = ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 20)
    pet:SetPos(spawnPos)
    pet:SetAngles(Angle(0, ply:GetAngles().y, 0))
    
    pet.IsHLRPGPet = true
    pet.OwnerPly = ply
    pet.PetID = petID
    pet.CurrentStats = stats

    pet:Spawn()
    pet:Activate()

    pet:SetMaxHealth(stats.maxHealth)
    pet:SetHealth(stats.maxHealth)
    
    pet:SetKeyValue("squadname", "")

    ply.CurrentRPGPet = pet
    ply:SetNWEntity("HLRPG_ActivePetEntity", pet)

    if HLRPG_SetupPetRelationships then
        HLRPG_SetupPetRelationships(pet, ply)
    else
        pet:AddRelationship("player D_LI 99")
    end

    ply:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 70, 140)
    local effectData = EffectData()
    effectData:SetOrigin(spawnPos)
    util.Effect("EntityDissolve", effectData)
end

hook.Add("EntityTakeDamage", "HLRPG_Pet_Damage_Master", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()

    if attacker.IsHLRPGPet and IsValid(attacker.OwnerPly) then
        local stats = attacker.CurrentStats
        if stats then
            local finalScale = stats.dmgMultiplier + ((stats.level - 1) * 0.1)
            dmginfo:ScaleDamage(finalScale)
        end
        
        if target:IsPlayer() or (target:IsNPC() and target:Disposition(attacker.OwnerPly) == D_LI) then
            dmginfo:SetDamage(0)
            return true
        end
    end

    if target.IsHLRPGPet and IsValid(target.OwnerPly) then
        if attacker:IsPlayer() or (attacker:IsNPC() and attacker:Disposition(target.OwnerPly) == D_LI) then
            dmginfo:SetDamage(0)
            return true
        end

        timer.Simple(0, function()
            if IsValid(target) and IsValid(target.OwnerPly) then
                target.OwnerPly:SetNWInt("HLRPG_Pet_CurHP", target:Health())
                target.OwnerPly:SetNWInt("HLRPG_Pet_MaxHP", target:GetMaxHealth())
            end
        end)
    end
end)

hook.Add("OnNPCKilled", "HLRPG_Pet_Global_Logic", function(victim, attacker, inflictor)
    if victim.IsHLRPGPet and IsValid(victim.OwnerPly) then
        victim.OwnerPly:SetNWString("HLRPG_ActivePet", "none")
        victim.OwnerPly:SetNWEntity("HLRPG_ActivePetEntity", nil)
        victim.OwnerPly:ChatPrint("💔 Petin öldü!")
        return
    end

    if IsValid(attacker) and attacker.IsHLRPGPet then
        local ply = attacker.OwnerPly
        local petID = attacker.PetID
        if not IsValid(ply) then return end

        local stats = HLRPG_GetPetStats(ply, petID)
        if not stats then return end

        local curXP = ply:GetNWInt("PetXP_" .. petID, 0) + 1
        local reqXP = stats.reqXP

        if curXP >= reqXP then
            curXP = 0
            local newLevel = stats.level + 1
            local totalLevel = stats.stage + (newLevel - 1)

            if stats.threshold and totalLevel > stats.threshold then
                local nextStage = stats.threshold
                if GetEvoData(petID, nextStage) then
                    ply:SetNWInt("PetStage_" .. petID, nextStage)
                    ply:SetNWInt("PetLevel_" .. petID, 1)
                    ply:SetNWInt("PetXP_" .. petID, 0)
                    
                    ply:ChatPrint("✨ PETİN EVRİM GEÇİRDİ: " .. GetEvoData(petID, nextStage).name)
                    HLRPG_SummonPet(ply, petID)
                    return 
                end
            end

            ply:SetNWInt("PetLevel_" .. petID, newLevel)
            ply:SetNWInt("PetXP_" .. petID, 0)

            local updatedStats = HLRPG_GetPetStats(ply, petID)
            attacker:SetMaxHealth(updatedStats.maxHealth)
            attacker:SetHealth(updatedStats.maxHealth)
            attacker.CurrentStats = updatedStats
            
            ply:ChatPrint("🎉 Pet Seviye Atladı: " .. newLevel .. " (Toplam: " .. totalLevel .. ")")
        else
            ply:SetNWInt("PetXP_" .. petID, curXP)
        end
    end
end)