-- hlrpg/core/sh_achievement_events.lua
-- What each map achievement event (fired by the maps' logic_achievement entities, see
-- entities/logic_achievement.lua) does. Handled by HLRPG.OnAchievementEvent in sv_achievements.lua.
--   "event" = "<achievement ID>"                          unlocks it (isGlobal decides who gets it)
--   { collection = "<counter>", item = "<id>" }           adds an item to the triggering player's collection
--   { challengeStart = "<id>", achievement = "<ach>" }     arms a challenge for everyone present
--   { challengeEnd = "<id>", achievement = "<ach>" }       awards everyone whose challenge is still armed

HLRPG.AchievementEvents = {
    -- Half-Life 2
    ["ACHIEVEMENT_EVENT_HL2_HIT_CANCOP_WITHCAN"] = "HL2_DEFIANT",
    ["ACHIEVEMENT_EVENT_HL2_PUT_CANINTRASH"] = "HL2_SUBMISSIVE",
    ["ACHIEVEMENT_EVENT_HL2_ESCAPE_APARTMENTRAID"] = "HL2_MALCONTENT",
    ["ACHIEVEMENT_EVENT_HL2_BREAK_MINITELEPORTER"] = "HL2_WHAT_CAT",
    ["ACHIEVEMENT_EVENT_HL2_GET_AIRBOAT"] = "HL2_ANCHORS_AWEIGH",
    ["ACHIEVEMENT_EVENT_HL2_GET_AIRBOATGUN"] = "HL2_HEAVY_WEAPONS",
    ["ACHIEVEMENT_EVENT_HL2_FIND_VORTIGAUNTCAVE"] = "HL2_VORTICOUGH",
    ["ACHIEVEMENT_EVENT_HL2_KILL_CHOPPER"] = "HL2_REVENGE",
    ["ACHIEVEMENT_EVENT_HL2_FIND_HEVFACEPLATE"] = "HL2_BLAST_FROM_PAST",
    ["ACHIEVEMENT_EVENT_HL2_GET_GRAVITYGUN"] = "HL2_ZERO_POINT_ENERGY",
    ["ACHIEVEMENT_EVENT_HL2_MAKEABASKET"] = "HL2_TWO_POINTS",
    ["ACHIEVEMENT_EVENT_HL2_BEAT_CEMETERY"] = "HL2_HALLOWED_GROUND",
    ["ACHIEVEMENT_EVENT_HL2_KILL_ENEMIES_WITHCRANE"] = "HL2_OSHA_VIOLATION",
    ["ACHIEVEMENT_EVENT_HL2_KILL_ODESSAGUNSHIP"] = "HL2_WHERE_CUBBAGE",
    ["ACHIEVEMENT_EVENT_HL2_PIN_SOLDIER_TOBILLBOARD"] = "HL2_TARGETTED_ADVERTISING",
    ["ACHIEVEMENT_EVENT_HL2_BEAT_DONTTOUCHSAND"] = "HL2_KEEP_OFF_SAND",
    ["ACHIEVEMENT_EVENT_HL2_BEAT_TURRETSTANDOFF2"] = "HL2_WARDEN_FREEMAN",
    ["ACHIEVEMENT_EVENT_HL2_FOLLOWFREEMAN"] = "HL2_FOLLOW_FREEMAN",
    ["ACHIEVEMENT_EVENT_HL2_BEAT_TOXICTUNNEL"] = "HL2_RADIATION_LEVELS",
    ["ACHIEVEMENT_EVENT_HL2_BEAT_PLAZASTANDOFF"] = "HL2_PLAZA_DEFENDER",
    ["ACHIEVEMENT_EVENT_HL2_KILL_ALLC1709SNIPERS"] = "HL2_COUNTER_SNIPER",
    ["ACHIEVEMENT_EVENT_HL2_BEAT_SUPRESSIONDEVICE"] = "HL2_FIGHT_THE_POWER",
    ["ACHIEVEMENT_EVENT_HL2_BEAT_C1713STRIDERSTANDOFF"] = "HL2_GIANT_KILLER",
    ["ACHIEVEMENT_EVENT_HL2_BEAT_GAME"] = "HL2_SINGULARITY_COLLAPSE",
    ["ACHIEVEMENT_EVENT_HL2_BEAT_RAVENHOLM_NOWEAPONS_START"] = { challengeStart = "ravenholm_gravgun", achievement = "HL2_ZOMBIE_CHOPPER" },
    ["ACHIEVEMENT_EVENT_HL2_BEAT_RAVENHOLM_NOWEAPONS_END"] = { challengeEnd = "ravenholm_gravgun", achievement = "HL2_ZOMBIE_CHOPPER" },

    -- Episode Two
    ["ACHIEVEMENT_EVENT_EP2_BEAT_ANTLIONINVASION"] = "EP2_INTO_THE_BREACH",
    ["ACHIEVEMENT_EVENT_EP2_BEAT_ANTLIONGUARDS"] = "EP2_TWOFER",
    ["ACHIEVEMENT_EVENT_EP2_BEAT_HUNTERAMBUSH"] = "EP2_MEET_THE_HUNTERS",
    ["ACHIEVEMENT_EVENT_EP2_KILL_COMBINECANNON"] = "EP2_GUNISHMENT",
    ["ACHIEVEMENT_EVENT_EP2_BEAT_ROCKETCACHEPUZZLE"] = "EP2_GORDON_PROPELLED_ROCKET",
    ["ACHIEVEMENT_EVENT_EP2_BEAT_WHITEFORESTINN"] = "EP2_QUIET_MOUNTAIN_GETAWAY",
    ["ACHIEVEMENT_EVENT_EP2_BEAT_RACEWITHDOG"] = "EP2_PEDAL_TO_THE_METAL",
    ["ACHIEVEMENT_EVENT_EP2_PUT_ITEMINROCKET"] = "EP2_LITTLE_ROCKET_MAN",
    ["ACHIEVEMENT_EVENT_EP2_BEAT_MISSILESILO2"] = "EP2_SECONDARY_SILO_SECURED",
    ["ACHIEVEMENT_EVENT_EP2_BEAT_OUTLAND12_NOBUILDINGSDESTROYED"] = "EP2_NEIGHBORHOOD_WATCH",
    ["ACHIEVEMENT_EVENT_EP2_BEAT_GAME"] = "EP2_DEFENSE_OF_THE_ARMAMENT",
    ["ACHIEVEMENT_EVENT_EP2_RADARCACHE_VAN"] = { collection = "ep2_radarcaches", item = "van" },
    ["ACHIEVEMENT_EVENT_EP2_RADARCACHE_SHACK"] = { collection = "ep2_radarcaches", item = "shack" },
    ["ACHIEVEMENT_EVENT_EP2_RADARCACHE_RPG"] = { collection = "ep2_radarcaches", item = "rpg" },
    ["ACHIEVEMENT_EVENT_EP2_RADARCACHE_CAVE"] = { collection = "ep2_radarcaches", item = "cave" },
    ["ACHIEVEMENT_EVENT_EP2_RADARCACHE_HANGING"] = { collection = "ep2_radarcaches", item = "hanging" },

    -- Episode One: its maps predate logic_achievement, so these come from HLRPG.MapInputEvents below
    ["HLRPG_EP1_ELEVATOR_SHAFT_BOTTOM"] = "EP1_WATCH_YOUR_HEAD",
    ["HLRPG_EP1_CORE_STARTED"] = { challengeStart = "ep1_pacifist", achievement = "EP1_PACIFIST" },
    ["HLRPG_EP1_CORE_CONTAINED"] = "EP1_CONTAINMENT",
    ["HLRPG_EP1_PACIFIST_END"] = { challengeEnd = "ep1_pacifist", achievement = "EP1_PACIFIST" },
    ["HLRPG_EP1_GARAGE_ELEVATOR"] = "EP1_ELEVATOR_ACTION",
    ["HLRPG_EP1_ESCORT_DONE"] = { challengeEnd = "ep1_citizen_escort", achievement = "EP1_CITIZEN_ESCORT" },
}

