-- addons/halflife_rpg/lua/hlrpg/modules/sv_equipment.lua
if not SERVER then return end

util.AddNetworkString("HLRPG_EquipItem")
util.AddNetworkString("HLRPG_Sync_Suit")

-- ==========================================
-- SLOT CONTROLLERS (MANTIK BURADA AYRILIYOR)
-- ==========================================

local EquipmentControllers = {}

-- 1. SUIT CONTROLLER (Model & Eller)
EquipmentControllers["suit"] = function(ply, id, info)
    ply:SetNWString("HLRPG_ActiveSuit", id)
    
    if info.model then
        ply:SetModel(info.model)
        ply.HLRPG_Model = info.model
    end

    -- Görsel Senkronizasyon (Broadcasting)
    net.Start("HLRPG_Sync_Suit")
        net.WriteEntity(ply)
        net.WriteString(info.model or "none")
    net.Broadcast()

    -- Eller
    timer.Simple(0.1, function()
        if IsValid(ply) then
            ply:SetupHands()
            local hands = ply:GetHands()
            if IsValid(hands) and info.hands then
                hands:SetModel(info.hands)
                if info.skin then hands:SetSkin(info.skin) end
                hands:SetRenderMode(RENDERMODE_NORMAL)
                hands:SetColor(Color(255, 255, 255, 255))
            end
        end
    end)
    
    return "Zırh kuşandın: " .. info.name
end

-- 2. HAT CONTROLLER (Aksesuar)
EquipmentControllers["hat"] = function(ply, id, info)
    ply:SetNWString("HLRPG_ActiveHat", id)
    -- Şimdilik sadece NWString setliyoruz, 
    -- İleride buraya şapkayı BoneMerge ile oyuncuya takan fonksiyona çağrı gelecek.
    return "Şapka kuşandın: " .. info.name
end

-- 3. PET CONTROLLER (Takipçi)
EquipmentControllers["pet"] = function(ply, id, info)
    ply:SetNWString("HLRPG_ActivePet", id)
    -- İleride buraya pet spawn eden fonksiyon gelecek.
    return "Pet yanına çağrıldı: " .. info.name
end

-- ==========================================
-- MERKEZİ NET RECEIVER
-- ==========================================

net.Receive("HLRPG_EquipItem", function(len, ply)
    local slotType = net.ReadString() -- "suit", "hat", "pet"
    local id = net.ReadString()
    local info = HLRPG_Assets[id]

    if not info then return end

    -- 1. Sahiplik Kontrolü
    if not ply:GetNWBool("HLRPG_Owned_" .. id, false) then 
        ply:ChatPrint("[HUB] Bu eşyaya sahip değilsin!")
        return 
    end

    -- 2. Controller'ı Çalıştır
    local controller = EquipmentControllers[slotType]
    if controller then
        local message = controller(ply, id, info)
        ply:ChatPrint("[HUB] " .. message)
        ply:EmitSound("items/suitchargeok1.wav")
    else
        ply:ChatPrint("[DEBUG] Bu slot tipi için controller bulunamadı: " .. tostring(slotType))
    end
end)

-- ==========================================
-- SPAWN & RESYNC HOOKS (SÜREKLİLİK)
-- ==========================================

hook.Add("PlayerSpawn", "HLRPG_RestoreEquipment", function(ply)
    timer.Simple(0.2, function()
        if not IsValid(ply) then return end
        
        -- Aktif suit'i geri yükle (Diğer slotlar eklendikçe buraya da eklenecek)
        local activeSuitID = ply:GetNWString("HLRPG_ActiveSuit", "")
        local suitInfo = HLRPG_Assets[activeSuitID]
        
        if suitInfo then
            EquipmentControllers["suit"](ply, activeSuitID, suitInfo)
        end
    end)
end)

-- Engine SetHands çağrısı için fallback
hook.Add("PlayerSetHands", "HLRPG_Hook_SetHands", function(ply, ent)
    local activeSuitID = ply:GetNWString("HLRPG_ActiveSuit", "")
    local info = HLRPG_Assets[activeSuitID]

    if info and info.hands then
        ent:SetModel(info.hands)
        if info.skin then ent:SetSkin(info.skin) end
        return true
    end
end)