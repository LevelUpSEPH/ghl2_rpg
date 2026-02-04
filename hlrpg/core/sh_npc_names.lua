-- addons/halflife_rpg/lua/hlrpg/config/sh_npc_names.lua

HLRPG_NPC_Configs = {
    ["npc_combine_s"] = { "Combine Soldier", Color(200, 200, 255) },
    ["npc_combine_e"] = { "Combine Elite", Color(255, 100, 100) },
    ["npc_metropolice"] = { "Civil Protection", Color(150, 200, 255) },
    ["npc_hunter"] = { "Hunter", Color(100, 150, 255) },
    ["npc_strider"] = { "Strider", Color(255, 200, 0) },
    ["npc_combinegunship"] = { "Combine Gunship", Color(255, 150, 0) },
    ["npc_helicopter"] = { "Attack Helicopter", Color(255, 150, 0) },
    ["npc_antlionguard"] = { "Antlion Guard", Color(0, 255, 150) },
    ["npc_antlion"] = { "Antlion", Color(200, 255, 100) },
    ["npc_antlion_worker"] = { "Antlion Worker", Color(100, 255, 100) },
    ["npc_zombie"] = { "Zombie", Color(255, 100, 100) },
    ["npc_zombie_torso"] = { "Zombie", Color(255, 100, 100) },
    ["npc_fastzombie"] = { "Fast Zombie", Color(255, 100, 100) },
    ["npc_fastzombie_torso"] = { "Fast Zombie", Color(255, 100, 100) },
    ["npc_poisonzombie"] = { "Poison Zombie", Color(100, 255, 100) },
    ["npc_zombine"] = { "Zombine", Color(150, 100, 255) },
    ["npc_headcrab"] = { "Headcrab", Color(200, 200, 200) },
    ["npc_headcrab_fast"] = { "Fast Headcrab", Color(255, 100, 100) },
    ["npc_headcrab_black"] = { "Poison Headcrab", Color(50, 255, 50) },
    ["npc_cscanner"] = { "Combine Scanner", Color(150, 150, 255) },
    ["npc_rollermine"] = { "Rollermine", Color(150, 150, 255) },
    ["npc_turret_floor"] = { "Turret", Color(255, 100, 100) },
    ["npc_monk"] = { "Father Grigori", Color(200, 200, 150) },
}

function HLRPG_GetNPCName(ent)
    if not IsValid(ent) then return "Unknown" end
    local class = ent:GetClass()
    return (HLRPG_NPC_Configs[class] and HLRPG_NPC_Configs[class][1]) or class:gsub("npc_", ""):upper()
end

function HLRPG_GetNPCColor(ent)
    if not IsValid(ent) then return Color(255, 255, 255) end
    local class = ent:GetClass()
    return (HLRPG_NPC_Configs[class] and HLRPG_NPC_Configs[class][2]) or Color(255, 255, 255)
end