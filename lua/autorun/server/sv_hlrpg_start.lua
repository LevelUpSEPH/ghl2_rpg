-- lua/autorun/server/sv_hlrpg_start.lua
-- Some hosts start every server with a fixed command line (+gamemode sandbox +map gm_flatgrass) that can't be
-- edited. On a dedicated server, this switches to the HL2:RPG setup instead: the Half-Life 2 Campaign gamemode
-- (gamemodes/hl2campaign, Lambda under its own name) on the first campaign map. Change START_MAP to begin on
-- Episode One (ep1_citadel_00) or Two (ep2_outland_01).

local TARGET_GAMEMODE = "hl2campaign"
local START_MAP = "d1_trainstation_01"

hook.Add("Initialize", "HLRPG_DedicatedStart", function()
    if not game.IsDedicated() or engine.ActiveGamemode() == TARGET_GAMEMODE then return end

    -- Without these checks a missing gamemode or map would restart the map forever
    for _, gm in ipairs({ TARGET_GAMEMODE, "lambda" }) do -- ours, and Lambda which it's built on
        if not file.Exists("gamemodes/" .. gm .. "/" .. gm .. ".txt", "GAME") then
            print("[HLRPG] Not switching to " .. TARGET_GAMEMODE .. ": the " .. gm .. " gamemode is not installed.")
            return
        end
    end
    if not file.Exists("maps/" .. START_MAP .. ".bsp", "GAME") then
        print("[HLRPG] Not switching: map " .. START_MAP .. " not found. Is Half-Life 2 mounted (cfg/mount.cfg)?")
        return
    end

    print("[HLRPG] Switching to " .. TARGET_GAMEMODE .. " on " .. START_MAP)
    timer.Simple(1, function()
        RunConsoleCommand("gamemode", TARGET_GAMEMODE)
        RunConsoleCommand("changelevel", START_MAP)
    end)
end)
