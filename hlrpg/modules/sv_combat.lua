-- hlrpg/modules/sv_combat.lua
-- One EntityTakeDamage dispatcher so the order of these rules is guaranteed.

local function IsPet(ent)
    return IsValid(ent) and ent.IsHLRPGPet and IsValid(ent.OwnerPly)
end

local function Block(dmginfo)
    dmginfo:SetDamage(0)
    return true
end

-- Players can't hurt other players or friendly story NPCs
local function IsProtectedFromPlayer(target, attacker)
    if target:IsPlayer() and target ~= attacker then return true end
    return target:IsNPC() and HLRPG.FriendlyNPCs[target:GetClass()] == true
end

-- How much harder a leveled NPC hits (level, plus the boss bonus)
function HLRPG.GetNPCDamageMultiplier(npc)
    local mult = HLRPG.GetNPCLevelMultiplier("DMG", HLRPG.GetNPCLevel(npc))
    if npc:GetNWBool("HLRPG_IsBoss") then mult = mult * HLRPG.BossDamageMultiplier end
    return mult
end

local function ScaleNPCDamage(npc, dmginfo)
    dmginfo:ScaleDamage(HLRPG.GetNPCDamageMultiplier(npc))
end

-- Scales pet damage by its stats. Returns true if the pet hit something on its owner's side.
local function HandlePetAttack(pet, target, dmginfo)
    local stats = pet.CurrentStats
    if stats then
        dmginfo:ScaleDamage(stats.dmgMultiplier + ((stats.level - 1) * 0.1))
    end

    return target:IsPlayer() or (target:IsNPC() and target:Disposition(pet.OwnerPly) == D_LI)
end

-- Returns true if the pet was hit by something on its owner's side
local function HandlePetHurt(pet, attacker)
    if IsValid(attacker) and (attacker:IsPlayer() or (attacker:IsNPC() and attacker:Disposition(pet.OwnerPly) == D_LI)) then
        return true
    end

    timer.Simple(0, function()
        if IsValid(pet) and IsValid(pet.OwnerPly) then
            pet.OwnerPly:SetNWInt("HLRPG_Pet_CurHP", pet:Health())
            pet.OwnerPly:SetNWInt("HLRPG_Pet_MaxHP", pet:GetMaxHealth())
        end
    end)
    return false
end

-- Damage share per player, used to split XP in sv_progression.lua
local function TrackDamage(npc, ply, dmginfo)
    npc.HLRPG_DamageTable = npc.HLRPG_DamageTable or {}
    local actualDmg = math.min(dmginfo:GetDamage(), npc:Health())
    npc.HLRPG_DamageTable[ply] = (npc.HLRPG_DamageTable[ply] or 0) + actualDmg
end

-- Player-side abilities (sh_abilities.lua): damage taken, then a chance to survive a lethal hit
local function HandlePlayerHurt(ply, attacker, dmginfo)
    ply.HLRPG_LastDamaged = CurTime()
    HLRPG.RunAbilityHook(ply, "OnTakeDamage", attacker, dmginfo)

    if ply.IsZombieForm or ply:Health() - dmginfo:GetDamage() > 0 then return false end
    return HLRPG.RunAbilityHook(ply, "OnLethalDamage", dmginfo) == true
end

hook.Add("EntityTakeDamage", "HLRPG_Combat_Master", function(target, dmginfo)
    if not IsValid(target) then return end
    local attacker = dmginfo:GetAttacker()
    local attackerIsPlayer = IsValid(attacker) and attacker:IsPlayer()

    if attackerIsPlayer and IsProtectedFromPlayer(target, attacker) then return Block(dmginfo) end

    if HLRPG.IsLeveledNPC(attacker) then ScaleNPCDamage(attacker, dmginfo) end

    if IsPet(attacker) and HandlePetAttack(attacker, target, dmginfo) then return Block(dmginfo) end
    if IsPet(target) and HandlePetHurt(target, attacker) then return Block(dmginfo) end

    if attackerIsPlayer then
        HLRPG.RunAbilityHook(attacker, "OnDealDamage", target, dmginfo)
        if target:IsNPC() then TrackDamage(target, attacker, dmginfo) end
    end

    if target:IsPlayer() and HandlePlayerHurt(target, attacker, dmginfo) then return true end
end)

hook.Add("EntityFireBullets", "HLRPG_Core_FireBullets", function(ply, data)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    HLRPG.RunAbilityHook(ply, "OnFireBullets", data)
    return true
end)
