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
    [1]  = 100,
    [2]  = 250,
    [3]  = 500,
    [4]  = 850,
    [5]  = 1300,
    [6]  = 2000,
    [7]  = 3000,
    [8]  = 4500,
    [9]  = 6500,
    [10] = 10000, -- 10'dan sonra her level için bir formül de ekleyebiliriz veya devam edebilirsin
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
        -- XP için kendi çarpanını (xpMult) kullanıyoruz
        return baseValue * diffData.xpMult * (1 + (npcLevel * 0.05))
    end
    
    return baseValue * diffMult
end

function HLRPG_GetRequiredXP(lvl)
    if HLRPG_LevelConfig[lvl] then
        return HLRPG_LevelConfig[lvl]
    end
    -- Tabloda yoksa: Son kayıtlı level + (level başına 5000 artış)
    return 10000 + ((lvl - 10) * 5000)
end