-- hlrpg/core/sh_util.lua

function HLRPG.IsSafeMap()
    return HLRPG.Config.SafeMaps[game.GetMap()] == true
end

if CLIENT then
    -- Asks the server to open a page that needs server data ("achievements", "lambdas")
    function HLRPG.RequestMenu(name)
        net.Start("HLRPG_RequestMenu")
            net.WriteString(name)
        net.SendToServer()
    end
end

if SERVER then
    HLRPG.ChatCommands = HLRPG.ChatCommands or {}

    -- Registers a chat command such as "!lambda". callback(ply, args) runs and the message is swallowed.
    function HLRPG.AddChatCommand(command, callback)
        HLRPG.ChatCommands[command:lower()] = callback
    end

    hook.Add("PlayerSay", "HLRPG_ChatCommands", function(ply, text)
        local args = string.Explode(" ", string.Trim(text))
        local callback = HLRPG.ChatCommands[args[1]:lower()]
        if not callback then return end

        table.remove(args, 1)
        callback(ply, args)
        return ""
    end)
end
