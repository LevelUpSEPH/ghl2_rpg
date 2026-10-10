-- hlrpg/core/sh_difficulty.lua
-- World difficulty only decides which levels NPCs spawn at. Everything an NPC's level affects
-- (health, damage, XP reward) comes from HLRPG.NPCLevelScaling below.

HLRPG.DifficultyScales = {
    [1] = { name = "Very Easy", minLvl = 1,  maxLvl = 5,  color = Color(255, 255, 255) },
    [2] = { name = "Easy",      minLvl = 6,  maxLvl = 10, color = Color(0, 255, 0) },
    [3] = { name = "Normal",    minLvl = 12, maxLvl = 20, color = Color(255, 200, 0) },
    [4] = { name = "Hard",      minLvl = 24, maxLvl = 30, color = Color(255, 50, 50) },
    [5] = { name = "Insane",    minLvl = 35, maxLvl = 50, color = Color(150, 0, 150) }
}

-- multiplier = (base + perLevel * (level - 1)) * growth ^ (level - 1)
-- Player weapons don't get stronger with level, so HP growth is kept gentle (it directly sets how long fights
-- take). DMG grows slightly faster than player max health (+10/level, sv_progression.lua), so high-level
-- fights are short and dangerous rather than long.
--   Level:  1     8     16    27    42    50
--   HP:     0.80  1.01  1.25  1.58  2.03  2.27
--   DMG:    1.00  1.84  2.80  4.12  5.92  6.88
--   XP:     1.00  1.61  2.76  5.81  16.0  27.5
HLRPG.NPCLevelScaling = {
    HP  = { base = 0.8, perLevel = 0.03, growth = 1.0 },
    DMG = { base = 1.0, perLevel = 0.12, growth = 1.0 },
    XP  = { base = 1.0, perLevel = 0,    growth = 1.07 },
}

-- Player levels are measured in kills of a standard enemy (ReferenceNPC in HLRPG.NPCXP) at the player's
-- own level, so the curve stays in step with the XP scaling above. Passing level L takes
-- KillsBase + KillsPerLevel * (L - 1) such kills (solo; XP is split in co-op).
--   Level:      1    5      10      20      30       40       50
--   Total XP:   650  4,350  13,000  55,550  172,700  468,850  1,180,750
-- A full solo HL2 campaign is roughly 1,300 standard kills, which ends around level 24.
HLRPG.LevelCurve = {
    ReferenceNPC = "npc_combine_s",
    KillsBase = 25,
    KillsPerLevel = 2.5,
}

function HLRPG.GetDifficulty()
    local level = GetGlobalInt("HLRPG_CurrentDifficulty", 1)
    return HLRPG.DifficultyScales[level] or HLRPG.DifficultyScales[1], level
end

-- stat is "HP", "DMG" or "XP"
function HLRPG.GetNPCLevelMultiplier(stat, npcLevel)
    local scaling = HLRPG.NPCLevelScaling[stat]
    local levels = math.max(npcLevel, 1) - 1
    return (scaling.base + (scaling.perLevel or 0) * levels) * scaling.growth ^ levels
end

local requiredXPCache = {}

-- Total (cumulative) XP needed to pass the given player level, rounded to the nearest 50
function HLRPG.GetRequiredXP(level)
    if requiredXPCache[level] then return requiredXPCache[level] end

    local curve = HLRPG.LevelCurve
    local referenceXP = HLRPG.NPCXP[curve.ReferenceNPC]

    local total = 0
    for l = 1, level do
        local kills = curve.KillsBase + curve.KillsPerLevel * (l - 1)
        total = total + referenceXP * HLRPG.GetNPCLevelMultiplier("XP", l) * kills
    end

    requiredXPCache[level] = math.Round(total / 50) * 50
    return requiredXPCache[level]
end
