-- addons/halflife_rpg/lua/hlrpg/modules/sv_equipment.lua

if not SERVER then return end

util.AddNetworkString("HLRPG_OpenMenu")
util.AddNetworkString("HLRPG_EquipItem")
util.AddNetworkString("HLRPG_Sync_Suit")

-- ==========================================
-- ELLERİ ZORLA DEĞİŞTİRME FONKSİYONU
-- (Hook'a güvenmiyoruz, kendimiz yapıyoruz)
-- ==========================================
local function SetHandsDirectly(ply)
    if not IsValid(ply) then return end
    
    -- 1. Zırh verisini al
    local suitID = ply.HLRPG_Suit
    if not suitID or suitID == "none" then return end

    local suitData = nil
    for _, s in ipairs(HLRPG.Config.Suits) do
        if s.id == suitID then suitData = s; break end
    end

    if not suitData or not suitData.hands then return end

    -- 2. SETUP HANDS ÇAĞIR (Sistemi hazırla)
    ply:SetupHands()

    -- 3. EL ENTITY'SİNİ BUL VE ZORLA DEĞİŞTİR
    local hands = ply:GetHands()
    if IsValid(hands) then
        hands:SetModel(suitData.hands)
        
        if suitData.skin then
            hands:SetSkin(suitData.skin)
        end
        
        -- Görünürlük ayarları (Bazen görünmez doğuyorlar)
        hands:SetRenderMode(RENDERMODE_NORMAL)
        hands:SetColor(Color(255, 255, 255, 255))
        
        print("[HLRPG] Eller Zorla Degistirildi: " .. suitData.hands)
    else
        print("[HLRPG] HATA: Oyuncunun el entity'si bulunamadı!")
    end
end

-- ==========================================
-- NETWORKING
-- ==========================================

hook.Add("ShowHelp", "HLRPG_Override_F1", function(ply)
    net.Start("HLRPG_OpenMenu")
    net.Send(ply)
    return false
end)

net.Receive("HLRPG_EquipItem", function(len, ply)
    local type = net.ReadString()
    local value = net.ReadString()
    
    if type == "model" then
        ply:SetModel(value)
        ply.HLRPG_Model = value
        ply:SetupHands() 
        ply:ChatPrint("Kıyafet değişti.")

    elseif type == "suit" then
        local suitData = nil
        for _, s in ipairs(HLRPG.Config.Suits) do
            if s.id == value then suitData = s; break end
        end
        
        if suitData then
            ply.HLRPG_Suit = value
            ply:ChatPrint("Zırh Kuşandın: " .. suitData.name)
            
            -- Visuals (Dış)
            net.Start("HLRPG_Sync_Suit")
                net.WriteEntity(ply)
                net.WriteString(suitData.model or "none")
            net.Broadcast()
            
            -- Eller (İç) - Timer ile gecikmeli yapıyoruz ki model otursun
            timer.Simple(0.1, function()
                if IsValid(ply) then SetHandsDirectly(ply) end
            end)
        end
    end
end)

-- ==========================================
-- HOOK: PLAYER SET HANDS (YEDEK PLAN)
-- ==========================================
-- Bu yine de dursun, oyun motoru bazen bunu kendi çağırırsa doğru cevabı verelim.
hook.Add("PlayerSetHands", "HLRPG_Hook_SetHands", function(ply, ent)
    if not ply.HLRPG_Suit or ply.HLRPG_Suit == "none" then return end

    local suitData = nil
    for _, s in ipairs(HLRPG.Config.Suits) do
        if s.id == ply.HLRPG_Suit then suitData = s; break end
    end

    if suitData and suitData.hands then
        ent:SetModel(suitData.hands)
        if suitData.skin then ent:SetSkin(suitData.skin) end
        print("[HLRPG] Hook Tetiklendi!") -- Bunu konsolda görmüyorsan hook çalışmıyor demektir.
        return true
    end
end)

-- ==========================================
-- SPAWN & LOAD
-- ==========================================
hook.Add("PlayerSpawn", "HLRPG_Spawn_Hands", function(ply)
    timer.Simple(0.2, function() -- 0.2 saniye bekle
        if not IsValid(ply) then return end
        
        -- Model
        if ply.HLRPG_Model then ply:SetModel(ply.HLRPG_Model) end
        
        -- Zırh Visuals
        if ply.HLRPG_Suit then
            local sModel = "none"
            for _, s in ipairs(HLRPG.Config.Suits) do
                if s.id == ply.HLRPG_Suit then sModel = s.model; break end
            end
            net.Start("HLRPG_Sync_Suit")
            net.WriteEntity(ply)
            net.WriteString(sModel or "none")
            net.Broadcast()
            
            -- ELLERİ ZORLA
            SetHandsDirectly(ply)
        end
    end)
end)

-- Yeni giren oyuncu senkronizasyonu
hook.Add("PlayerInitialSpawn", "HLRPG_Sync_Init", function(ply)
    timer.Simple(5, function()
        if not IsValid(ply) then return end
        for _, otherPly in ipairs(player.GetAll()) do
            if otherPly.HLRPG_Suit then
                local modelPath = "none"
                for _, s in ipairs(HLRPG.Config.Suits) do
                    if s.id == otherPly.HLRPG_Suit then modelPath = s.model; break end
                end
                if modelPath ~= "none" then
                    net.Start("HLRPG_Sync_Suit")
                    net.WriteEntity(otherPly)
                    net.WriteString(modelPath)
                    net.Send(ply)
                end
            end
        end
    end)
end)