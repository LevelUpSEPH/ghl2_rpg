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
-- 2. XP VE LEVEL SİSTEMİ (GÜNCELLENDİ)
-- ==========================================

hook.Add("OnNPCKilled", "HLRPG_XP_System", function(npc, attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() then
        
        -- XP HESABI
        local xpGain = 10
        local npcClass = npc:GetClass()
        if npcClass == "npc_combine_s" then xpGain = 25 end
        if npcClass == "npc_hunter" then xpGain = 150 end
        if npcClass == "npc_strider" then xpGain = 500 end
        if npcClass == "npc_zombie" then xpGain = 15 end
        if npcClass == "npc_headcrab" then xpGain = 5 end

        -- XP EKLE
        attacker.HLRPG_XP = attacker.HLRPG_XP + xpGain
        attacker:SetNWInt("HLRPG_XP", attacker.HLRPG_XP)
        attacker:PrintMessage(HUD_PRINTCENTER, "+" .. xpGain .. " XP")

        -- [YENİ] ULTI CHARGE ENTEGRASYONU
        -- Warp Cannon şu an aktif değilse öldürme başına şarj ver
        if not attacker:GetNWBool("HLRPG_IsCastingUlt", false) then
            -- XP'nin yarısı kadar da Ulti şarjı gelsin
            local chargeGain = math.Clamp(xpGain * 0.5, 5, 20) 
            attacker:AddUltCharge(chargeGain)
        end

        -- LEVEL UP KONTROLÜ
        local requiredXP = attacker.HLRPG_Level * 100
        attacker:SetNWInt("HLRPG_MaxXP", requiredXP) -- HUD Barı için güncelle

        if attacker.HLRPG_XP >= requiredXP then
            attacker.HLRPG_XP = attacker.HLRPG_XP - requiredXP
            attacker.HLRPG_Level = attacker.HLRPG_Level + 1
            
            attacker:SetNWInt("HLRPG_Level", attacker.HLRPG_Level)
            attacker:SetNWInt("HLRPG_XP", attacker.HLRPG_XP)
            attacker:SetNWInt("HLRPG_MaxXP", attacker.HLRPG_Level * 100)
            
            attacker:EmitSound("music/hltv_stinger3.wav")
            attacker:ChatPrint(">>> TEBRİKLER! SEVİYE ATLADIN: " .. attacker.HLRPG_Level)
            
            local newMax = 100 + ((attacker.HLRPG_Level - 1) * 10)
            attacker:SetMaxHealth(newMax)
            attacker:SetHealth(newMax)
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