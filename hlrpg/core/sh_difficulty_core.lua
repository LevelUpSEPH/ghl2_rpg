-- addons/halflife_rpg/lua/hlrpg/core/sh_difficulty_core.lua

if SERVER then AddCSLuaFile() end -- Bu dosyanın Client'a da gitmesini sağlar

HLRPG_DifficultyScales = {
    [1] = { name = "Very Easy", minLvl = 1,  maxLvl = 5,  mult = 0.8, xpMult = 1.0, color = Color(255, 255, 255) },
    [2] = { name = "Easy",      minLvl = 6,  maxLvl = 10, mult = 1.0, xpMult = 1.5, color = Color(0, 255, 0) },
    [3] = { name = "Normal",    minLvl = 12, maxLvl = 20, mult = 1.5, xpMult = 2.0, color = Color(255, 200, 0) },
    [4] = { name = "Hard",      minLvl = 24, maxLvl = 30, mult = 2.0, xpMult = 3.0, color = Color(255, 50, 50) },
    [5] = { name = "Insane",    minLvl = 35, maxLvl = 50, mult = 3.5, xpMult = 5.0, color = Color(150, 0, 150) }
}

HLRPG_LevelConfig = {
    [1]  = 500,
    [2]  = 1500,
    [3]  = 2500,
    [4]  = 3500,
    [5]  = 4500,
    [6]  = 5500,
    [7]  = 6500,
    [8]  = 8000,
    [9]  = 9000,
    [10] = 10000,
    [11] = 12000,
    [12] = 14000,
    [13] = 16000,
    [14] = 18000,
    [15] = 20000,
    [16] = 25000,
    [17] = 30000,
    [18] = 35000,
    [19] = 40000,
    [20] = 50000
}

function HLRPG_CalculateStat(baseValue, statType, npcLevel)
    local currentDiff = GetGlobalInt("HLRPG_CurrentDifficulty", 1)
    local diffData = HLRPG_DifficultyScales[currentDiff] or HLRPG_DifficultyScales[1]
    
    local levelBonus = 1 + (npcLevel * 0.02)
    local diffMult = diffData.mult

    if statType == "HP" then
        return baseValue * diffMult * levelBonus
    elseif statType == "DMG" then
        return baseValue * (1 + (diffMult * 0.1)) * (1 + (npcLevel * 0.01))
    elseif statType == "XP" then
        return baseValue * diffData.xpMult * (1 + (npcLevel * 0.05))
    end
    
    return baseValue * diffMult
end

function HLRPG_GetRequiredXP(lvl)
    if HLRPG_LevelConfig[lvl] then
        return HLRPG_LevelConfig[lvl]
    end
    return 10000 + ((lvl - 10) * 5000)
end