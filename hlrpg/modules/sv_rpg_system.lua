-- addons/halflife_rpg/lua/hlrpg/modules/sv_rpg_system.lua

if not SERVER then return end

print("[HLRPG] Core RPG System Yukleniyor...")

-- ==========================================
-- 1. STAT VE BAŞLANGIÇ AYARLARI
-- ==========================================

-- Oyuncu doğduğunda statlarını ayarla
hook.Add("PlayerSpawn", "HLRPG_ApplyStats", function(ply)
    -- Veri güvenliği: Değerler yoksa varsayılanı ata
    ply.HLRPG_Level = ply.HLRPG_Level or 1
    ply.HLRPG_XP = ply.HLRPG_XP or 0
    ply.HLRPG_Hat = ply.HLRPG_Hat or "None"
    
    -- Network Sync: Client (Scoreboard) bilsin diye veriyi yay
    ply:SetNWInt("HLRPG_Level", ply.HLRPG_Level)
    ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
    ply:SetNWString("HLRPG_Hat", ply.HLRPG_Hat)

    -- Fiziksel Statlar (Level başına +10 HP, +2 Hız)
    local maxHealth = 100 + ((ply.HLRPG_Level - 1) * 10)
    
    -- Timer kullanıyoruz çünkü GMod bazen spawn anında statları ezer
    timer.Simple(0.1, function()
        if IsValid(ply) then
            ply:SetMaxHealth(maxHealth)
            ply:SetHealth(maxHealth)
        end
    end)
end)

-- ==========================================
-- 2. XP VE LEVEL SİSTEMİ
-- ==========================================

hook.Add("OnNPCKilled", "HLRPG_XP_System", function(npc, attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() then
        
        -- Düşman tipine göre XP Hesapla
        local xpGain = 10
        local npcClass = npc:GetClass()
        
        if npcClass == "npc_combine_s" then xpGain = 25 end
        if npcClass == "npc_hunter" then xpGain = 150 end
        if npcClass == "npc_strider" then xpGain = 500 end
        if npcClass == "npc_zombie" then xpGain = 15 end
        if npcClass == "npc_headcrab" then xpGain = 5 end

        -- XP Ekle
        attacker.HLRPG_XP = attacker.HLRPG_XP + xpGain
        
        -- Client'a bildir (Network Update)
        attacker:SetNWInt("HLRPG_XP", attacker.HLRPG_XP)
        attacker:PrintMessage(HUD_PRINTCENTER, "+" .. xpGain .. " XP")

        -- LEVEL UP KONTROLÜ
        -- Formül: Level * 100 (Örn: Lv1 -> 100XP, Lv5 -> 500XP ister)
        local requiredXP = attacker.HLRPG_Level * 100
        
        if attacker.HLRPG_XP >= requiredXP then
            attacker.HLRPG_XP = attacker.HLRPG_XP - requiredXP -- Artan XP'yi devret
            attacker.HLRPG_Level = attacker.HLRPG_Level + 1
            
            -- Network Update
            attacker:SetNWInt("HLRPG_Level", attacker.HLRPG_Level)
            attacker:SetNWInt("HLRPG_XP", attacker.HLRPG_XP)
            
            -- Efektler
            attacker:EmitSound("music/hltv_stinger3.wav")
            attacker:ChatPrint(">>> TEBRİKLER! SEVİYE ATLADIN: " .. attacker.HLRPG_Level)
            
            -- Canı fulle ve artır
            local newMax = 100 + ((attacker.HLRPG_Level - 1) * 10)
            attacker:SetMaxHealth(newMax)
            attacker:SetHealth(newMax)
        end
    end
end)

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