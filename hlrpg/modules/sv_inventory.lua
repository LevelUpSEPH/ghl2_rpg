-- hlrpg/modules/sv_inventory.lua
-- Routes equip requests to the controller for each item group. Every group holds one item at a time.

util.AddNetworkString("HLRPG_HubAction")

function HLRPG.GiveItem(ply, itemID, reason)
    if not IsValid(ply) or not itemID or ply:OwnsItem(itemID) then return false end

    ply:AddInventoryItem(itemID)

    local item = HLRPG.Assets[itemID]
    ply:ChatPrint("[INVENTORY] New item: " .. (item and item.name or itemID) .. " (" .. (reason or "System") .. ")")
    return true
end

function HLRPG.EquipItem(ply, itemID)
    local item = HLRPG.Assets[itemID]
    if not item then return end

    if not ply:OwnsItem(itemID) then
        ply:ChatPrint("[INV] You don't own this item!")
        return
    end

    if item.group == "Suits" then
        HLRPG.ToggleSuit(ply, itemID)
    elseif item.group == "Hats" then
        HLRPG.ToggleHat(ply, itemID)
    elseif item.type == "modifier" then
        HLRPG.ToggleModifierItem(ply, itemID)
    elseif item.group == "Pets" then
        HLRPG.TogglePet(ply, itemID)
    end
end

net.Receive("HLRPG_HubAction", function(len, ply)
    local action = net.ReadString()
    local itemID = net.ReadString()

    if action == "equip" then
        HLRPG.EquipItem(ply, itemID)
    end
end)
