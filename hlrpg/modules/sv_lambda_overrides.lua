-- hlrpg/modules/sv_lambda_overrides.lua
-- Lambda's own F1-F4 menu (info, votes, player, settings) is replaced by the HLRPG menus: F1 opens the
-- character menu (sv_suit_equipment.lua) and everything else lives in the TAB menu. A hook returning a
-- value stops Lambda's GM:ShowTeam / ShowSpare1 / ShowSpare2 from opening its menu on F2-F4.

for _, hookName in ipairs({ "ShowTeam", "ShowSpare1", "ShowSpare2" }) do
    hook.Add(hookName, "HLRPG_BlockLambdaMenu", function()
        return false
    end)
end
