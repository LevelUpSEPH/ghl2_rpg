-- addons/halflife_rpg/lua/hlrpg/modules/sv_inventory_logic.lua
if not SERVER then return end

function HLRPG_AddInventoryItem(ply, itemID)
    if not IsValid(ply) or not itemID then return end
    ply:SetNWBool("HLRPG_Owned_" .. itemID, true)
end

function HLRPG_Inventory_EquipRequest(ply, itemID)
    local itemData = HLRPG_Assets[itemID]
    if not itemData then return end

    if not ply:GetNWBool("HLRPG_Owned_" .. itemID, false) then
        ply:ChatPrint("[INV] Bu eşyaya sahip değilsin!")
        return
    end

    local equipType = ""
    local equipValue = ""

    if itemData.group == "Suits" then
        equipType = "suit"
        equipValue = itemID
    elseif itemData.group == "Models" then
        equipType = "model"
        equipValue = itemData.model
    end
    
    net.Start("HLRPG_EquipItem")
    net.WriteString(equipType)
    net.WriteString(equipValue)
    net.Send(ply)
end