-- Episode One moments: when the named entity on that map receives the input, the event fires (sv_achievements.lua).
-- Found by reading the maps' entity data, like the Half-Life 2 events above.
HLRPG.MapInputEvents = {
    -- Chapter 2: the main elevator reaches the bottom of the shaft
    ep1_citadel_02b = {
        { name = "finale_rl", input = "Trigger", event = "HLRPG_EP1_ELEVATOR_SHAFT_BOTTOM" },
    },
    -- Chapter 2: the core sequence starts (stalkers wake), and later the core is contained
    ep1_citadel_03 = {
        { name = "relay_core_enable", input = "Trigger", event = "HLRPG_EP1_CORE_STARTED" },
        { name = "relay_core_completed", input = "Trigger", event = "HLRPG_EP1_CORE_CONTAINED" },
        { name = "relay_core_completed", input = "Trigger", event = "HLRPG_EP1_PACIFIST_END" },
    },
    -- Chapter 3: the player and Alyx are both in the garage elevator and its doors close
    ep1_c17_00a = {
        { name = "player_elev_clip", input = "Enable", event = "HLRPG_EP1_GARAGE_ELEVATOR" },
    },
    -- Chapter 5: the citizens are escorted and Barney heads for the last train
    ep1_c17_05 = {
        { name = "relay_barney_head_for_train", input = "Trigger", event = "HLRPG_EP1_ESCORT_DONE" },
    },
}

