-- hlrpg/core/sh_npcs.lua

-- Display name and tag color per NPC class
HLRPG.NPCNames = {
    ["npc_combine_s"] = { name = "Combine Soldier", color = Color(200, 200, 255) },
    ["npc_combine_e"] = { name = "Combine Elite", color = Color(255, 100, 100) },
    ["npc_metropolice"] = { name = "Civil Protection", color = Color(150, 200, 255) },
    ["npc_hunter"] = { name = "Hunter", color = Color(100, 150, 255) },
    ["npc_strider"] = { name = "Strider", color = Color(255, 200, 0) },
    ["npc_combinegunship"] = { name = "Combine Gunship", color = Color(255, 150, 0) },
    ["npc_helicopter"] = { name = "Attack Helicopter", color = Color(255, 150, 0) },
    ["npc_antlionguard"] = { name = "Antlion Guard", color = Color(0, 255, 150) },
    ["npc_antlion"] = { name = "Antlion", color = Color(200, 255, 100) },
    ["npc_antlion_worker"] = { name = "Antlion Worker", color = Color(100, 255, 100) },
    ["npc_zombie"] = { name = "Zombie", color = Color(255, 100, 100) },
    ["npc_zombie_torso"] = { name = "Zombie", color = Color(255, 100, 100) },
    ["npc_fastzombie"] = { name = "Fast Zombie", color = Color(255, 100, 100) },
    ["npc_fastzombie_torso"] = { name = "Fast Zombie", color = Color(255, 100, 100) },
    ["npc_poisonzombie"] = { name = "Poison Zombie", color = Color(100, 255, 100) },
    ["npc_zombine"] = { name = "Zombine", color = Color(150, 100, 255) },
    ["npc_headcrab"] = { name = "Headcrab", color = Color(200, 200, 200) },
    ["npc_headcrab_fast"] = { name = "Fast Headcrab", color = Color(255, 100, 100) },
    ["npc_headcrab_black"] = { name = "Poison Headcrab", color = Color(50, 255, 50) },
    ["npc_cscanner"] = { name = "Combine Scanner", color = Color(150, 150, 255) },
    ["npc_rollermine"] = { name = "Rollermine", color = Color(150, 150, 255) },
    ["npc_turret_floor"] = { name = "Turret", color = Color(255, 100, 100) },
    ["npc_monk"] = { name = "Father Grigori", color = Color(200, 200, 150) },
}

-- Base XP per kill, scaled by the NPC's level and split between everyone who damaged it.
-- The Combine Soldier (25) is the "standard enemy" the player level curve is measured in (sh_difficulty.lua).
-- Values follow threat: health, how dangerous the attack is, and whether the NPC respawns endlessly.
HLRPG.NPCXP = {
    -- Combine
    ["npc_combine_s"]        = 25,  -- 50 HP, ranged, grenades; also elites and prison guards
    ["npc_metropolice"]      = 15,
    ["npc_manhack"]          = 8,   -- arrives in swarms
    ["npc_cscanner"]         = 5,   -- harmless
    ["npc_rollermine"]       = 15,  -- needs the gravity gun
    ["npc_turret_floor"]     = 20,
    ["npc_stalker"]          = 5,   -- passive
    ["npc_hunter"]           = 150,

    -- Bosses
    ["npc_helicopter"]       = 600, -- one long fight
    ["npc_combinegunship"]   = 400,
    ["npc_strider"]          = 400,
    ["npc_antlionguard"]     = 250,

    -- Zombies
    ["npc_zombie"]           = 12,
    ["npc_zombie_torso"]     = 6,
    ["npc_fastzombie"]       = 18,
    ["npc_fastzombie_torso"] = 9,
    ["npc_poisonzombie"]     = 30,  -- 175 HP, throws poison headcrabs
    ["npc_zombine"]          = 40,

    -- Headcrabs
    ["npc_headcrab"]         = 4,
    ["npc_headcrab_fast"]    = 6,
    ["npc_headcrab_black"]   = 12,  -- poison drops you to 1 HP

    -- Antlions (thumper areas spawn them endlessly, so keep them cheap)
    ["npc_antlion"]          = 10,
    ["npc_antlion_worker"]   = 20,

    ["npc_barnacle"]         = 6,
}

HLRPG.DefaultXP = 10

-- Players cannot damage these
HLRPG.FriendlyNPCs = {
    ["npc_kleiner"] = true,
    ["npc_barney"] = true,
    ["npc_citizen"] = true,
    ["npc_alyx"] = true,
    ["npc_dog"] = true,
    ["npc_vortigaunt"] = true,
    ["npc_eli"] = true,
    ["npc_magnusson"] = true,
}

-- Shown on the boss HUD with boosted health and damage
HLRPG.BossNPCs = {
    ["npc_hunter"] = true,
    ["npc_combinegunship"] = true,
    ["npc_helicopter"] = true,
    ["npc_strider"] = true,
    ["npc_antlionguard"] = true,
    ["npc_combinedropship"] = true,
}

HLRPG.BossHealthMultiplier = 4.0
HLRPG.BossDamageMultiplier = 1.5
HLRPG.BossKillUltCharge = 50

function HLRPG.GetNPCName(ent)
    if not IsValid(ent) then return "Unknown" end
    local class = ent:GetClass()
    local info = HLRPG.NPCNames[class]
    return info and info.name or class:gsub("npc_", ""):upper()
end

function HLRPG.GetNPCColor(ent)
    local info = IsValid(ent) and HLRPG.NPCNames[ent:GetClass()]
    return info and info.color or Color(255, 255, 255)
end
