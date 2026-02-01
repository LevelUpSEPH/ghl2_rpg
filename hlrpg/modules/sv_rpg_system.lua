-- addons/halflife_rpg/lua/hlrpg/modules/sv_rpg_system.lua

if not SERVER then return end

util.AddNetworkString("HLRPG_XPNotify")

print("[HLRPG] Core RPG System Yukleniyor...")

-- ==========================================
-- 1. STAT VE BAŞLANGIÇ AYARLARI
-- ==========================================

local function PerformLevelUp(ply)
    local currentLevel = ply.HLRPG_Level or 1
    local levelsGained = 0
    
    -- XP barajını aşana kadar seviye atlat
    while (ply.HLRPG_XP or 0) >= HLRPG_GetRequiredXP(currentLevel + levelsGained) do
        levelsGained = levelsGained + 1
    end

    if levelsGained > 0 then
        ply.HLRPG_Level = currentLevel + levelsGained
        ply:SetNWInt("HLRPG_Level", ply.HLRPG_Level)

        -- Stat Güncelleme (Max HP artışı)
        local newMax = 100 + ((ply.HLRPG_Level - 1) * 10) + (ply.HLRPG_BonusHP or 0)
        ply:SetMaxHealth(newMax)
        ply:SetHealth(newMax)

        ply:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 100, 120)
        ply:ChatPrint(">>> SEVİYE ATLADIN: " .. ply.HLRPG_Level .. " <<<")
    end

    -- HUD/Scoreboard için bar sınırını güncelle
    ply:SetNWInt("HLRPG_MaxXP", HLRPG_GetRequiredXP(ply.HLRPG_Level))
end

-- DIŞARIDAN ÇAĞRILACAK ANA FONKSİYON (Başarım vb. için)
function HLRPG_AddXP(ply, amount)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not amount or amount <= 0 then return end

    ply.HLRPG_XP = (ply.HLRPG_XP or 0) + amount
    ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)

    -- Seviye kontrolünü yap
    PerformLevelUp(ply)
end

-- ==========================================
-- 2. COMBAT VE NPC SİSTEMİ
-- ==========================================

hook.Add("PlayerSpawn", "HLRPG_ApplyStats", function(ply)
    ply.HLRPG_Level = ply.HLRPG_Level or 1
    ply.HLRPG_XP = ply.HLRPG_XP or 0
    
    ply:SetNWInt("HLRPG_Level", ply.HLRPG_Level)
    ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
    ply:SetNWInt("HLRPG_MaxXP", HLRPG_GetRequiredXP(ply.HLRPG_Level))

    local maxHealth = 100 + ((ply.HLRPG_Level - 1) * 10)
    timer.Simple(0.1, function()
        if IsValid(ply) then
            ply:SetMaxHealth(maxHealth)
            ply:SetHealth(maxHealth)
        end
    end)
end)

-- Hasar Takibi
hook.Add("EntityTakeDamage", "HLRPG_TrackDamage", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    if IsValid(target) and target:IsNPC() and IsValid(attacker) and attacker:IsPlayer() then
        target.HLRPG_DamageTable = target.HLRPG_DamageTable or {}
        local actualDmg = math.min(dmginfo:GetDamage(), target:Health())
        target.HLRPG_DamageTable[attacker] = (target.HLRPG_DamageTable[attacker] or 0) + actualDmg
    end
end)

-- NPC Ölümünde XP Dağıtımı
hook.Add("OnNPCKilled", "HLRPG_XP_System", function(npc, attacker, inflictor)
    if not npc.HLRPG_DamageTable then return end

    local totalXPAward = npc.HLRPG_AwardXP or 10
    local totalDamage = 0
    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) then totalDamage = totalDamage + dmg end
    end

    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) and ply:IsPlayer() and totalDamage > 0 then
            local ratio = dmg / totalDamage
            local xpGain = math.Round(totalXPAward * ratio)

            if xpGain > 0 then
                -- MERKEZİ FONKSİYONU KULLAN
                HLRPG_AddXP(ply, xpGain)

                -- Bildirim Gönder
                net.Start("HLRPG_XPNotify")
                    net.WriteInt(xpGain, 32)
                    net.WriteInt(math.Round(ratio * 100), 16)
                    net.WriteString((HLRPG_GetNPCName and HLRPG_GetNPCName(npc)) or npc:GetClass():upper())
                    net.WriteColor(Color(255, 255, 255))
                net.Send(ply)
            end
        end
    end
end)

-- ==========================================
-- 3. KAYIT SİSTEMİ (LAMBDA INTEGRATION)
-- ==========================================

if engine.ActiveGamemode() == "lambda" then
    hook.Add("LambdaOnPlayerSave", "HLRPG_SaveData", function(ply, data)
        data.HLRPG_Data = {
            xp = ply.HLRPG_XP,
            level = ply.HLRPG_Level,
            achievements = ply.UnlockedAchievements -- Başarımları da kaydet
        }
    end)

    hook.Add("LambdaOnPlayerLoaded", "HLRPG_LoadData", function(ply, data)
        if data.HLRPG_Data then
            local saved = data.HLRPG_Data
            ply.HLRPG_Level = saved.level or 1
            ply.HLRPG_XP = saved.xp or 0
            ply.UnlockedAchievements = saved.achievements or {}
            
            ply:SetNWInt("HLRPG_Level", ply.HLRPG_Level)
            ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
            ply:ChatPrint("[SISTEM] Karakter verileri yüklendi.")
        end
    end)
end