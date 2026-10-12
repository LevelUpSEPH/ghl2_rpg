-- hlrpg/core/sh_achievements.lua
-- category: the menu tab (HLRPG.AchievementCategories below), "hl2" if not set.
-- sort: optional sort key within the tab (defaults to the name).
-- counter + goal: a progress achievement, unlocked when that per-player counter reaches the goal.
-- isGlobal: everyone on the server gets it when it triggers. Map triggers live in sh_achievement_events.lua.
-- kills: the XP reward, in standard kills at the player's level (HLRPG.GetKillEquivalentXP):
--   8 story beat, 10 chapter end, 20 secret/trick, 30 boss, 60 chapter-long challenge, 165 collect everything

HLRPG.Achievements = {
    ["HL2_DEFIANT"] = {
        name = "Defiant",
        desc = "Go against norms",
        kills = 8,
        icon = "resources/icons/achievements/hl2_defiant.png",
        isGlobal = true
    },
    ["HL2_SUBMISSIVE"] = {
        name = "Submissive",
        desc = "Good boy",
        kills = 8,
        icon = "resources/icons/achievements/hl2_submissive.png",
        isGlobal = true
    },
    ["HL2_MALCONTENT"] = {
        name = "Malcontent",
        desc = "Close call",
        kills = 8,
        icon = "resources/icons/achievements/hl2_malcontent.png",
        isGlobal = true
    },
    ["HL2_WHAT_CAT"] = {
        name = "What Cat?",
        desc = "Good job, electrician",
        kills = 8,
        icon = "resources/icons/achievements/hl2_what_cat.png",
        isGlobal = true
    },
    ["HL2_TRUSTY_HARDWARE"] = {
        name = "Trusty Hardware",
        desc = "Right hand man achieved",
        kills = 8,
        icon = "resources/icons/achievements/hl2_trusty_hardware.png"
    },
    ["HL2_BARNACLE_BOWLING"] = {
        name = "Barnacle Bowling",
        desc = "Use barnacles to your advantage",
        kills = 20,
        icon = "resources/icons/achievements/hl2_barnacle_bowling.png",
        isGlobal = true
    },
    ["HL2_VORTICOUGH"] = {
        name = "Vorticough",
        desc = "Knowing it all doesnt mean you can sing.",
        kills = 20,
        isGlobal = true
    },
    ["HL2_KEEP_OFF_SAND"] = {
        name = "Keep Off The Sand",
        desc = "Avoid the sand traps",
        kills = 60,
        rewardItem = "pet_antlion",
        isGlobal = true
    },
    ["HL2_LAMBDA_LOCATOR"] = {
        name = "Lambda Locator",
        desc = "Find all lambda caches",
        kills = 500,
        isGlobal = false
    },
    ["HL2_ANCHORS_AWEIGH"] = {
        name = "Anchors Aweigh",
        desc = "Ride the boat",
        kills = 8,
        isGlobal = true
    },
    ["HL2_HEAVY_WEAPONS"] = {
        name = "Heavy Weapons",
        desc = "Get the mounted gun",
        kills = 8,
        isGlobal = true
    },
    ["HL2_REVENGE"] = {
        name = "Revenge",
        desc = "Defeat the Chopper",
        kills = 30,
        rewardItem = "hat_helibomb",
        isGlobal = true
    },
    ["HL2_ZERO_POINT_ENERGY"] = {
        name = "Zero Point Energy",
        desc = "Gravity gun acquired",
        kills = 8,
        isGlobal = true
    },
    ["HL2_BLAST_FROM_PAST"] = {
        name = "Blast From The Past",
        desc = "Use the old HEV suit charger",
        kills = 20,
        isGlobal = true
    },
    ["HL2_TWO_POINTS"] = {
        name = "Two Points",
        desc = "Score a basket with the rollermine",
        kills = 20,
        isGlobal = true
    },
    ["HL2_HALLOWED_GROUND"] = {
        name = "Hallowed Ground",
        desc = "Reach the graveyard",
        kills = 10,
        isGlobal = true
    },
}

