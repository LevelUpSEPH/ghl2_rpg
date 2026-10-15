-- hlrpg/modules/custom_achievement_listeners/sv_episode_one.lua
-- Episode One achievements Valve detected in game code. The map moments (Watch Your Head!, Containment,
-- Elevator Action, and the ends of the Pacifist and Citizen Escort challenges) come from HLRPG.MapInputEvents.
-- Every check only runs on the map(s) its achievement belongs to.

-- Where each check counts
local MAPS = {
    attica = "ep1_c17_02a",        -- the hospital attic gunship
    pacifist = "ep1_citadel_03",   -- the core and its stalkers
    escort = "ep1_c17_05",         -- the citizens heading for the train
    liveBait = "ep1_c17_01",       -- Alyx's sniper position
    bulletStart = "ep1_citadel_00", -- Episode One's first map
}

local function OnEpisodeOne() return string.StartWith(game.GetMap():lower(), "ep1_") end

-- A challenge that fails for one player fails for the whole group
local function FailForEveryone(challenge, achID)
    for _, ply in ipairs(player.GetAll()) do HLRPG.FailChallenge(ply, challenge, achID) end
end

-- The player behind a kill: the attacker, or whoever last held the object with the Gravity Gun or +use
local function GetKiller(attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() then return attacker end
    if IsValid(inflictor) and IsValid(inflictor.HLRPG_LastHolder) then return inflictor.HLRPG_LastHolder end
end

hook.Add("OnPlayerPhysicsPickup", "HLRPG_EP1_Holder", function(ply, ent) ent.HLRPG_LastHolder = ply end)

-- Energy balls remember who fired them (an Elite), before a player catches and returns them
hook.Add("OnEntityCreated", "HLRPG_EP1_BallOrigin", function(ent)
    if ent:GetClass() ~= "prop_combine_ball" then return end
    timer.Simple(0, function()
        if IsValid(ent) then ent.HLRPG_OriginalOwner = ent:GetOwner() end
    end)
end)

local function IsElite(npc)
    return npc:GetClass() == "npc_combine_s" and string.find(string.lower(npc:GetModel() or ""), "super_soldier", 1, true) ~= nil
end

local ZOMBIES = {
    npc_zombie = true, npc_zombie_torso = true, npc_fastzombie = true, npc_fastzombie_torso = true,
    npc_poisonzombie = true, npc_zombine = true,
}

hook.Add("OnNPCKilled", "HLRPG_EP1_Kills", function(npc, attacker, inflictor)
    if not IsValid(npc) or not OnEpisodeOne() then return end
    local class, map = npc:GetClass(), game.GetMap():lower()
    local killer = GetKiller(attacker, inflictor)
    local inflictorClass = IsValid(inflictor) and inflictor:GetClass() or ""

    -- Attica!: the gunship in the hospital attic, however it goes down
    if map == MAPS.attica and npc:GetName() == "gunship_showdown" then
        HLRPG.AwardAchievementToAll("EP1_ATTICA")
    end

    -- Pacifist: any player killing a stalker during the core sequence fails it for everyone
    if map == MAPS.pacifist and class == "npc_stalker" and IsValid(killer) then
        FailForEveryone("ep1_pacifist", "EP1_PACIFIST")
    end

    -- Citizen Escort: any citizen dying on the escort map fails it for everyone
    if map == MAPS.escort and class == "npc_citizen" then
        FailForEveryone("ep1_citizen_escort", "EP1_CITIZEN_ESCORT")
    end

    -- Live Bait: Alyx's sniper position (an npc_sniper named sniper_alyx) counts for everyone present
    if map == MAPS.liveBait and IsValid(attacker) and attacker:GetClass() == "npc_sniper" and attacker:GetName() == "sniper_alyx" then
        for _, ply in ipairs(player.GetAll()) do HLRPG.AddCounter(ply, "ep1_alyx_snipes") end
    end

    if inflictorClass == "prop_combine_ball" then
        -- Think Fast!: an Elite killed by the energy ball he fired
        if IsValid(killer) and IsElite(npc) and inflictor.HLRPG_OriginalOwner == npc then
            HLRPG.AwardAchievement(killer, "EP1_THINK_FAST")
        end
        -- Conservationist: five kills with the same ball
        inflictor.HLRPG_BallKills = (inflictor.HLRPG_BallKills or 0) + 1
        if IsValid(killer) and inflictor.HLRPG_BallKills >= 5 then
            HLRPG.AwardAchievement(killer, "EP1_CONSERVATIONIST")
        end
    end

    -- Car Crusher: antlions squashed with a thrown car
    if IsValid(killer) and (class == "npc_antlion" or class == "npc_antlion_worker")
        and string.StartWith(inflictorClass, "prop_physics")
        and string.find(string.lower(inflictor:GetModel() or ""), "props_vehicles/car", 1, true) then
        HLRPG.AddCounter(killer, "ep1_car_crushes")
    end
end)

-- Zombie-que: flares set zombies alight on touch without dealing damage, so burning zombies near a flare are
-- checked twice a second on Episode One maps, credited to whoever last carried that flare
timer.Create("HLRPG_EP1_ZombieQue", 0.5, 0, function()
    if not OnEpisodeOne() then return end
    for _, flare in ipairs(ents.FindByClass("env_flare")) do
        local holder = flare.HLRPG_LastHolder
        if IsValid(holder) then
            for _, ent in ipairs(ents.FindInSphere(flare:GetPos(), 96)) do
                if ZOMBIES[ent:GetClass()] and ent:IsOnFire() and not ent.HLRPG_Flared then
                    ent.HLRPG_Flared = true
                    HLRPG.AddCounter(holder, "ep1_flared_zombies")
                end
            end
        end
    end
end)

-- Challenges that start when a player loads into a map:
--   Citizen Escort on the escort map; The One Free Bullet on Episode One's first map, for the whole campaign
hook.Add("HLRPG_PlayerDataLoaded", "HLRPG_EP1_Challenges", function(ply)
    local map = game.GetMap():lower()
    if map == MAPS.escort and not HLRPG.IsChallengeActive(ply, "ep1_citizen_escort") then
        HLRPG.StartChallenge("ep1_citizen_escort", "EP1_CITIZEN_ESCORT", { ply })
    elseif map == MAPS.bulletStart then
        ply.HLRPG_Counters.ep1_bullets_fired = 0
        HLRPG.StartChallenge("ep1_one_bullet", "EP1_ONE_FREE_BULLET", { ply })
    end
end)

-- The One Free Bullet: every shot from a bullet weapon counts (rockets, grenades, melee and props don't)
hook.Add("HLRPG_PlayerFiredBullets", "HLRPG_EP1_OneBullet", function(ply)
    if not HLRPG.IsChallengeActive(ply, "ep1_one_bullet") then return end

    ply.HLRPG_Counters.ep1_bullets_fired = (ply.HLRPG_Counters.ep1_bullets_fired or 0) + 1
    if ply.HLRPG_Counters.ep1_bullets_fired > 1 then
        HLRPG.FailChallenge(ply, "ep1_one_bullet", "EP1_ONE_FREE_BULLET")
    elseif ply.HLRPG_Counters.ep1_bullets_fired == 1 then
        ply:SaveCounters() -- so a map change doesn't forget it
        ply:ChatPrint("[ACH] The One Free Bullet: that was your one bullet.")
    end
end)

hook.Add("HLRPG_CampaignCompleted", "HLRPG_EP1_OneBulletEnd", function(campaignID)
    if campaignID == "ep1" then HLRPG.EndChallenge("ep1_one_bullet", "EP1_ONE_FREE_BULLET") end
end)
