-- addons/halflife_rpg/lua/hlrpg/modules/sv_rpg_system.lua

if not SERVER then return end

util.AddNetworkString("HLRPG_XPNotify")

print("[HLRPG] Core RPG System Yukleniyor...")

-- ==========================================
-- 1. STAT VE BAŞLANGIÇ AYARLARI
-- ==========================================

hook.Add("PlayerSpawn", "HLRPG_ApplyStats", function(ply)
    ply.HLRPG_Level = ply.HLRPG_Level or 1
    ply.HLRPG_XP = ply.HLRPG_XP or 0
    
    ply:SetNWInt("HLRPG_Level", ply.HLRPG_Level)
    ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
    -- HUD İÇİN KRİTİK: Bir sonraki seviye gereksinimini de ağa yay
    ply:SetNWInt("HLRPG_MaxXP", ply.HLRPG_Level * 100)

    local maxHealth = 100 + ((ply.HLRPG_Level - 1) * 10)
    
    timer.Simple(0.1, function()
        if IsValid(ply) then
            ply:SetMaxHealth(maxHealth)
            ply:SetHealth(maxHealth)
        end
    end)
end)

local function PerformLevelUp(ply)
    local levelsGained = 0
    local currentLevel = ply.HLRPG_Level or 1
    
    -- Sözlükten bir sonraki seviye gereksinimini al
    -- XP harcanınca seviye düşmemesi için sadece 'ileriye' doğru kontrol yapar
    while ply.HLRPG_XP >= HLRPG_GetRequiredXP(currentLevel + levelsGained) do
        levelsGained = levelsGained + 1
    end

    if levelsGained > 0 then
        ply.HLRPG_Level = currentLevel + levelsGained
        ply:SetNWInt("HLRPG_Level", ply.HLRPG_Level)

        -- Stat Güncelleme
        local newMax = 100 + ((ply.HLRPG_Level - 1) * 10) + (ply.HLRPG_BonusHP or 0)
        ply:SetMaxHealth(newMax)
        ply:SetHealth(newMax)

        ply:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 100, 120)
        ply:ChatPrint(">>> SEVİYE ATLADIN: " .. ply.HLRPG_Level .. " <<<")
    end

    -- HUD/Scoreboard için gereken bar sınırını güncelle
    ply:SetNWInt("HLRPG_MaxXP", HLRPG_GetRequiredXP(ply.HLRPG_Level))
end

hook.Add("EntityTakeDamage", "HLRPG_TrackDamage", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()

    if IsValid(target) and target:IsNPC() and IsValid(attacker) and attacker:IsPlayer() then
        target.HLRPG_DamageTable = target.HLRPG_DamageTable or {}
        
        local dmgAmount = dmginfo:GetDamage()
        
        local actualDmg = math.min(dmgAmount, target:Health())
        
        target.HLRPG_DamageTable[attacker] = (target.HLRPG_DamageTable[attacker] or 0) + actualDmg
    end
end)

hook.Add("EntityTakeDamage", "HLRPG_TrackVehicleDamage", function(target, dmginfo)
    if target:IsNPC() then
        local attacker = dmginfo:GetAttacker()
        local inflictor = dmginfo:GetInflictor()
        local ply = nil

        if IsValid(attacker) and attacker:IsVehicle() then
            ply = attacker:GetDriver()
        elseif IsValid(inflictor) and inflictor:IsVehicle() then
            ply = inflictor:GetDriver()
        end

        if IsValid(ply) and ply:IsPlayer() then
            target.HLRPG_DamageTable = target.HLRPG_DamageTable or {}
            target.HLRPG_DamageTable[ply] = (target.HLRPG_DamageTable[ply] or 0) + dmginfo:GetDamage()
        end
    end
end)

hook.Add("OnNPCKilled", "HLRPG_XP_System", function(npc, attacker, inflictor)
    if not npc.HLRPG_DamageTable or table.Count(npc.HLRPG_DamageTable) == 0 then return end

    local totalXPAward = npc.HLRPG_AwardXP or 10
    local npcDisplayName = (HLRPG_GetNPCName and HLRPG_GetNPCName(npc)) or npc:GetClass():gsub("npc_", ""):upper()

    local totalDamage = 0
    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) then totalDamage = totalDamage + dmg end
    end

    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) and ply:IsPlayer() then
            local ratio = dmg / totalDamage
            local xpGain = math.Round(totalXPAward * ratio)
            local percentage = math.Round(ratio * 100)

            if xpGain > 0 then
                if ply.IsZombieForm then
                    ply.CanBurstRevive = true
                end

                ply.HLRPG_XP = (ply.HLRPG_XP or 0) + xpGain
                ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)

                if HLRPG_AddTempPoints then HLRPG_AddTempPoints(ply, xpGain) end
                PerformLevelUp(ply)
                
                if ply.AddUltCharge then
                    ply:AddUltCharge(math.Clamp(xpGain * 0.2, 2, 50))
                end

                net.Start("HLRPG_XPNotify")
                net.WriteInt(xpGain, 32)
                net.WriteInt(percentage, 16)
                net.WriteString(npcDisplayName)
                local npcCol = (HLRPG_GetNPCColor and HLRPG_GetNPCColor(npc)) or Color(255, 255, 255)
                net.WriteColor(npcCol)
                net.Send(ply)
            end
        end
    end
end)

if engine.ActiveGamemode() == "lambda" then
    print("[HLRPG] Lambda Modu Tespit Edildi. Entegrasyon Aktif.")

    hook.Add("LambdaOnPlayerSave", "HLRPG_SaveData", function(ply, data)
        data.HLRPG_Data = {
            xp = ply.HLRPG_XP,
            level = ply.HLRPG_Level,
            hat = ply.HLRPG_Hat
        }
    end)

    hook.Add("LambdaOnPlayerLoaded", "HLRPG_LoadData", function(ply, data)
        if data.HLRPG_Data then
            local saved = data.HLRPG_Data
            
            ply.HLRPG_Level = saved.level or 1
            ply.HLRPG_XP = saved.xp or 0
            ply.HLRPG_Hat = saved.hat or "Yok"
            
            ply:SetNWInt("HLRPG_Level", ply.HLRPG_Level)
            ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
            ply:SetNWString("HLRPG_Hat", ply.HLRPG_Hat)
            
            ply:ChatPrint("[SISTEM] Karakter verileri yüklendi. (Lv: " .. ply.HLRPG_Level .. ")")
        end
    end)
end