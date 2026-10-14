-- hlrpg/modules/sv_player.lua

util.AddNetworkString("HLRPG_ClientReady")

-- Sent by the client once it has finished loading (cl_suit_visuals.lua). Messages sent before that, like the
-- player's own suit and hat right after their data loads on a reconnect, can be lost, so controllers resend
-- what the client needs from hook.Add("HLRPG_ClientReady", ..., function(ply) end).
net.Receive("HLRPG_ClientReady", function(len, ply)
    if ply.HLRPG_ClientReady then return end
    ply.HLRPG_ClientReady = true
    hook.Run("HLRPG_ClientReady", ply)
end)

-- Welcome message: the saved one (rpg_welcome) if set, else the config default
local WELCOME_FILE = "hlrpg/welcome.txt"

function HLRPG.GetWelcomeMessage()
    local saved = file.Read(WELCOME_FILE, "DATA")
    return (saved and saved ~= "") and saved or HLRPG.Config.WelcomeMessage
end

function HLRPG.SetWelcomeMessage(text)
    file.CreateDir("hlrpg")
    file.Write(WELCOME_FILE, text)
end

function HLRPG.FormatWelcome(ply)
    return (string.gsub(HLRPG.GetWelcomeMessage(), "{name}", function() return ply:Nick() end))
end

hook.Add("PlayerInitialSpawn", "HLRPG_InitialLoad", function(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end

        ply:InitialRPGSetup()
        ply:ChatPrint(HLRPG.FormatWelcome(ply))
    end)
end)
