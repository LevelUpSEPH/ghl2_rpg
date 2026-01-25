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
    
    while ply.HLRPG_XP >= (ply.HLRPG_Level * 100) do
        local required = ply.HLRPG_Level * 100
        ply.HLRPG_XP = ply.HLRPG_XP - required
        ply.HLRPG_Level = ply.HLRPG_Level + 1
        levelsGained = levelsGained + 1
    end

    if levelsGained > 0 then
        ply:SetNWInt("HLRPG_Level", ply.HLRPG_Level)
        ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
        ply:SetNWInt("HLRPG_MaxXP", ply.HLRPG_Level * 100)

        local newMax = 100 + ((ply.HLRPG_Level - 1) * 10)
        ply:SetMaxHealth(newMax)
        ply:SetHealth(newMax)

        -- SES SEÇENEĞİ: 
        -- "ambient/levels/citadel/weapon_disintegrate2.wav" -> Çok havalı bir teknolojik ses
        -- "items/suitchargeok1.wav" -> Klasik HEV onayı
        
        -- Ben burada hem kısa hem de 'güçlenme' hissi veren şu sesi seçtim:
        ply:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 100, 120)
        ply:EmitSound("items/suitchargeok1.wav", 80, 100) -- İkisini karıştırınca çok RPG vari oluyor

        -- Görsel Efekt
        local ed = EffectData()
        ed:SetOrigin(ply:GetPos() + Vector(0,0,20))
        ed:SetScale(1)
        util.Effect("cball_explode", ed)

        ply:ChatPrint(">>> SEVİYE ATLADIN: " .. ply.HLRPG_Level .. " <<<")
    end
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

-- addons/halflife_rpg/lua/hlrpg/modules/sv_rpg_system.lua

-- addons/halflife_rpg/lua/hlrpg/modules/sv_rpg_system.lua

hook.Add("OnNPCKilled", "HLRPG_XP_System", function(npc, attacker, inflictor)
    if not npc.HLRPG_DamageTable or table.Count(npc.HLRPG_DamageTable) == 0 then return end

    -- NPC doğduğunda üzerine mühürlediğimiz sabit XP'yi al
    local totalXPAward = npc.HLRPG_AwardXP or 10
    
    -- Sözlükten ismini alalım (Sözlük yoksa class ismini temizle)
    local npcDisplayName = (HLRPG_GetNPCName and HLRPG_GetNPCName(npc)) or npc:GetClass():gsub("npc_", ""):upper()

    -- 1. TOPLAM HASARI HESAPLA
    local totalDamage = 0
    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) then totalDamage = totalDamage + dmg end
    end

    -- 2. DAĞITIM VE BİLDİRİM
    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) and ply:IsPlayer() then
            local ratio = dmg / totalDamage
            local xpGain = math.Round(totalXPAward * ratio)
            local percentage = math.Round(ratio * 100)

            if xpGain > 0 then
                -- Stat Güncelleme
                ply.HLRPG_XP = (ply.HLRPG_XP or 0) + xpGain
                ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
                
                -- Level Kontrolü
                PerformLevelUp(ply)
                
                -- Ulti Şarjı
                if ply.AddUltCharge then
                    ply:AddUltCharge(math.Clamp(xpGain * 0.2, 2, 50))
                end

                net.Start("HLRPG_XPNotify")
                net.WriteInt(xpGain, 32)
                net.WriteInt(percentage, 16)
                net.WriteString(npcDisplayName)
                -- NPC rengini de gönderelim (sözlükten çekiyoruz)
                local npcCol = (HLRPG_GetNPCColor and HLRPG_GetNPCColor(npc)) or Color(255, 255, 255)
                net.WriteColor(npcCol)
                net.Send(ply)
            end
        end
    end
end)

-- Lambda entegrasyonu kısmını olduğu gibi bırakabilirsin, o gayet güzel çalışıyor.

-- ==========================================
-- 3. LAMBDA ENTEGRASYONU (DATA PERSISTENCE)
-- ==========================================

if engine.ActiveGamemode() == "lambda" then
    print("[HLRPG] Lambda Modu Tespit Edildi. Entegrasyon Aktif.")

    -- HARİTA DEĞİŞİRKEN (SAVE)
    hook.Add("LambdaOnPlayerSave", "HLRPG_SaveData", function(ply, data)
        data.HLRPG_Data = {
            xp = ply.HLRPG_XP,
            level = ply.HLRPG_Level,
            hat = ply.HLRPG_Hat
        }
    end)

    -- YENİ HARİTADA (LOAD)
    hook.Add("LambdaOnPlayerLoaded", "HLRPG_LoadData", function(ply, data)
        if data.HLRPG_Data then
            local saved = data.HLRPG_Data
            
            ply.HLRPG_Level = saved.level or 1
            ply.HLRPG_XP = saved.xp or 0
            ply.HLRPG_Hat = saved.hat or "Yok"
            
            -- Network Sync yapmayı unutma!
            ply:SetNWInt("HLRPG_Level", ply.HLRPG_Level)
            ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
            ply:SetNWString("HLRPG_Hat", ply.HLRPG_Hat)
            
            ply:ChatPrint("[SISTEM] Karakter verileri yüklendi. (Lv: " .. ply.HLRPG_Level .. ")")
        end
    end)
end