-- addons/halflife_rpg/lua/hlrpg/modules/sv_equipment.lua

if not SERVER then return end

-- İletişim ağını kuralım
util.AddNetworkString("HLRPG_OpenMenu")   -- Server -> Client (Menüyü Aç)
util.AddNetworkString("HLRPG_EquipItem")  -- Client -> Server (Bunu Giy)
util.AddNetworkString("HLRPG_Sync_Suit")

-- 1. F1 TUŞUNU YAKALA (Lambda'yı Engelle)
hook.Add("ShowHelp", "HLRPG_Override_F1", function(ply)
    -- Client'a "Menüyü Aç" emri gönder
    net.Start("HLRPG_OpenMenu")
    net.Send(ply)
    
    return false -- false döndürerek Lambda'nın menüsünü engelliyoruz!
end)

-- 2. GİYİNME İSTEĞİNİ İŞLE
net.Receive("HLRPG_EquipItem", function(len, ply)
    local type = net.ReadString() -- "model" veya "hat"
    local value = net.ReadString() -- "models/..." veya "hat_rollermine"
    
    if type == "model" then
        -- Modeli ayarla
        ply:SetModel(value)
        ply.HLRPG_Model = value -- Veritabanı için değişkene kaydet
        
        -- Lambda Entegrasyonu: Lambda'nın verisini de güncelle ki respawn olunca bozulmasın
        -- Not: Lambda'nın iç yapısında "lambda_playermodel" diye bir değişken olabilir, 
        -- ama biz en garantisi kendi hookumuzla ezeceğiz.
        ply:ChatPrint("Kıyafetin değiştirildi!")
        
    elseif type == "hat" then
        ply.HLRPG_Hat = value
        ply:SetNWString("HLRPG_Hat", value)
        ply:ChatPrint("Şapka takıldı: " .. value)
    elseif type == "suit" then
        -- Value burada configdeki ID'dir (örn: "suit_combine")
        local suitData = nil
        for _, s in ipairs(HLRPG.Config.Suits) do
            if s.id == value then suitData = s; break end
        end
        
        if suitData then
            ply.HLRPG_Suit = value
            
            -- Statları uygula (İlerde buraya zırh puanı ekleyeceğiz)
            ply:ChatPrint("Zırh Kuşandın: " .. suitData.name)
            
            -- TÜM OYUNCULARA HABER VER (Senkronizasyon)
            net.Start("HLRPG_Sync_Suit")
                net.WriteEntity(ply)
                net.WriteString(suitData.model or "none") -- Model yolunu yolla
            net.Broadcast() -- Herkese yolla
        end
    end
end)

-- 3. SPAWN OLUNCA MODELİ ZORLA (Anti-Overlap)
-- Lambda spawn ederken kendi modelini giydirir. Biz 0.1 saniye sonra onu eziyoruz.
hook.Add("PlayerSpawn", "HLRPG_ForceModel", function(ply)
    timer.Simple(0.1, function()
        if IsValid(ply) and ply.HLRPG_Model then
            ply:SetModel(ply.HLRPG_Model)
        end
    end)
end)

hook.Add("PlayerInitialSpawn", "HLRPG_Sync_All_Suits", function(ply)
    -- Yeni giren kişiye, sunucudaki diğer herkesin zırhını göster
    timer.Simple(5, function() -- 5 sn bekle tam yüklensin
        if not IsValid(ply) then return end
        
        for _, otherPly in ipairs(player.GetAll()) do
            if otherPly.HLRPG_Suit then
                -- O oyuncunun zırhının modelini bul
                local modelPath = "none"
                for _, s in ipairs(HLRPG.Config.Suits) do
                    if s.id == otherPly.HLRPG_Suit then modelPath = s.model; break end
                end
                
                -- Sadece yeni giren kişiye yolla
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

-- 4. LAMBDA SAVE ENTEGRASYONU (Modeli Kaydet)
hook.Add("LambdaOnPlayerSave", "HLRPG_SaveModel", function(ply, data)
    -- Mevcut data tablosuna ekleme yap
    if not data.HLRPG_Data then data.HLRPG_Data = {} end
    data.HLRPG_Data.model = ply.HLRPG_Model
end)

hook.Add("LambdaOnPlayerLoaded", "HLRPG_LoadModel", function(ply, data)
    if data.HLRPG_Data and data.HLRPG_Data.model then
        ply.HLRPG_Model = data.HLRPG_Data.model
        -- Yüklenir yüklenmez giydir
        timer.Simple(0.5, function() 
            if IsValid(ply) then ply:SetModel(ply.HLRPG_Model) end 
        end)
    end
end)