-- Half-Life 2 (map events in sh_achievement_events.lua unless noted)
local HL2_MORE = {
    HL2_OSHA_VIOLATION = { name = "OSHA Violation", desc = "Kill 3 enemies using the crane", kills = 20 },
    HL2_WHERE_CUBBAGE = { name = "Where Cubbage Fears to Tread", desc = "Defend Little Odessa from the gunship attack", kills = 30 },
    HL2_TARGETTED_ADVERTISING = { name = "Targetted Advertising", desc = "Pin a soldier to the billboard in Highway 17", kills = 20 },
    HL2_WARDEN_FREEMAN = { name = "Warden Freeman", desc = "Survive the second turret standoff in Nova Prospekt", kills = 20 },
    HL2_FOLLOW_FREEMAN = { name = "Follow Freeman", desc = "Gain command of a squad of rebels in the uprising", kills = 8 },
    HL2_RADIATION_LEVELS = { name = "Radiation Levels Detected", desc = "Get through the toxic tunnel under City 17", kills = 10 },
    HL2_PLAZA_DEFENDER = { name = "Plaza Defender", desc = "Survive the generator plaza standoff in Anticitizen One", kills = 20 },
    HL2_COUNTER_SNIPER = { name = "Counter-Sniper", desc = "Kill all of the snipers in City 17", kills = 20 },
    HL2_FIGHT_THE_POWER = { name = "Fight the Power", desc = "Shut down the suppression device by disabling its generators", kills = 20 },
    HL2_GIANT_KILLER = { name = "Giant Killer", desc = "Survive the rooftop strider battle in the ruins of City 17", kills = 30 },
    HL2_SINGULARITY_COLLAPSE = { name = "Singularity Collapse", desc = "Destroy the Citadel's reactor core", kills = 60 },
    HL2_ZOMBIE_CHOPPER = { name = "Zombie Chopper", desc = "Play through Ravenholm using only the Gravity Gun", kills = 60, rewardItem = "hat_headcrab" },
    -- Kill checks (custom_achievement_listeners/sv_kill_achievements.lua)
    HL2_ONE_MAN_ARMY = { name = "One Man Army", desc = "Destroy six gunships", kills = 30, counter = "gunship_kills", goal = 6, isGlobal = false },
    HL2_FLUSHED = { name = "Flushed", desc = "Kill an enemy with a toilet", kills = 20, isGlobal = false },
    HL2_BUG_HUNT = { name = "Bug Hunt", desc = "Use the antlions to kill 50 enemies", kills = 20, counter = "antlion_assists", goal = 50 },
    HL2_ATOMIZER = { name = "Atomizer", desc = "Disintegrate 15 soldiers by throwing them into a Combine ball field", kills = 30, counter = "atomized_soldiers", goal = 15, isGlobal = false, rewardItem = "upg_dissolver_ar2" },
}

-- Episode One
local EP1 = {
    -- Awarded when Episode One's ending credits roll (sv_achievements.lua)
    EP1_ESCAPE_FROM_CITY_17 = { name = "Escape From City 17", desc = "Escape City 17 with Alyx", kills = 60, completeCampaign = "ep1" },
    -- Grenade checks (custom_achievement_listeners/sv_kill_achievements.lua)
    EP1_GRAVE_ROBBER = { name = "Grave Robber", desc = "Steal a Zombine's grenade", kills = 10, isGlobal = false },
}

-- Episode Two
local EP2 = {
    EP2_INTO_THE_BREACH = { name = "Into the Breach", desc = "Help Griggs and Sheckley hold off the antlion invasion inside the mine shaft", kills = 20 },
    EP2_TWOFER = { name = "Twofer", desc = "Defeat both antlion guards outside the White Forest", kills = 30 },
    EP2_MEET_THE_HUNTERS = { name = "Meet the Hunters", desc = "Survive the Hunter ambush with Alyx", kills = 20 },
    EP2_GUNISHMENT = { name = "Gunishment!", desc = "Destroy the Combine Autogun in the junkyard", kills = 30 },
    EP2_GORDON_PROPELLED_ROCKET = { name = "Gordon Propelled Rocket", desc = "Unlock the rocket launcher lambda cache in Under the Radar", kills = 20 },
    EP2_QUIET_MOUNTAIN_GETAWAY = { name = "Quiet Mountain Getaway", desc = "Survive the ambush at the White Forest Inn", kills = 20 },
    EP2_PEDAL_TO_THE_METAL = { name = "Pedal to the Metal", desc = "Beat DOG in a race to the White Forest base", kills = 20 },
    EP2_LITTLE_ROCKET_MAN = { name = "Little Rocket Man", desc = "Send the garden gnome into space", kills = 60, rewardItem = "hat_gnome" },
    EP2_SECONDARY_SILO_SECURED = { name = "Secondary Silo Secured", desc = "Secure the launch doors on missile silo 2", kills = 20 },
    EP2_NEIGHBORHOOD_WATCH = { name = "Neighborhood Watch", desc = "Save all buildings outside the missile silo from destruction", kills = 30 },
    EP2_DEFENSE_OF_THE_ARMAMENT = { name = "Defense of the Armament", desc = "Save the missile silo from the Combine offensive", kills = 60 },
    -- Collections: one item per map event, per player
    EP2_PINATA_PARTY = { name = "Pinata Party", desc = "Find and break every web cache", kills = 20, counter = "ep2_webcaches", goal = 9, isGlobal = false },
    EP2_CACHE_CHECKER = { name = "Cache Checker", desc = "Find every radar cache in Under the Radar", kills = 20, counter = "ep2_radarcaches", goal = 5, isGlobal = false },
    -- Kill checks (custom_achievement_listeners/sv_kill_achievements.lua)
    EP2_ACID_REFLEX = { name = "Acid Reflex", desc = "Kill an acid antlion worker", kills = 8, isGlobal = false },
    EP2_HIT_AND_RUN = { name = "Hit and Run", desc = "Run over 20 enemies with a vehicle", kills = 20, counter = "vehicle_kills", goal = 20, isGlobal = false },
    EP2_PAYBACK = { name = "Payback", desc = "Kill a Hunter with its own flechettes", kills = 20, isGlobal = false },
    EP2_BONE_BREAKER = { name = "Bone Breaker", desc = "Kill 30 enemies with thrown physics objects", kills = 20, counter = "physics_kills", goal = 30, isGlobal = false },
    EP2_DEADLY_HARVEST = { name = "Deadly Harvest", desc = "Kill an enemy with a hopper mine", kills = 10, isGlobal = false },
    EP2_HOT_POTATOWNED = { name = "Hot Potat0wned", desc = "Kill a Combine soldier with his own grenade", kills = 10, isGlobal = false },
    -- Shared by everyone present, reset with the campaign run (custom_achievement_listeners/sv_grubs.lua)
    EP2_GET_SOME_GRUB = { name = "Get Some Grub", desc = "Squish every antlion grub in one Episode Two run", kills = 400, counter = "ep2_grubs", goal = 333, isGlobal = false, rewardItem = "hat_grub" },
}

