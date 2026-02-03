-- addons/halflife_rpg/lua/hlrpg/modules/sv_test_commands.lua
if not SERVER then return end

concommand.Add("rpg_give_money", function(ply, cmd, args)
    if not IsValid(ply) then return end
    local amt = tonumber(args[1]) or 5000
    ply.HLRPG_XP = (ply.HLRPG_XP or 0) + amt
    ply:SetNWInt("HLRPG_XP", ply.HLRPG_XP)
    ply:ChatPrint(amt .. " XP verildi.")
end)