-- addons/halflife_rpg/lua/hlrpg/modules/cl_visuals.lua

if not CLIENT then return end

local Visuals = {}
local INVISIBLE_MAT = "models/effects/vol_light001"

-- YARDIMCI: Temizlik Fonksiyonu (Tekrar tekrar yazmamak için)
local function RemoveVisuals(sid)
    if not Visuals[sid] then return end
    
    local data = Visuals[sid]
    if IsValid(data.Suit) then data.Suit:Remove() end
    if IsValid(data.FakeHead) then data.FakeHead:Remove() end
    
    -- Oyuncu hala oyundaysa (disconnect olmadıysa) materyalini düzelt
    local ply = player.GetBySteamID(sid)
    if IsValid(ply) then
        ply:SetMaterial("")
        ply:SetRenderMode(RENDERMODE_NORMAL)
        ply:SetColor(Color(255, 255, 255, 255))
        
        -- Silahı da düzelt
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            wep:SetMaterial("")
            wep:SetRenderMode(RENDERMODE_NORMAL)
            wep:SetColor(Color(255, 255, 255, 255))
        end
    end

    Visuals[sid] = nil
end

-- NETWORK: Sunucudan gelen zırh bilgisini al
net.Receive("HLRPG_Sync_Suit", function()
    local ply = net.ReadEntity()
    local suitModel = net.ReadString()
    
    if IsValid(ply) then
        UpdatePlayerVisuals(ply, suitModel)
    end
end)

-- GÖRSEL GÜNCELLEME
function UpdatePlayerVisuals(ply, suitPath)
    local sid = ply:SteamID()
    
    -- 1. Önce eski kalıntıları temizle (Crash Fix)
    RemoveVisuals(sid)

    -- 2. Eğer zırh çıkarıldıysa ("none"), temizledik ve çıkıyoruz.
    if not suitPath or suitPath == "none" or suitPath == "" then
        return
    end

    -- 3. Yeni kayıt oluştur
    Visuals[sid] = {
        Active = true,
        CachedHeadID_Suit = nil,
        CachedHeadID_Fake = nil
    }

    -- 4. SUIT YARAT
    local suit = ClientsideModel(suitPath)
    if IsValid(suit) then
        suit:SetPos(ply:GetPos())
        suit:SetParent(ply)
        suit:AddEffects(EF_BONEMERGE)
        suit:SetModelScale(1.01, 0)
        
        local hBone = suit:LookupBone("ValveBiped.Bip01_Head1")
        if hBone then
            Visuals[sid].CachedHeadID_Suit = hBone
            
            -- CALLBACK (Kafayı Yok Et)
            suit:AddCallback("BuildBonePositions", function(ent, nbones)
                -- CRASH FIX: Visuals[sid] silindiyse çalışmayı durdur!
                if not Visuals[sid] or not IsValid(ent) then return end
                
                local id = Visuals[sid].CachedHeadID_Suit
                local m = ent:GetBoneMatrix(id)
                if m then m:Scale(Vector(0,0,0)); ent:SetBoneMatrix(id, m) end
            end)
        end
        Visuals[sid].Suit = suit
    end

    -- 5. FAKE HEAD YARAT
    local head = ClientsideModel(ply:GetModel())
    if IsValid(head) then
        head:SetPos(ply:GetPos())
        head:SetParent(ply)
        head:AddEffects(EF_BONEMERGE)
        
        local hBone = head:LookupBone("ValveBiped.Bip01_Head1")
        if hBone then
            Visuals[sid].CachedHeadID_Fake = hBone
            
            -- CALLBACK (Kafa Hariç Her Şeyi Yok Et)
            head:AddCallback("BuildBonePositions", function(ent, nbones)
                -- CRASH FIX: Güvenlik Kontrolü
                if not Visuals[sid] or not IsValid(ent) then return end
                
                local hid = Visuals[sid].CachedHeadID_Fake
                for i = 0, nbones - 1 do
                    if i ~= hid then
                        local m = ent:GetBoneMatrix(i)
                        if m then m:Scale(Vector(0,0,0)); ent:SetBoneMatrix(i, m) end
                    end
                end
            end)
        end
        Visuals[sid].FakeHead = head
    end
end

-- THINK: DÖNGÜ VE KONTROLLER
hook.Add("Think", "HLRPG_Global_Visual_Enforce", function()
    for sid, data in pairs(Visuals) do
        local ply = player.GetBySteamID(sid)
        
        -- KONTROL 1: Oyuncu çıktıysa temizle
        if not IsValid(ply) then 
            RemoveVisuals(sid)
            continue 
        end
        
        -- KONTROL 2: Oyuncu ÖLDÜYSE temizle (GHOST BUG FIX)
        -- Alive() kontrolü sayesinde ölür ölmez modeller silinir.
        if not ply:Alive() then
            RemoveVisuals(sid)
            continue
        end
        
        -- Optimizasyon: Oyuncu çizilmiyorsa (uzaktaysa) işlem yapma
        if ply:IsDormant() then continue end

        -- GÖRÜNMEZLİK VE SİLAH YÖNETİMİ
        if ply:GetMaterial() ~= INVISIBLE_MAT then
            ply:SetMaterial(INVISIBLE_MAT)
        end
        
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            if wep:GetMaterial() == INVISIBLE_MAT then wep:SetMaterial("") end
            if wep:GetColor().a ~= 255 then 
                wep:SetColor(Color(255,255,255,255))
                wep:SetRenderMode(RENDERMODE_NORMAL) 
            end
        end
    end
end)

-- EKSTRA GÜVENLİK: Ölüm Anı (Ragdoll düzgün çıksın diye)
hook.Add("PostPlayerDeath", "HLRPG_Cleanup_OnDeath", function(ply)
    local sid = ply:SteamID()
    if Visuals[sid] then
        RemoveVisuals(sid)
    end
    
    -- Ragdoll materyali bozuk çıkmasın diye ölürken de reset atıyoruz
    ply:SetMaterial("")
end)