-- Story and map achievements are shared by everyone present unless marked isGlobal = false
for category, list in pairs({ hl2 = HL2_MORE, ep1 = EP1, ep2 = EP2 }) do
    for id, ach in pairs(list) do
        ach.category = category
        if ach.isGlobal == nil then ach.isGlobal = true end
        HLRPG.Achievements[id] = ach
    end
end

-- XP for each lambda cache found, in standard kills at the player's level
HLRPG.LambdaCacheKills = 5

-- Menu tabs, in order
HLRPG.AchievementCategories = {
    { id = "hl2", name = "Half-Life 2" },
    { id = "ep1", name = "Episode One" },
    { id = "ep2", name = "Episode Two" },
    { id = "general", name = "General" },
}

-- General: progress achievements (counters are fed by custom_achievement_listeners/sv_counters.lua)

HLRPG.Achievements["GEN_DEATHS_50"] = {
    name = "Persistence",
    desc = "Die 50 times",
    category = "general",
    sort = "1",
    counter = "deaths", goal = 50,
    kills = 10,
}

-- Enemy groups for the kill achievements. rewards = { [goal] = itemID } gives an item with that tier.
HLRPG.KillCounterGroups = {
    zombie = { name = "Zombie", plural = "zombies", classes = {
        "npc_zombie", "npc_zombie_torso", "npc_fastzombie", "npc_fastzombie_torso", "npc_poisonzombie", "npc_zombine",
    } },
    combine = { name = "Combine", plural = "Combine", classes = {
        "npc_combine_s", "npc_metropolice", "npc_manhack", "npc_cscanner", "npc_clawscanner", "npc_rollermine",
        "npc_turret_floor", "npc_hunter", "npc_strider", "npc_combinegunship", "npc_helicopter",
    }, rewards = { [250] = "hat_metrocop" } },
    antlion = { name = "Antlion", plural = "antlions", classes = {
        "npc_antlion", "npc_antlion_worker", "npc_antlionguard",
    } },
    headcrab = { name = "Headcrab", plural = "headcrabs", classes = {
        "npc_headcrab", "npc_headcrab_fast", "npc_headcrab_black", "npc_headcrab_poison",
    } },
}

local KILL_TIERS = {
    { goal = 50, kills = 10, numeral = "I" },
    { goal = 250, kills = 30, numeral = "II" },
    { goal = 1000, kills = 80, numeral = "III" },
}

for groupID, group in pairs(HLRPG.KillCounterGroups) do
    for _, tier in ipairs(KILL_TIERS) do
        HLRPG.Achievements["GEN_KILLS_" .. groupID:upper() .. "_" .. tier.goal] = {
            name = group.name .. " Hunter " .. tier.numeral,
            desc = "Kill " .. tier.goal .. " " .. group.plural,
            category = "general",
            sort = string.format("2 %s %04d", group.name, tier.goal),
            counter = "kills_" .. groupID, goal = tier.goal,
            kills = tier.kills,
            rewardItem = group.rewards and group.rewards[tier.goal],
        }
    end
end

-- Icons: an achievement without an explicit icon uses materials/resources/icons/achievements/<id>.jpg if it
-- exists (Valve's official icons, downloaded from Steam). sv_resources.lua sends them to joining players.
for id, ach in pairs(HLRPG.Achievements) do
    local path = "resources/icons/achievements/" .. string.lower(id) .. ".jpg"
    if not ach.icon and file.Exists("materials/" .. path, "GAME") then ach.icon = path end
end
