-- addons/halflife_rpg/lua/hlrpg/modules/sv_inventory_logic.lua
if not SERVER then return end

function HLRPG_AddInventoryItem(ply, itemID)
    if not IsValid(ply) or not itemID then return end
    ply:SetNWBool("HLRPG_Owned_" .. itemID, true)
end

function HLRPG_Inventory_EquipRequest(ply, itemID)
    local itemData = HLRPG_Assets[itemID]
    if not itemData then return end

    local group = itemData.group

    if group == "Suits" then
        HLRPG_ApplyEquipment(ply, "suit", itemID) -- Senin sv_equipment'taki suit logic'in
    elseif group == "Hats" then
        HLRPG_ApplyHat(ply, itemID) -- Yeni hat logic'i
    elseif group == "Pets" then
        HLRPG_ApplyPet(ply, itemID) -- Yeni pet logic'i
    elseif group == "Models" then
        HLRPG_ApplyEquipment(ply, "model", itemData.model) -- Karakter değişimi
    end
end