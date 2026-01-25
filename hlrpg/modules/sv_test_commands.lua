-- addons/halflife_rpg/lua/hlrpg/modules/sv_test_commands.lua
if not SERVER then return end

concommand.Add("rpg_inventory_getall", function(ply)
    if not IsValid(ply) then return end
    
    local ownedItems = {}
    for id, info in pairs(HLRPG_Assets or {}) do
        if ply:GetNWBool("HLRPG_Owned_" .. id, false) then
            table.insert(ownedItems, {id = id, name = info.name, group = info.group})
        end
    end

    ply:ChatPrint("======= SENİN ENVANTERİN =======")
    if #ownedItems == 0 then
        ply:ChatPrint("Envanterin bomboş...")
    else
        for _, item in ipairs(ownedItems) do
            ply:ChatPrint(string.format("[%s] %s (ID: %s)", item.group, item.name, item.id))
        end
    end
    ply:ChatPrint("================================")
end)

concommand.Add("rpg_shop_buy", function(ply, cmd, args)
    if not IsValid(ply) then return end
    local itemID = args[1]
    if not itemID then return end

    ply:ConCommand("say [TEST] " .. itemID .. " satın alınmaya çalışılıyor...")
    
    ply:SetNWBool("HLRPG_Owned_" .. itemID, true)
    ply:ChatPrint(itemID .. " sahipliği zorla verildi (Debug).")
end)

concommand.Add("rpg_inventory_equip", function(ply, cmd, args)
    local itemID = args[1]
    local itemData = HLRPG_Assets[itemID]
    if not itemData then return end

    if not ply:GetNWBool("HLRPG_Owned_" .. itemID, false) then return end

    local equipType = (itemData.group == "Suits") and "suit" or "model"
    local equipValue = (equipType == "suit") and itemID or itemData.model

    HLRPG_ApplyEquipment(ply, equipType, equipValue)
end)

concommand.Add("rpg_give_money", function(ply, cmd, args)
    if not IsValid(ply) then return end
    local amt = tonumber(args[1]) or 5000
    ply.HLRPG_XP = (ply.HLRPG_XP or 0) + amt
    ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
    ply:ChatPrint(amt .. " XP verildi.")
end)