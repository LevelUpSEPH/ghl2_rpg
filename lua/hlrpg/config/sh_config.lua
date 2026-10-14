-- hlrpg/config/sh_config.lua
-- Server operator settings. Game content (items, NPCs, pets...) lives in hlrpg/core/.

HLRPG.Config = {}

-- Default welcome message; {name} is replaced with the player's name. Admins can change it in-game or from the
-- server console with rpg_welcome, which saves it to data/hlrpg/welcome.txt and overrides this default.
HLRPG.Config.WelcomeMessage = ">>> Welcome, {name}! <<<"

-- Workshop items clients download on join. Lambda isn't one of them: the server's own (non-Workshop) copy of the
-- gamemode sends its content to players itself, and mixing it with the Workshop release breaks the gamemode.
HLRPG.Config.WorkshopContent = {
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
