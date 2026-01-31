-- addons/halflife_rpg/lua/hlrpg/modules/sv_equipment.lua

if not SERVER then return end

util.AddNetworkString("HLRPG_OpenMenu")
util.AddNetworkString("HLRPG_EquipItem")
util.AddNetworkString("HLRPG_Sync_Suit")

local function SetHandsDirectly(ply)
    if not IsValid(ply) then return end
    
    local suitID = ply.HLRPG_Suit
    if not suitID or suitID == "none" then return end

    local suitData = nil
    for _, s in ipairs(HLRPG.Config.Suits) do
        if s.id == suitID then suitData = s; break end
    end

    if not suitData or not suitData.hands then return end

    ply:SetupHands()

    local hands = ply:GetHands()
    if IsValid(hands) then
        hands:SetModel(suitData.hands)
        
        if suitData.skin then
            hands:SetSkin(suitData.skin)
        end
        
        hands:SetRenderMode(RENDERMODE_NORMAL)
        hands:SetColor(Color(255, 255, 255, 255))
        
        print("[HLRPG] Eller Zorla Degistirildi: " .. suitData.hands)
    else
        print("[HLRPG] HATA: Oyuncunun el entity'si bulunamadı!")
    end
end

hook.Add("ShowHelp", "HLRPG_Override_F1", function(ply)
    net.Start("HLRPG_OpenMenu")
    net.Send(ply)
    return false
end)

function HLRPG_ApplyEquipment(ply, type, value)
    if not IsValid(ply) then return end
    
    print("[HLRPG] Equip Islemi Baslatildi: Type=" .. type .. ", Value=" .. value)

    if type == "model" then
        ply:SetModel(value)
        ply.HLRPG_Model = value
        ply:SetNWString("HLRPG_ActiveModel", value)
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
            ply:SetNWString("HLRPG_ActiveSuit", value)
            net.Start("HLRPG_Sync_Suit")
                net.WriteEntity(ply)
                net.WriteString(suitData.model or "none")
            net.Broadcast()
            
            timer.Simple(0.1, function()
                if IsValid(ply) then SetHandsDirectly(ply) end
            end)
        else
            print("[HLRPG] HATA: Suit verisi bulunamadi: " .. value)
        end
    end
end

net.Receive("HLRPG_EquipItem", function(len, ply)
    local type = net.ReadString()
    local value = net.ReadString()
    
    HLRPG_ApplyEquipment(ply, type, value)
end)

hook.Add("PlayerSetHands", "HLRPG_Hook_SetHands", function(ply, ent)
    if not ply.HLRPG_Suit or ply.HLRPG_Suit == "none" then return end

    local suitData = nil
    for _, s in ipairs(HLRPG.Config.Suits) do
        if s.id == ply.HLRPG_Suit then suitData = s; break end
    end

    if suitData and suitData.hands then
        ent:SetModel(suitData.hands)
        if suitData.skin then ent:SetSkin(suitData.skin) end
        print("[HLRPG] Hook Tetiklendi!")
        return true
    end
end)

hook.Add("PlayerSpawn", "HLRPG_Spawn_Hands", function(ply)
    timer.Simple(0.2, function()
        if not IsValid(ply) then return end
        
        if ply.HLRPG_Model then ply:SetModel(ply.HLRPG_Model) end
        
        if ply.HLRPG_Suit then
            local sModel = "none"
            for _, s in ipairs(HLRPG.Config.Suits) do
                if s.id == ply.HLRPG_Suit then sModel = s.model; break end
            end
            net.Start("HLRPG_Sync_Suit")
            net.WriteEntity(ply)
            net.WriteString(sModel or "none")
            net.Broadcast()
            
            SetHandsDirectly(ply)
        end
    end)
end)

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