-- hlrpg/modules/sv_debug_commands.lua
-- Admin-only console commands for testing items and abilities.

local function AddAdminCommand(name, callback)
    concommand.Add(name, function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsAdmin() then return end
        callback(ply, args)
    end)
end

-- rpg_giveitem <itemID>: adds an item to your inventory for free
AddAdminCommand("rpg_giveitem", function(ply, args)
    local itemID = args[1]
    if not HLRPG.Assets[itemID or ""] then
        ply:ChatPrint("Unknown item: " .. tostring(itemID))
        return
    end
    HLRPG.GiveItem(ply, itemID, "Admin")
end)

-- rpg_abilities: lists every ability active right now (weapon-scoped ones depend on the weapon you hold)
AddAdminCommand("rpg_abilities", function(ply)
    ply:ChatPrint("--- ACTIVE ABILITIES ---")
    for _, itemID in ipairs(HLRPG.GetEquippedItems(ply)) do
        local item = HLRPG.Assets[itemID]
        local scope = item.scope and (" [" .. item.scope .. "]") or ""
        ply:ChatPrint(item.name .. scope .. ": " .. HLRPG.DescribeAbilities(item))
    end
end)
