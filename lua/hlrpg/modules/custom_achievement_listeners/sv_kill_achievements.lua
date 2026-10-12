-- hlrpg/modules/custom_achievement_listeners/sv_kill_achievements.lua
-- Achievements the original games detected in code rather than through map events: what killed what, with what.

local function IsEnemyNPC(ent)
    return IsValid(ent) and ent:IsNPC() and not ent.IsHLRPGPet and not HLRPG.FriendlyNPCs[ent:GetClass()]
end

-- The player behind a kill; a vehicle counts as its driver
local function GetKiller(attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() then return attacker end

    for _, ent in ipairs({ attacker, inflictor }) do
        if IsValid(ent) and ent:IsVehicle() and IsValid(ent:GetDriver()) then return ent:GetDriver() end
    end
end

-- hlrpg_debug_kills (admin, toggles): print what GMod reports for every NPC death
local debugKills = false

concommand.Add("hlrpg_debug_kills", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    debugKills = not debugKills

    local msg = "[HLRPG KILL] Kill debug " .. (debugKills and "ON" or "OFF")
    print(msg)
    if IsValid(ply) then ply:ChatPrint(msg) end
end)

local function Describe(ent)
    if not IsValid(ent) then return "none" end
    return ent:IsPlayer() and ent:Nick() or ent:GetClass()
end

-- Grenades remember who first held them (a soldier or a Zombine); throwing one back makes the player its
-- thrower, so the original owner has to be noted when the grenade appears
local function GetGrenadeOwner(grenade)
    local thrower = grenade:GetInternalVariable("m_hThrower")
    if IsValid(thrower) then return thrower end
    if IsValid(grenade:GetOwner()) then return grenade:GetOwner() end
    return grenade:GetParent()
end

hook.Add("OnEntityCreated", "HLRPG_GrenadeOrigin", function(ent)
    if ent:GetClass() ~= "npc_grenade_frag" then return end
    timer.Simple(0, function()
        if IsValid(ent) then ent.HLRPG_OriginalOwner = GetGrenadeOwner(ent) end
    end)
end)

-- Whoever last grabbed or punted something with the Gravity Gun gets credit for what happens to it
hook.Add("GravGunPunt", "HLRPG_GravGunHolder", function(ply, ent)
    ent.HLRPG_LastHolder = ply
end)

-- A supercharged punt kills the soldier first; his body inherits the credit
hook.Add("CreateEntityRagdoll", "HLRPG_GravGunHolder", function(owner, ragdoll)
    if IsValid(owner) and owner.HLRPG_LastHolder then ragdoll.HLRPG_LastHolder = owner.HLRPG_LastHolder end
end)

-- Atomizer: a soldier's body dissolving after a player threw it (the Citadel's Combine ball fields).
-- Dissolving spawns an env_entity_dissolver attached to the body, so only that moment is checked.
local SOLDIER_MODELS = { "models/combine_soldier", "models/combine_super_soldier" }

local function IsSoldierBody(ent)
    if not IsValid(ent) or ent:GetClass() ~= "prop_ragdoll" then return false end
    local model = string.lower(ent:GetModel() or "")
    for _, prefix in ipairs(SOLDIER_MODELS) do
        if string.StartWith(model, prefix) then return true end
    end
    return false
end

hook.Add("OnEntityCreated", "HLRPG_Atomizer", function(ent)
    if ent:GetClass() ~= "env_entity_dissolver" then return end
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        local body = ent:GetParent()
        if not IsSoldierBody(body) or body.HLRPG_Atomized or not IsValid(body.HLRPG_LastHolder) then return end

        body.HLRPG_Atomized = true
        HLRPG.AddCounter(body.HLRPG_LastHolder, "atomized_soldiers")
    end)
end)

-- Grave Robber: pulling a Zombine's grenade away with the Gravity Gun
hook.Add("GravGunOnPickedUp", "HLRPG_GraveRobber", function(ply, ent)
    ent.HLRPG_LastHolder = ply
    if ent:GetClass() ~= "npc_grenade_frag" then return end

    local owner = ent.HLRPG_OriginalOwner
    if IsValid(owner) and owner:GetClass() == "npc_zombine" then
        HLRPG.AwardAchievement(ply, "EP1_GRAVE_ROBBER")
    end
end)

hook.Add("OnNPCKilled", "HLRPG_KillAchievements", function(npc, attacker, inflictor)
    if not IsValid(npc) then return end
    local class = npc:GetClass()
    local killer = GetKiller(attacker, inflictor)
    local inflictorClass = IsValid(inflictor) and inflictor:GetClass() or ""

    if debugKills then
        local msg = string.format("[HLRPG KILL] %s killed by %s with %s -> credited to %s",
            class, Describe(attacker), Describe(inflictor), Describe(killer))
        print(msg)
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsAdmin() then ply:ChatPrint(msg) end
        end
    end

    -- Bug Hunt: antlions on the players' side (bugbait) killing enemies count for everyone present
    if IsValid(attacker) and attacker:GetClass() == "npc_antlion" and class ~= "npc_antlion" then
        local first = player.GetAll()[1]
        if IsValid(first) and attacker:Disposition(first) == D_LI then
            for _, ply in ipairs(player.GetAll()) do HLRPG.AddCounter(ply, "antlion_assists") end
        end
    end

    -- Hot Potat0wned: a soldier killed by the grenade he brought, thrown back by a player
    if class == "npc_combine_s" and inflictorClass == "npc_grenade_frag" and inflictor.HLRPG_OriginalOwner == npc then
        local thrower = killer or inflictor.HLRPG_LastHolder
        if IsValid(thrower) then HLRPG.AwardAchievement(thrower, "EP2_HOT_POTATOWNED") end
    end

    if not killer then return end

    if class == "npc_combinegunship" then HLRPG.AddCounter(killer, "gunship_kills") end
    if class == "npc_antlion_worker" then HLRPG.AwardAchievement(killer, "EP2_ACID_REFLEX") end

    if class == "npc_hunter" and inflictorClass == "hunter_flechette" and not inflictor.HLRPG_PlayerFired then
        HLRPG.AwardAchievement(killer, "EP2_PAYBACK")
    end

    if inflictorClass == "combine_mine" then HLRPG.AwardAchievement(killer, "EP2_DEADLY_HARVEST") end

    local byVehicle = (IsValid(inflictor) and inflictor:IsVehicle()) or (IsValid(attacker) and attacker:IsVehicle())
    if byVehicle and IsEnemyNPC(npc) then HLRPG.AddCounter(killer, "vehicle_kills") end

    if string.StartWith(inflictorClass, "prop_physics") then
        HLRPG.AddCounter(killer, "physics_kills")
        if string.find(string.lower(inflictor:GetModel() or ""), "toilet", 1, true) then
            HLRPG.AwardAchievement(killer, "HL2_FLUSHED")
        end
    end
end)

-- Zombie Chopper: hurting an enemy with anything but the Gravity Gun fails the Ravenholm challenge
-- (the challenge itself is started and finished by map events, see sh_achievement_events.lua)
hook.Add("EntityTakeDamage", "HLRPG_ZombieChopperCheck", function(target, dmginfo)
    local ply = dmginfo:GetAttacker()
    if not IsValid(ply) or not ply:IsPlayer() or not IsEnemyNPC(target) then return end
    if not HLRPG.IsChallengeActive(ply, "ravenholm_gravgun") then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_physcannon" then
        HLRPG.FailChallenge(ply, "ravenholm_gravgun", "HL2_ZOMBIE_CHOPPER")
    end
end)
