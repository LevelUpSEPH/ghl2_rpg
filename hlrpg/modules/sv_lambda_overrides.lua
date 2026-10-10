-- hlrpg/modules/sv_lambda_overrides.lua
-- Lambda's own F1-F4 menu (info, votes, player, settings) is replaced by the HLRPG menus: F1 opens the
-- character menu (sv_suit_equipment.lua) and everything else lives in the TAB menu. A hook returning a
-- value stops Lambda's GM:ShowTeam / ShowSpare1 / ShowSpare2 from opening its menu on F2-F4.

for _, hookName in ipairs({ "ShowTeam", "ShowSpare1", "ShowSpare2" }) do
    hook.Add(hookName, "HLRPG_BlockLambdaMenu", function()
        return false
    end)
end

-- Lambda handles NPC melee hits on players (claws, stunsticks) after our EntityTakeDamage hook, and its
-- ApplyCorrectedDamage *sets* a fixed per-weapon damage, wiping the NPC level scaling from sv_combat.lua.
-- Re-apply it when that happens. Only melee: for bullets Lambda runs this before our hook, which then
-- scales normally.
local MELEE_DAMAGE = bit.bor(DMG_CLUB, DMG_SLASH)

hook.Add("Initialize", "HLRPG_LambdaDamageScaling", function()
    local applyCorrectedDamage = GAMEMODE.ApplyCorrectedDamage
    if not applyCorrectedDamage then return end

    function GAMEMODE:ApplyCorrectedDamage(dmginfo)
        local before = dmginfo:GetDamage()
        applyCorrectedDamage(self, dmginfo)

        local attacker = dmginfo:GetAttacker()
        if dmginfo:GetDamage() ~= before and bit.band(dmginfo:GetDamageType(), MELEE_DAMAGE) ~= 0
            and HLRPG.IsLeveledNPC(attacker) then
            dmginfo:ScaleDamage(HLRPG.GetNPCDamageMultiplier(attacker))
        end

        return dmginfo
    end
end)
