-- hlrpg/modules/sv_map_restart_manager.lua
-- Sends an empty server back to the campaign start (see HLRPG.Config.MapReset), and makes the maps in
-- HLRPG.Config.FullReloadMaps restart by loading again instead of Lambda's cleanup.

local cfg = HLRPG.Config.MapReset

-- Whether anyone has played on this map since it loaded (a map change reloads all Lua, so this starts false)
local played = false
hook.Add("PlayerInitialSpawn", "HLRPG_MapPlayed", function() played = true end)

timer.Create("HLRPG_EmptyServerCheck", cfg.CheckInterval, 0, function()
    if #player.GetAll() > 0 then
        if timer.Exists("HLRPG_MapResetTimer") then
            print("[HLRPG] Map reset canceled, players have joined.")
            timer.Remove("HLRPG_MapResetTimer")
        end
        return
    end

    if timer.Exists("HLRPG_MapResetTimer") then return end

    print("[HLRPG] Server is empty, map will be reset in " .. (cfg.EmptyWait / 60) .. " minutes.")

    timer.Create("HLRPG_MapResetTimer", cfg.EmptyWait, 1, function()
        if #player.GetAll() == 0 and (game.GetMap() ~= cfg.Map or played) then
            print("[HLRPG] Changing map to " .. cfg.Map .. ".")
            RunConsoleCommand("changelevel", cfg.Map)
        end
    end)
end)

-- Full reloads: Lambda restarts a map by cleaning it up (GM:CleanUpMap); on these maps that becomes a changelevel
-- to the same map. Lambda's own cleanup while a round starts (when the first players arrive) is left alone, or
-- the map would reload forever.
local function ReloadMap()
    local map = game.GetMap()
    print("[HLRPG] Reloading " .. map .. " from scratch.")
    game.SetTimeScale(1) -- Lambda slows time down during its restart countdown
    if GAMEMODE.RequestChangeLevel then
        GAMEMODE.ChangingLevel = nil -- a pending restart isn't a level change
        GAMEMODE:RequestChangeLevel(map, nil, {}, {}, true)
    else
        RunConsoleCommand("changelevel", map)
    end
end

hook.Add("Initialize", "HLRPG_FullReloadMaps", function()
    if not HLRPG.Config.FullReloadMaps[game.GetMap():lower()] then return end
    if not GAMEMODE.CleanUpMap or not GAMEMODE.StartRound then return end

    local startingRound = false
    local originalStartRound, originalCleanUpMap = GAMEMODE.StartRound, GAMEMODE.CleanUpMap

    GAMEMODE.StartRound = function(self, ...)
        startingRound = true
        local ok, err = pcall(originalStartRound, self, ...)
        startingRound = false
        if not ok then error(err, 0) end
    end

    GAMEMODE.CleanUpMap = function(self, ...)
        if startingRound then return originalCleanUpMap(self, ...) end
        ReloadMap()
    end
end)
