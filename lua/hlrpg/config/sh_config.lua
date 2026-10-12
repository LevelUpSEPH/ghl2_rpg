-- hlrpg/config/sh_config.lua
-- Server operator settings. Game content (items, NPCs, pets...) lives in hlrpg/core/.

HLRPG.Config = {}

-- %s is replaced with the player's name
HLRPG.Config.WelcomeMessage = ">>> Welcome, %s! Join our discord at: https://discord.gg/d588UVcpzD <<<"

-- Workshop items clients download on join
HLRPG.Config.WorkshopContent = {
    "780244493",  -- Lambda - Half-Life 2 Co-Op content
    "3320656757", -- Gordon Freeman Restored (HEV Suit model)
}

-- Pets cannot be summoned on these maps
HLRPG.Config.SafeMaps = {
    ["d1_trainstation_01"] = true,
    ["d1_trainstation_02"] = true,
    ["d1_trainstation_03"] = true,
    ["d1_trainstation_04"] = true,
    ["d1_trainstation_05"] = true,
    ["d1_trainstation_06"] = true,
}

-- When the server has been empty for EmptyWait seconds, change to Map
HLRPG.Config.MapReset = {
    Map = "d1_trainstation_01",
    EmptyWait = 1800,
    CheckInterval = 60,
}

-- Base player models selectable from the F1 menu
HLRPG.Config.Models = {
    { name = "Rebel Male", model = "models/player/group01/male_02.mdl" },
    { name = "Rebel Male", model = "models/player/group01/male_04.mdl" },
    { name = "Rebel Male", model = "models/player/group01/male_07.mdl" },
    { name = "Rebel Male", model = "models/player/group01/male_09.mdl" },
    { name = "Rebel Female", model = "models/player/group01/female_01.mdl" },
}
