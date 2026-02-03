-- addons/halflife_rpg/lua/hlrpg/modules/sv_inventory_logic.lua
if not SERVER then return end

util.AddNetworkString("HLRPG_HubAction")

function HLRPG_Inventory_EquipRequest(ply, itemID)
    local itemData = HLRPG_Assets[itemID]
    if not itemData then return end

    if not ply:GetNWBool("HLRPG_Owned_" .. itemID, false) then 
        ply:ChatPrint("[INV] Bu eşyaya sahip değilsin!")
        return 
    end

    local group = itemData.group

    if group == "Suits" or group == "Models" then
        if ply.HLRPG_Suit == itemID or ply.HLRPG_Model == itemData.model then
            ply.HLRPG_Suit = "none"
            ply:SetNWString("HLRPG_ActiveSuit", "")
            ply:SaveSuit()
            model = ply:GetNWString("HLRPG_ActiveModel", "models/player/kleiner.mdl")
            ply:SetModel(model)
            net.Start("HLRPG_Sync_Suit")
                net.WriteEntity(ply)
                net.WriteString("none")
            net.Broadcast()
            ply:ChatPrint("[INV] Zırh/Karakter çıkarıldı.")
        else
            if group == "Suits" then
                ply.HLRPG_Suit = itemID
                ply:SetNWString("HLRPG_ActiveSuit", itemID)
                ply:SaveSuit()
            end
            HLRPG_ApplyEquipment(ply, (group == "Suits" and "suit" or "model"), itemID)
        end

    elseif group == "Hats" then
        if ply.HLRPG_ActiveHat == itemID then
            HLRPG_ApplyHat(ply, "none")
            ply:SaveHat()
        else
            HLRPG_ApplyHat(ply, itemID)
            ply:SaveHat()
        end

    elseif itemData.type == "modifier" then
        local scope = itemData.scope or "Global"
        local modID = itemData.modID

        if ply.RPG_Mods and ply.RPG_Mods[scope] then
            
            for currentModID, _ in pairs(ply.RPG_Mods[scope]) do
                if currentModID == modID then
                    ply:RemoveRPGModifier(currentModID, scope)
                    ply:SetNWBool("HLRPG_ModActive_" .. itemID, false)
                    ply:ChatPrint("[MOD] Özellik devre dışı bırakıldı.")
                    return
                end
                
                ply:RemoveRPGModifier(currentModID, scope)
            end
        end

        HLRPG_ApplyModifier(ply, modID, itemData.modVal, scope)
        ply:SetNWBool("HLRPG_ModActive_" .. itemID, true)

    elseif group == "Pets" then
        if ply.HLRPG_ActivePet == itemID then
            HLRPG_ApplyPet(ply, "none")
        else
            HLRPG_ApplyPet(ply, itemID)
        end
    end
end

function HLRPG_SyncEntireServerToPlayer(newPlayer)
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply ~= newPlayer then
            if ply.HLRPG_ActiveHat and ply.HLRPG_ActiveHat ~= "none" then
                net.Start("HLRPG_Sync_Hat")
                    net.WriteEntity(ply)
                    net.WriteString(ply.HLRPG_ActiveHat)
                net.Send(newPlayer)
            end

            if ply.HLRPG_Suit and ply.HLRPG_Suit ~= "none" then
                net.Start("HLRPG_Sync_Suit")
                    net.WriteEntity(ply)
                    net.WriteString(ply.HLRPG_Suit)
                net.Send(newPlayer)
            end
        end
    end
end

function HLRPG_GiveItem(ply, itemID, reason)
    if not IsValid(ply) or not itemID then return false end
    
    local inv = ply:GetInventory()
    if inv[itemID] then return false end

    inv[itemID] = true
    ply.HLRPG_Inventory = inv
    ply:SaveInventory()
    
    ply:SetNWBool("HLRPG_Owned_" .. itemID, true)
    
    local itemData = HLRPG_Assets[itemID]
    local itemName = itemData and itemData.name or itemID
    ply:ChatPrint("[INVENTORY] Yeni eşya: " .. itemName .. " (" .. (reason or "Sistem") .. ")")
    
    return true
end

hook.Add("PlayerInitialSpawn", "HLRPG_Sync_LateJoiners", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then
            HLRPG_SyncEntireServerToPlayer(ply)
        end
    end)
end)

net.Receive("HLRPG_HubAction", function(len, ply)
    local action = net.ReadString() -- "equip"
    local id = net.ReadString()
    
    if action == "equip" then
        HLRPG_Inventory_EquipRequest(ply, id)
    end
end)