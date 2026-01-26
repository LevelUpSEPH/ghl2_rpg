-- addons/halflife_rpg/lua/hlrpg/modules/sv_hat_equipment.lua
if not SERVER then return end

util.AddNetworkString("HLRPG_Sync_Hat")

function HLRPG_ApplyHat(ply, hatID)
    if not IsValid(ply) then return end

    -- Toggle
    if ply.HLRPG_ActiveHat == hatID then
        ply.HLRPG_ActiveHat = "none"
    else
        ply.HLRPG_ActiveHat = hatID
    end

    ply:SetNWString("HLRPG_ActiveHat", ply.HLRPG_ActiveHat)

    net.Start("HLRPG_Sync_Hat")
        net.WriteEntity(ply)
        net.WriteString(ply.HLRPG_ActiveHat)
    net.Broadcast()
end