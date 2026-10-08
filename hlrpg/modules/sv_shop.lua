-- hlrpg/modules/sv_shop.lua

util.AddNetworkString("HLRPG_Shop_Purchase")

local PURCHASE_COOLDOWN = 0.5

local function GetBalance(ply, currency)
    if currency == "TP" then return ply.HLRPG_TempPoints or 0 end
    return ply:GetXP()
end

local function Charge(ply, currency, price)
    if currency == "TP" then
        ply.HLRPG_TempPoints = GetBalance(ply, "TP") - price
        ply:SetNWInt("HLRPG_TempPoints", ply.HLRPG_TempPoints)
    else
        ply:ChangeXP(-price)
    end
end

local function Deny(ply, message)
    ply:ChatPrint("[SHOP] " .. message)
    ply:EmitSound("buttons/button11.wav")
end

-- Returns false and a reason if the consumable would do nothing right now
local function CanUseConsumable(ply, item)
    local def = HLRPG.Consumables[item.consumable]
    if not def then return false, "This item is unavailable." end
    if not ply:Alive() or ply.IsZombieForm then return false, "You can't use that right now." end
    return def.CanUse(ply)
end

net.Receive("HLRPG_Shop_Purchase", function(len, ply)
    local itemID = net.ReadString()
    local item = HLRPG.Assets[itemID]
    if not IsValid(ply) or not item or item.unbuyable then return end

    if (ply.HLRPG_NextPurchase or 0) > CurTime() then return end
    ply.HLRPG_NextPurchase = CurTime() + PURCHASE_COOLDOWN

    local isConsumable = item.type == "consumable"

    if not isConsumable and ply:OwnsItem(itemID) then
        Deny(ply, "You already own this item!")
        return
    end

    local currency = item.currency or "XP"
    local price = item.price or 0

    if GetBalance(ply, currency) < price then
        Deny(ply, "Insufficient balance!")
        return
    end

    if isConsumable then
        local canUse, reason = CanUseConsumable(ply, item)
        if not canUse then
            Deny(ply, reason)
            return
        end

        Charge(ply, currency, price)
        HLRPG.Consumables[item.consumable].OnUse(ply, item)
        ply:ChatPrint("[SHOP] Used: " .. item.name)
        return
    end

    Charge(ply, currency, price)
    ply:AddInventoryItem(itemID)

    ply:EmitSound("items/suitchargeok1.wav")
    ply:ChatPrint("[SHOP] Successfully purchased: " .. item.name)
end)
