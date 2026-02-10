if not SERVER then return end

local RESET_MAP = "d1_trainstation_01"
local WAIT_TIME = 1800
local CHECK_INTERVAL = 60

timer.Create("HLRPG_EmptyServerCheck", CHECK_INTERVAL, 0, function()
    if #player.GetAll() == 0 then
        if not timer.Exists("HLRPG_MapResetTimer") then
            print("[HLRPG] Server is empty, map will be reset in " .. (WAIT_TIME / 60) .. " minutes.")
            
            timer.Create("HLRPG_MapResetTimer", WAIT_TIME, 1, function()
                if #player.GetAll() == 0 and game.GetMap() != RESET_MAP then
                    print("[HLRPG] Changing map " .. RESET_MAP .. " as requested.")
                    RunConsoleCommand("changelevel", RESET_MAP)
                end
            end)
        end
    else
        if timer.Exists("HLRPG_MapResetTimer") then
            print("[HLRPG] Map reset to trainstation canceled, players have joined.")
            timer.Remove("HLRPG_MapResetTimer")
        end
    end
end)