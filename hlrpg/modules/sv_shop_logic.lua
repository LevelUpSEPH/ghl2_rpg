-- sv_shop_logic.lua

local shopCooldowns = {}

util.AddNetworkString("HLRPG_Shop_Purchase")

net.Receive("HLRPG_Shop_Purchase", function(len, ply)
    local itemID = net.ReadString()
    local itemData = HLRPG_Assets[itemID]
    
    if not IsValid(ply) or not itemData then return end

    local curTime = CurTime()
    if (shopCooldowns[ply] or 0) > curTime then return end
    shopCooldowns[ply] = curTime + 0.5

    local inv = ply:GetInventory()
    if itemData.group != "Temporary Upgrades" then
        if inv[itemID] then
            ply:ChatPrint("[SHOP] Bu eşyaya zaten sahipsin!")
            return
        end
    end

    local currency = itemData.currency or "XP"
    local price = itemData.price or 0
    local currentBal = (currency == "TP") and (ply.HLRPG_TempPoints or 0) or ply:GetXP()

    if currentBal >= price then
        if currency == "TP" then
            ply.HLRPG_TempPoints = currentBal - price
            ply:SetNWInt("HLRPG_TempPoints", ply.HLRPG_TempPoints)
        else
            local newXP = currentBal - price
            ply:SaveXP(-price)
            ply:SetNWInt("HLRPG_XP", newXP)
        end

        -- ENVANTERE EKLE VE KAYDET
        inv[itemID] = true
        ply.HLRPG_Inventory = inv
        ply:SaveInventory()
        
        ply:SetNWBool("HLRPG_Owned_" .. itemID, true)

        ply:EmitSound("items/suitchargeok1.wav")
        ply:ChatPrint("[SHOP] Başarıyla satın alındı: " .. itemData.name)
    else
        ply:ChatPrint("[SHOP] Yetersiz bakiye!")
        ply:EmitSound("buttons/button11.wav")
    end
end)