for i = 1, 9 do
    local item = string.format("%02d", i)
    HLRPG.AchievementEvents["ACHIEVEMENT_EVENT_EP2_WEBCACHE_" .. item] = { collection = "ep2_webcaches", item = item }
end

-- Lambda caches: event -> { saved cache ID, map it's on }. The IDs (L1-L45) are what player saves store.
HLRPG.LambdaMap = {
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_KLEINERSLAB"] = { id = "L1", map = "d1_trainstation_05" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_CANALSSTATION"] = { id = "L2", map = "d1_canals_01" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_VENTCRAWL"] = { id = "L3", map = "d1_canals_01" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_CANALSTUNNEL"] = { id = "L4", map = "d1_canals_01a" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_SEWERGRATE"] = { id = "L5", map = "d1_canals_02" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_STEAMPIPE"] = { id = "L6", map = "d1_canals_03" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_CURVEDROOM"] = { id = "L7", map = "d1_canals_05" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_SHANTYTOWN"] = { id = "L8", map = "d1_canals_05" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_TUNNELLADDER"] = { id = "L9", map = "d1_canals_06" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_REDBARN"] = { id = "L10", map = "d1_canals_06" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_ZOMBIEAMBUSH"] = { id = "L11", map = "d1_canals_06" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_BELOWAPCS"] = { id = "L12", map = "d1_canals_07" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_COUNTERWEIGHT"] = { id = "L13", map = "d1_canals_08" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_RAILWAYBRIDGE"] = { id = "L14", map = "d1_canals_08" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_TUNNELPLATFORMS"] = { id = "L15", map = "d1_canals_09" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_BANKEDCANAL"] = { id = "L16", map = "d1_canals_10" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_CANALWALL"] = { id = "L17", map = "d1_canals_10" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_CHANNELSPLIT"] = { id = "L18", map = "d1_canals_12" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_BMEDOCK"] = { id = "L19", map = "d1_eli_01" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_GENERATORS"] = { id = "L20", map = "d1_town_01" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_CARCRUSHERARENA"] = { id = "L21", map = "d1_town_01" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_RAVENHOLMATTIC"] = { id = "L22", map = "d1_town_01a" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_MINETUNNELEXIT"] = { id = "L23", map = "d1_town_05" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_COASTSHACK"] = { id = "L24", map = "d2_coast_01" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_POISONSHACK"] = { id = "L25", map = "d2_coast_03" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_GUNSHIPVAN"] = { id = "L26", map = "d2_coast_04" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_SUICIDECITIZEN"] = { id = "L27", map = "d2_coast_05" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_RAILROADSHACK"] = { id = "L28", map = "d2_coast_07" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_COASTABOVEBATTERY"] = { id = "L29", map = "d2_coast_09" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_SANDSHACK"] = { id = "L30", map = "d2_coast_11" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_GMANCACHE"] = { id = "L31", map = "d2_prison_02" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_CELLCACHE"] = { id = "L32", map = "d2_prison_03" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_POISONLAUNDRY"] = { id = "L33", map = "d2_prison_05" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_SODAMACHINE"] = { id = "L34", map = "d2_prison_06" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_STREETWARDOGWALL"] = { id = "L35", map = "d3_c17_02" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_STREETWARSHACK"] = { id = "L36", map = "d3_c17_04" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_STREETWARFENCE"] = { id = "L37", map = "d3_c17_05" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_FREEWAYTUNNEL"] = { id = "L38", map = "d3_c17_06a" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_DRAWBRIDGE"] = { id = "L39", map = "d3_c17_06b" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_PLAZAFENCE"] = { id = "L40", map = "d3_c17_06b" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_SEWERSCATWALKS"] = { id = "L41", map = "d3_c17_08" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_POISONZOMBIEALCOVE"] = { id = "L42", map = "d3_c17_08" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_PIPEHOPTUNNEL"] = { id = "L43", map = "d3_c17_08" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_EXITCATWALK"] = { id = "L44", map = "d3_c17_08" },
    ["ACHIEVEMENT_EVENT_HL2_LAMDACACHE_ENDOFC1712B"] = { id = "L45", map = "d3_c17_12b" },
}
