-- hlrpg/modules/sv_vehicles.lua
-- Vehicle page of the TAB menu. Lambda spawns vehicles by itself at checkpoints on maps that have them
-- (one per living player); this only reports that state and lets a player respawn their own vehicle,
-- e.g. when it's stuck or left far behind. Uses Lambda's functions; other gamemodes report "unsupported".

util.AddNetworkString("HLRPG_OpenVehicleMenu")
util.AddNetworkString("HLRPG_VehicleRespawn")

local RESPAWN_COOLDOWN = 10

local function IsSupported()
    return GAMEMODE.RemovePlayerVehicles ~= nil and GAMEMODE.PlayerGetVehicleOwned ~= nil
end

local function MapHasVehicles()
    return GAMEMODE.MapVehicles ~= nil and #GAMEMODE.MapVehicles > 0
end

local function GetOwnedVehicle(ply)
    local vehicle = GAMEMODE:PlayerGetVehicleOwned(ply)
    return IsValid(vehicle) and vehicle or NULL
end

local function SendVehicleMenu(ply)
    local supported = IsSupported()

    net.Start("HLRPG_OpenVehicleMenu")
        net.WriteBool(supported)
        net.WriteBool(supported and MapHasVehicles())
        net.WriteBool(supported and GAMEMODE.SpawnPlayerVehicles == true)
        net.WriteEntity(supported and GetOwnedVehicle(ply) or NULL)
    net.Send(ply)
end

HLRPG.AddMenuRequest("vehicle", SendVehicleMenu)

net.Receive("HLRPG_VehicleRespawn", function(len, ply)
    if not IsSupported() then return end

    if (ply.HLRPG_NextVehicleRespawn or 0) > CurTime() then
        ply:ChatPrint("[VEHICLE] Wait a few seconds before respawning again.")
        return
    end

    local vehicle = GetOwnedVehicle(ply)
    if not IsValid(vehicle) then
        ply:ChatPrint("[VEHICLE] You don't have a vehicle to respawn.")
        return
    end

    if IsValid(vehicle:GetDriver()) then
        ply:ChatPrint("[VEHICLE] Someone is driving your vehicle.")
        return
    end

    ply.HLRPG_NextVehicleRespawn = CurTime() + RESPAWN_COOLDOWN
    GAMEMODE:RemovePlayerVehicles(ply)
    ply:ChatPrint("[VEHICLE] Vehicle removed. A new one will appear at the checkpoint shortly.")
end)
