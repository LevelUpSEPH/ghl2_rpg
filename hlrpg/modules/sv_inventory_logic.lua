-- addons/halflife_rpg/lua/hlrpg/modules/sv_inventory_logic.lua
if not SERVER then return end

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
            ply:SetModel(ply.HLRPG_DefaultModel or "models/player/kleiner.mdl")
            net.Start("HLRPG_Sync_Suit")
                net.WriteEntity(ply)
                net.WriteString("none")
            net.Broadcast()
            ply:ChatPrint("[INV] Zırh/Karakter çıkarıldı.")
        else
            HLRPG_ApplyEquipment(ply, (group == "Suits" and "suit" or "model"), itemID)
        end

    elseif group == "Hats" then
        if ply.HLRPG_ActiveHat == itemID then
            HLRPG_ApplyHat(ply, "none")
        else
            HLRPG_ApplyHat(ply, itemID)
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