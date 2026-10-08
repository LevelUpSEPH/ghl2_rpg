-- hlrpg/modules/sv_player.lua

hook.Add("PlayerInitialSpawn", "HLRPG_InitialLoad", function(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end

        ply:InitialRPGSetup()
        ply:ChatPrint(string.format(HLRPG.Config.WelcomeMessage, ply:Nick()))
    end)
end)
