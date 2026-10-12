-- hlrpg/modules/sv_map_restart_manager.lua
-- Sends an empty server back to the campaign start (see HLRPG.Config.MapReset).

local cfg = HLRPG.Config.MapReset

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
        if #player.GetAll() == 0 and game.GetMap() ~= cfg.Map then
            print("[HLRPG] Changing map to " .. cfg.Map .. ".")
            RunConsoleCommand("changelevel", cfg.Map)
        end
    end)
end)
