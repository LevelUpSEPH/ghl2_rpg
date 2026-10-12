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

hook.Add("PlayerInitialSpawn", "HLRPG_InitialLoad", function(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end

        ply:InitialRPGSetup()
        ply:ChatPrint(string.format(HLRPG.Config.WelcomeMessage, ply:Nick()))
    end)
end)
