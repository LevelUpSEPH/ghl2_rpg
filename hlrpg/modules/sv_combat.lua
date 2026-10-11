-- hlrpg/modules/sv_combat.lua
-- Damage is handled in two passes:
--   1. The EntityTakeDamage hook only decides whether a hit is allowed (friendly fire, pets).
--   2. The final pass runs at the end of the gamemode's own EntityTakeDamage (wrapped on Initialize) and
--      applies every multiplier and ability. Running last means nothing the gamemode does to the damage
--      (Lambda sets fixed per-weapon / melee damage) can undo the scaling, whatever the attack type.

-- hlrpg_debug_damage (admin, toggles): report every hit a player takes, stage by stage, to chat and console
local debugDamage = false

concommand.Add("hlrpg_debug_damage", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    debugDamage = not debugDamage

    local msg = "[HLRPG DMG] Damage debug " .. (debugDamage and "ON" or "OFF")
    print(msg)
    if IsValid(ply) then ply:ChatPrint(msg) end
end)

local function IsPet(ent)
    return IsValid(ent) and ent.IsHLRPGPet and IsValid(ent.OwnerPly)
end

local function Block(dmginfo)
    dmginfo:SetDamage(0)
    return true
end

-- The NPC or player really behind a hit. Projectiles (grenades, Combine balls, rockets) are often the
-- attacker or inflictor themselves, with whoever fired them as their owner.
local function GetDamageSource(dmginfo)
    for _, ent in ipairs({ dmginfo:GetAttacker(), dmginfo:GetInflictor() }) do
        if IsValid(ent) then
            if ent:IsNPC() or ent:IsPlayer() then return ent end

            local owner = ent:GetOwner()
            if IsValid(owner) and (owner:IsNPC() or owner:IsPlayer()) then return owner end
        end
    end
    return dmginfo:GetAttacker()
end

-- Players can't hurt other players or friendly story NPCs
local function IsProtectedFromPlayer(target, ply)
    if target:IsPlayer() and target ~= ply then return true end
    return target:IsNPC() and HLRPG.FriendlyNPCs[target:GetClass()] == true
end

