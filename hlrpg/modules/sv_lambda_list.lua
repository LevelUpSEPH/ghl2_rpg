-- sv_lambda_list.lua

util.AddNetworkString("HLRPG_OpenLambdaMenu")

hook.Add("PlayerSay", "HLRPG_LambdaChatCommand", function(ply, text)
    if string.lower(text) == "!lambda" then
        
        local foundLambdas = ply.HLRPG_FoundLambdas or {} 

        net.Start("HLRPG_OpenLambdaMenu")
            net.WriteTable(foundLambdas)
        net.Send(ply)
        
        return ""
    end
end)