-- hlrpg/modules/sv_hat_equipment.lua
-- Hats are drawn client-side (cl_hat_visuals.lua); the server only tracks and syncs the active one.

util.AddNetworkString("HLRPG_Sync_Hat")

-- Sends ply's hat to target, or to everyone if target is nil
local function SendHat(ply, target)
    net.Start("HLRPG_Sync_Hat")
        net.WriteEntity(ply)
        net.WriteString(ply.HLRPG_ActiveHat or "none")
    if target then net.Send(target) else net.Broadcast() end
end

-- hatID "none" removes the current hat
function HLRPG.ApplyHat(ply, hatID)
    if not IsValid(ply) then return end

    local oldHatID = ply.HLRPG_ActiveHat or "none"
    ply.HLRPG_ActiveHat = hatID
    ply:SetNWString("HLRPG_ActiveHat", hatID)
    SendHat(ply)
    HLRPG.OnEquipmentChanged(ply, oldHatID, hatID)
    hook.Run("HLRPG_HatChanged", ply, hatID)
end

function HLRPG.ToggleHat(ply, hatID)
    HLRPG.ApplyHat(ply, ply.HLRPG_ActiveHat == hatID and "none" or hatID)
    ply:SaveHat()
end

-- Late joiners need everyone else's hats
-- A client that just finished loading needs every hat, its own included
hook.Add("HLRPG_ClientReady", "HLRPG_Sync_Hats", function(newPly)
    for _, ply in ipairs(player.GetAll()) do
        if ply.HLRPG_ActiveHat and ply.HLRPG_ActiveHat ~= "none" then SendHat(ply, newPly) end
    end
end)