-- Whether a pet and another entity are on the same side (players, or NPCs that like the pet's owner)
local function IsPetAlly(pet, other)
    if not IsValid(other) then return false end
    return other:IsPlayer() or (other:IsNPC() and other:Disposition(pet.OwnerPly) == D_LI)
end

-- How much harder a leveled NPC hits (level, plus the boss bonus)
function HLRPG.GetNPCDamageMultiplier(npc)
    local mult = HLRPG.GetNPCLevelMultiplier("DMG", HLRPG.GetNPCLevel(npc))
    if npc:GetNWBool("HLRPG_IsBoss") then mult = mult * HLRPG.BossDamageMultiplier end
    return mult
end

local function GetPetDamageMultiplier(pet)
    local stats = pet.CurrentStats
    return stats and (stats.dmgMultiplier + ((stats.level - 1) * 0.1)) or 1
end

local function SyncPetHealth(pet)
    timer.Simple(0, function()
        if IsValid(pet) and IsValid(pet.OwnerPly) then
            pet.OwnerPly:SetNWInt("HLRPG_Pet_CurHP", pet:Health())
            pet.OwnerPly:SetNWInt("HLRPG_Pet_MaxHP", pet:GetMaxHealth())
        end
    end)
end

-- Damage share per player, used to split XP in sv_progression.lua
local function TrackDamage(npc, ply, dmginfo)
    npc.HLRPG_DamageTable = npc.HLRPG_DamageTable or {}
    local actualDmg = math.min(dmginfo:GetDamage(), npc:Health())
    npc.HLRPG_DamageTable[ply] = (npc.HLRPG_DamageTable[ply] or 0) + actualDmg
end

-- Player-side abilities (sh_abilities.lua): damage taken, then a chance to survive a lethal hit.
-- Health and armor are recorded first so AfterTakeDamage knows what the hit actually removed.
local function HandlePlayerHurt(ply, source, dmginfo)
    ply.HLRPG_LastDamaged = CurTime()
    ply.HLRPG_PreHit = { health = ply:Health(), armor = ply:Armor(), attacker = source }
    HLRPG.RunAbilityHook(ply, "OnTakeDamage", source, dmginfo)

    if ply.IsZombieForm or ply:Health() - dmginfo:GetDamage() > 0 then return false end
    return HLRPG.RunAbilityHook(ply, "OnLethalDamage", dmginfo) == true
end

-- Pass 1: is this hit allowed at all?
hook.Add("EntityTakeDamage", "HLRPG_Combat_Master", function(target, dmginfo)
    if not IsValid(target) then return end
    local source = GetDamageSource(dmginfo)

    if debugDamage and target:IsPlayer() then
        target.HLRPG_DebugHit = { raw = dmginfo:GetDamage(), source = source }
    end

    if IsValid(source) and source:IsPlayer() and IsProtectedFromPlayer(target, source) then return Block(dmginfo) end
    if IsPet(source) and IsPetAlly(source, target) then return Block(dmginfo) end
    if IsPet(target) and IsPetAlly(target, source) then return Block(dmginfo) end
end)

-- Pass 2: multipliers and abilities on the final damage. Returns true if the hit should be blocked.
local function ApplyFinalDamage(target, dmginfo)
    local source = GetDamageSource(dmginfo)
    local debugHit = target.HLRPG_DebugHit
    if debugHit then debugHit.afterGamemode = dmginfo:GetDamage() end

    if HLRPG.IsLeveledNPC(source) then dmginfo:ScaleDamage(HLRPG.GetNPCDamageMultiplier(source)) end
    if IsPet(source) then dmginfo:ScaleDamage(GetPetDamageMultiplier(source)) end

    if IsValid(source) and source:IsPlayer() then
        HLRPG.RunAbilityHook(source, "OnDealDamage", target, dmginfo)
        if target:IsNPC() then TrackDamage(target, source, dmginfo) end
    end

    if debugHit then debugHit.scaled = dmginfo:GetDamage() end

    if IsPet(target) then SyncPetHealth(target) end
    if target:IsPlayer() and HandlePlayerHurt(target, source, dmginfo) then return true end
    if debugHit then debugHit.final = dmginfo:GetDamage() end
end

hook.Add("Initialize", "HLRPG_CombatFinalPass", function()
    local gamemodeTakeDamage = GAMEMODE.EntityTakeDamage

    function GAMEMODE:EntityTakeDamage(target, dmginfo)
        if gamemodeTakeDamage and gamemodeTakeDamage(self, target, dmginfo) == true then return true end
        if IsValid(target) and ApplyFinalDamage(target, dmginfo) then return true end
    end
end)

local function PrintDebugHit(target, hit, healthLost, armorLost)
    local source = hit.source
    local who = IsValid(source) and source:GetClass() or "world"
    if HLRPG.IsLeveledNPC(source) then
        who = who .. string.format(" Lv%d x%.2f", HLRPG.GetNPCLevel(source), HLRPG.GetNPCDamageMultiplier(source))
    end

    -- "-" means that stage never ran for this hit (e.g. the final pass isn't installed)
    local function fmt(v) return v and string.format("%.1f", v) or "-" end
    local line = string.format("[HLRPG DMG] %s <- %s | raw %s > after gamemode %s > scaled %s > final %s | health -%s, armor -%s",
        target:Nick(), who, fmt(hit.raw), fmt(hit.afterGamemode), fmt(hit.scaled), fmt(hit.final),
        healthLost or "?", armorLost or "?")
    print(line)
    target:ChatPrint(line)
end

hook.Add("PostEntityTakeDamage", "HLRPG_AfterPlayerHurt", function(target, dmginfo, took)
    local debugHit = target.HLRPG_DebugHit
    target.HLRPG_DebugHit = nil

    local pre = target.HLRPG_PreHit
    if not pre then
        if debugHit then PrintDebugHit(target, debugHit) end
        return
    end
    target.HLRPG_PreHit = nil
    if not target:IsPlayer() then return end

    local healthLost = math.max(0, pre.health - target:Health())
    local armorLost = math.max(0, pre.armor - target:Armor())
    if debugHit then PrintDebugHit(target, debugHit, healthLost, armorLost) end
    if not target:Alive() then return end

    if healthLost > 0 or armorLost > 0 then
        HLRPG.RunAbilityHook(target, "AfterTakeDamage", pre.attacker, healthLost, armorLost)
    end
end)

hook.Add("EntityFireBullets", "HLRPG_Core_FireBullets", function(ply, data)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    HLRPG.RunAbilityHook(ply, "OnFireBullets", data)
    return true
end)
