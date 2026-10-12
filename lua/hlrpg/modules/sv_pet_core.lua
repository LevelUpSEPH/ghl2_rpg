-- hlrpg/modules/sv_pet_core.lua
-- Pet spawning, leveling/evolution and customization.

util.AddNetworkString("HLRPG_UpdatePetCustomization")

local MAX_PET_NAME_LENGTH = 32

function HLRPG.GetPetStats(ply, petID)
    local level = ply:GetNWInt("PetLevel_" .. petID, 1)
    local evo, stage = HLRPG.GetPetEvolution(petID, level)
    if not evo then return nil end

    return {
        class = evo.class,
        name = evo.name,
        maxHealth = evo.baseHealth + ((level - stage) * evo.healthPerLevel),
        dmgMultiplier = evo.dmgMultiplier,
        level = level,
        stage = stage,
        reqXP = HLRPG.GetPetRequiredXP(petID, level)
    }
end

function HLRPG.SummonPet(ply, petID)
    if not IsValid(ply) or petID == "none" then return end

    if HLRPG.IsSafeMap() then
        ply:ChatPrint("[PET] Pets can't be summoned on this map!")
        return
    end

    local stats = HLRPG.GetPetStats(ply, petID)
    if not stats then return end

    if IsValid(ply.CurrentRPGPet) then
        ply.CurrentRPGPet:Remove()
    end

    local evo = HLRPG.PetData[petID].Evolutions[stats.stage]
    local pet = ents.Create(stats.class)
    if not IsValid(pet) then return end

    local customName, customColor = ply:GetPetCustomization(petID)
    local colorVec = customColor or Vector(1, 1, 1)

    pet:SetNWString("HLRPG_PetEntityName", customName or stats.name)
    pet:SetNWVector("HLRPG_CustomColor", colorVec)

    if evo.modelScale then
        pet:SetModelScale(evo.modelScale, 0)
    end

    if evo.weapon then
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
    pet:SetNWEntity("HLRPG_PetOwner", ply)

    pet:SetKeyValue("squadname", "")
    pet:SetKeyValue("spawnflags", "256")

    pet:Spawn()
    pet:Activate()

    if evo.OnSpawn then evo.OnSpawn(pet) end

    if evo.weapon and pet:IsNPC() then
        pet:CapabilitiesAdd(CAP_WEAPON_RANGE_ATTACK1)
    end

    pet:SetMaxHealth(stats.maxHealth)
    pet:SetHealth(stats.maxHealth)
    pet:SetColor(Color(colorVec.x * 255, colorVec.y * 255, colorVec.z * 255))

    ply.CurrentRPGPet = pet
    ply:SetNWEntity("HLRPG_ActivePetEntity", pet)
    pet:SetNWBool("HLRPG_ISPET", true)

    HLRPG.SetupPetRelationships(pet, ply)

    ply:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 70, 140)
    local effectData = EffectData()
    effectData:SetOrigin(spawnPos)
    util.Effect("EntityDissolve", effectData)
end

-- Adds XP to one of ply's pets, leveling it up (possibly several times) and evolving it as needed.
-- The pet doesn't need to be summoned; if it is, its stats update in place.
function HLRPG.AddPetXP(ply, petID, amount)
    local level = ply:GetNWInt("PetLevel_" .. petID, 1)
    local xp = ply:GetNWInt("PetXP_" .. petID, 0) + amount
    local startStage = HLRPG.GetPetEvolutionStage(petID, level)

    local startLevel = level
    while xp >= HLRPG.GetPetRequiredXP(petID, level) do
        xp = xp - HLRPG.GetPetRequiredXP(petID, level)
        level = level + 1
    end

    ply:SetNWInt("PetLevel_" .. petID, level)
    ply:SetNWInt("PetXP_" .. petID, xp)
    ply:SavePetProgress(petID, level, xp)

    if level == startLevel then return end

    local pet = ply.CurrentRPGPet
    local isSummoned = IsValid(pet) and pet.PetID == petID

    local newEvo, newStage = HLRPG.GetPetEvolution(petID, level)
    if newStage ~= startStage then
        ply:ChatPrint("✨ YOUR PET EVOLVED!: " .. newEvo.name)
        if isSummoned then HLRPG.SummonPet(ply, petID) end
        return
    end

    local newStats = isSummoned and HLRPG.GetPetStats(ply, petID)
    if newStats then
        pet:SetMaxHealth(newStats.maxHealth)
        pet:SetHealth(newStats.maxHealth)
        pet.CurrentStats = newStats
        pet:SetNWInt("HLRPG_PetEntityLevel", level)
    end

    ply:ChatPrint("🎉 Pet Level Up: " .. level)
end

-- Pets gain 1 XP per kill
-- Summoning is refused on safe maps (SummonPet), but Lambda's level transitions carry NPCs standing in the
-- changelevel area over to the next map. Pets are left behind when heading into a safe map, and any that
-- still arrive on one are removed once the map and its transition have loaded.
local function RemoveAllPets()
    for _, ent in ipairs(ents.GetAll()) do
        if ent.IsHLRPGPet or ent:GetNWBool("HLRPG_ISPET", false) then ent:Remove() end
    end
end

hook.Add("LambdaPreChangelevel", "HLRPG_NoPetsIntoSafeMaps", function(nextMap)
    if HLRPG.Config.SafeMaps[string.lower(nextMap or "")] then RemoveAllPets() end
end)

hook.Add("InitPostEntity", "HLRPG_NoPetsOnSafeMaps", function()
    if not HLRPG.IsSafeMap() then return end
    timer.Simple(3, RemoveAllPets)
end)

hook.Add("OnNPCKilled", "HLRPG_Pet_XP_Logic", function(victim, attacker, inflictor)
    if not IsValid(attacker) or not attacker.IsHLRPGPet or not IsValid(attacker.OwnerPly) then return end

    HLRPG.AddPetXP(attacker.OwnerPly, attacker.PetID, 1)
end)

net.Receive("HLRPG_UpdatePetCustomization", function(len, ply)
    local petID = net.ReadString()
    local name = string.sub(net.ReadString(), 1, MAX_PET_NAME_LENGTH)
    local col = net.ReadColor()

    if not HLRPG.PetData[petID] or not ply:OwnsItem(petID) then return end

    ply:SavePetCustomization(petID, name, col)

    local pet = ply.CurrentRPGPet
    if IsValid(pet) and pet.PetID == petID then
        pet:SetNWString("HLRPG_PetEntityName", name)
        pet:SetNWVector("HLRPG_CustomColor", Vector(col.r / 255, col.g / 255, col.b / 255))
        pet:SetRenderMode(RENDERMODE_TRANSCOLOR)
        pet:SetColor(col)
    end
end)
