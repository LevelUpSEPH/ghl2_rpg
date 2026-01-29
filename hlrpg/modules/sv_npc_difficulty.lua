-- addons/halflife_rpg/lua/hlrpg/modules/sv_npc_difficulty.lua
if not SERVER then return end

local RPG_Difficulty = 2

local function SetupBoss(npc)
    if not IsValid(npc) then return end
    
    local class = npc:GetClass()
    local bossList = {
        ["npc_hunter"] = true,
        ["npc_combinegunship"] = true,
        ["npc_helicopter"] = true,
        ["npc_strider"] = true,
        ["npc_antlionguard"] = true,
        ["npc_combinedropship"] = true
    }

    if bossList[class] then
        npc:SetNWBool("HLRPG_IsBoss", true)
        
        local bonusHP = 1 + (RPG_Difficulty * 1.5)
        npc:SetMaxHealth(npc:GetMaxHealth() * bonusHP)
        npc:SetHealth(npc:GetMaxHealth())
        
        npc:CallOnRemove("BossDeathCharge", function(ent)
            local attacker = ent:GetInternalVariable("m_hLastAttacker")
            if IsValid(attacker) and attacker:IsPlayer() then
                attacker:AddUltCharge(50) -- Boss ölünce barın yarısı dolsun
            end
        end)
    end
end

-- addons/halflife_rpg/lua/hlrpg/modules/sv_npc_difficulty.lua

function ScaleNPC(npc)
    if not IsValid(npc) or npc:IsPlayer() or npc:GetNWBool("HLRPG_ISPET", true) then return end
    
    -- Sadece canı ful olanlar güncellenir (Senin istediğin kural)
    if npc:Health() < npc:GetMaxHealth() then return end

    local diffLevel = GetGlobalInt("HLRPG_CurrentDifficulty", 1)
    local diffData = HLRPG_DifficultyScales[diffLevel]

    -- 1. Seviye Ataması
    if npc:GetNWInt("HLRPG_NPCLevel", 0) == 0 then
        local randomLvl = math.random(diffData.minLvl, diffData.maxLvl)
        npc:SetNWInt("HLRPG_NPCLevel", randomLvl)
    end
    local myLvl = npc:GetNWInt("HLRPG_NPCLevel")

    -- 2. XP'Yİ DOĞDUĞU AN HESAPLA VE KAYDET (Kritik Fix)
    local npcClass = npc:GetClass()
    local xpTable = { ["npc_combine_s"] = 25, ["npc_hunter"] = 150, ["npc_strider"] = 1000, ["npc_zombie"] = 15, ["npc_headcrab"] = 5, ["npc_antlionguard"] = 300 }
    local baseXP = xpTable[npcClass] or 10
    
    -- NPC üzerine o anki zorluğa göre hak ettiği XP'yi mühürle
    npc.HLRPG_AwardXP = HLRPG_CalculateStat(baseXP, "XP", myLvl)

    -- 3. Can Statlarını Uygula
    if not npc.HLRPG_BaseHealth then npc.HLRPG_BaseHealth = npc:GetMaxHealth() end
    local finalHP = HLRPG_CalculateStat(npc.HLRPG_BaseHealth, "HP", myLvl)
    if npc:GetNWBool("HLRPG_IsBoss") then finalHP = finalHP * 2 end

    npc:SetMaxHealth(math.floor(finalHP))
    npc:SetHealth(math.floor(finalHP))
end

-- Yeni doğanlar için kanca
hook.Add("OnEntityCreated", "HLRPG_ScaleNPC_Spawn", function(ent)
    if ent:IsNPC() then
        timer.Simple(0.1, function() ScaleNPC(ent) end)
    end
end)

hook.Add("OnEntityCreated", "HLRPG_BossInit", function(ent)
    if ent:IsNPC() then
        timer.Simple(0.1, function() SetupBoss(ent) end)
    end
end)