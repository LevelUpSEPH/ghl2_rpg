-- addons/halflife_rpg/lua/hlrpg/modules/sv_shop_logic.lua
if not SERVER then return end

util.AddNetworkString("HLRPG_Shop_Purchase")

net.Receive("HLRPG_Shop_Purchase", function(len, ply)
    local itemID = net.ReadString()
    local itemData = HLRPG_Assets[itemID]
    if not itemData then return end

    -- Bakiye Kontrolü
    local currency = itemData.currency or "XP"
    local price = itemData.price or 0
    local currentBal = (currency == "TP") and (ply.HLRPG_TempPoints or 0) or (ply.HLRPG_XP or 0)

    if currentBal >= price then
        -- Ödeme
        if currency == "TP" then
            ply.HLRPG_TempPoints = currentBal - price
            ply:SetNWInt("HLRPG_TempPoints", ply.HLRPG_TempPoints)
        else
            ply.HLRPG_XP = currentBal - price
            ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
        end

        -- Sahiplik Verme (NWBool üzerinden inventory'de görünmesi için)
        ply:SetNWBool("HLRPG_Owned_" .. itemID, true)

        -- Eğer bu bir modifier (upgrade) ise aktif et
        if itemData.modifier and ply.AddRPGModifier then
            ply:AddRPGModifier(itemData.modifier, itemData.modVal)
        end

        ply:EmitSound("items/suitchargeok1.wav")
        ply:ChatPrint("[SHOP] Satın alındı: " .. itemData.name)
    else
        ply:ChatPrint("[SHOP] Yetersiz bakiye!")
    end
end)