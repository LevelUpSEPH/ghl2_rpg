-- addons/halflife_rpg/lua/hlrpg/modules/sv_rpg_system.lua

if not SERVER then return end

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

-- ==========================================
-- GELİŞMİŞ XP VE LEVEL ATLATMA FONKSİYONU
-- ==========================================

-- ==========================================
-- Gelişmiş Seviye Atlama (HEV Temalı)
-- ==========================================

-- ==========================================
-- Gelişmiş Seviye Atlama (Valve Intro Temalı)
-- ==========================================

-- ==========================================
-- Seviye Atlama (Garantili Valve Sesi)
-- ==========================================

-- ==========================================
-- Seviye Atlama (Kısa ve Vurucu Ses)
-- ==========================================

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

-- ==========================================
-- GÜNCELLENİŞ ÖLDÜRME HOOK'U
-- ==========================================
hook.Add("OnNPCKilled", "HLRPG_XP_System", function(npc, attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() then
        local xpGain = 10
        local npcClass = npc:GetClass()
        
        -- XP Tablosu
        local xpTable = {
            ["npc_combine_s"] = 25,
            ["npc_hunter"] = 150,
            ["npc_strider"] = 1000, -- 1000 XP verir (Lv1 birini anında 3-4 level atlatır)
            ["npc_zombie"] = 15,
            ["npc_headcrab"] = 5,
            ["npc_antlionguard"] = 300
        }
        
        xpGain = xpTable[npcClass] or 10

        -- XP Ekle ve Fonksiyonu Çağır
        attacker.HLRPG_XP = (attacker.HLRPG_XP or 0) + xpGain
        attacker:SetNWInt("HLRPG_XP", attacker.HLRPG_XP)
        
        -- Level atlama kontrolünü çalıştır
        PerformLevelUp(attacker)
        
        -- Ulti şarjını da unutma
        if attacker.AddUltCharge then
            attacker:AddUltCharge(math.Clamp(xpGain * 0.2, 2, 50))
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