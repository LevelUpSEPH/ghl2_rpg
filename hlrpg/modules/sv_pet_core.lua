-- addons/halflife_rpg/lua/hlrpg/modules/sv_pet_core.lua
if not SERVER then return end

util.AddNetworkString("HLRPG_UpdatePetCustomization")

local function GetEvoData(petID, stage)
    return HLRPG.PetData[petID] and HLRPG.PetData[petID].Evolutions[stage]
end

function HLRPG_GetPetStats(ply, petID)
    local level = ply:GetNWInt("PetLevel_" .. petID, 1)
    local stage = HLRPG_GetPetEvolutionStage(petID, level)
    local evo = HLRPG.PetData[petID].Evolutions[stage]
    
    if not evo then return nil end

    return {
        class = evo.class,
        name = evo.name,
        maxHealth = evo.baseHealth + ((level - stage) * evo.healthPerLevel),
        dmgMultiplier = evo.dmgMultiplier,
        level = level,
        stage = stage,
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
    local pData = HLRPG.PetData[petID]
    local evo = pData.Evolutions[stats.stage]
    local pet = ents.Create(stats.class)
    if not IsValid(pet) then return end
    
    local savedName = ply:GetPData("PetName_" .. petID) or stats.name
    local rawCol = ply:GetPData("PetColor_" .. petID)

    pet:SetNWString("HLRPG_PetEntityName", savedName)
    local savedColorVec = Vector(1, 1, 1)
    if rawCol then
        local colTable = util.JSONToTable(rawCol)
        if colTable and #colTable >= 3 then
            savedColorVec = Vector(colTable[1] / 255, colTable[2] / 255, colTable[3] / 255)
        end
    end
    pet:SetNWVector("HLRPG_CustomColor", savedColorVec)

    if evo.modelScale then
        pet:SetModelScale(evo.modelScale, 0)
    end

    if evo.weapon then
        print("Equipping pet with weapon: " .. evo.weapon)
        pet:SetKeyValue("additionalequipment", evo.weapon)
        pet:SetKeyValue("NumGrenades", "5") 
    end

    local spawnPos = ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 20)
    pet:SetPos(spawnPos)
    pet:SetAngles(Angle(0, ply:GetAngles().y, 0))
    
    pet.IsHLRPGPet = true
    pet.OwnerPly = ply
    pet.PetID = petID
    pet.CurrentStats = stats

    pet:SetNWInt("HLRPG_PetEntityLevel", stats.level)

    pet:SetKeyValue("squadname", "")
    pet:SetKeyValue("spawnflags", "256")
    
    pet:Spawn()
    pet:Activate()

    if evo.weapon and pet:IsNPC() then
        pet:CapabilitiesAdd(CAP_WEAPON_RANGE_ATTACK1)
    end

    pet:SetMaxHealth(stats.maxHealth)
    pet:SetHealth(stats.maxHealth)

    pet:SetColor(Color(savedColorVec.x * 255, savedColorVec.y * 255, savedColorVec.z * 255))

    ply.CurrentRPGPet = pet
    ply:SetNWEntity("HLRPG_ActivePetEntity", pet)

    pet:SetNWBool("HLRPG_ISPET", true)

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

hook.Add("OnNPCKilled", "HLRPG_Pet_XP_Logic", function(victim, attacker, inflictor)
    if IsValid(attacker) and attacker.IsHLRPGPet then
        local ply = attacker.OwnerPly
        local petID = attacker.PetID
        
        local currentLevel = ply:GetNWInt("PetLevel_" .. petID, 1)
        local currentXP = ply:GetNWInt("PetXP_" .. petID, 0) + 1
        
        local stage = HLRPG_GetPetEvolutionStage(petID, currentLevel)
        local evo = HLRPG.PetData[petID].Evolutions[stage]
        
        local reqXP = evo.xpRequired + ((currentLevel - stage) * evo.xpIncreasePerLevel)

        print("Pet XP: " .. currentXP .. " / " .. reqXP)
        
        if currentXP >= reqXP then
            currentXP = 0
            local newLevel = currentLevel + 1
            ply:SetNWInt("PetLevel_" .. petID, newLevel)
            ply:SetNWInt("PetXP_" .. petID, 0)

            ply:SavePetProgress(petID, newLevel, 0)

            local nextStage = HLRPG_GetPetEvolutionStage(petID, newLevel)
            if nextStage != stage then
                ply:ChatPrint("✨ PETİN EVRİMLEŞTİ: " .. HLRPG.PetData[petID].Evolutions[nextStage].name)
                HLRPG_SummonPet(ply, petID)
                return 
            else
                local newStats = HLRPG_GetPetStats(ply, petID)
                if newStats then
                    attacker:SetMaxHealth(newStats.maxHealth)
                    attacker:SetHealth(newStats.maxHealth)
                    attacker.CurrentStats = newStats
                    
                    attacker:SetNWInt("HLRPG_PetEntityLevel", newLevel)
                    attacker:SetNWString("HLRPG_PetEntityName", newStats.name)
                end
                
                ply:ChatPrint("🎉 Pet Seviye Atladı: " .. newLevel)
            end
        else
            ply:SetNWInt("PetXP_" .. petID, currentXP)

            ply:SavePetProgress(petID, currentLevel, currentXP)
        end
    end
end)

net.Receive("HLRPG_UpdatePetCustomization", function(len, ply)
    local petID = net.ReadString()
    local name = net.ReadString()
    local col = net.ReadColor()
    local colVec = Vector(col.r / 255, col.g / 255, col.b / 255)

    ply:SetPData("PetName_" .. petID, name)
    ply:SetPData("PetColor_" .. petID, util.TableToJSON({col.r, col.g, col.b}))

    local pet = ply.CurrentRPGPet
    if IsValid(pet) and pet.PetID == petID then
        pet:SetNWString("HLRPG_PetEntityName", name)
        pet:SetNWVector("HLRPG_CustomColor", colVec)
        pet:SetRenderMode(RENDERMODE_TRANSCOLOR)
        pet:SetColor(col)
    end
end)