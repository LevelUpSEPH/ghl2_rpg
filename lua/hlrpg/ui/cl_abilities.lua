-- hlrpg/ui/cl_abilities.lua
-- Client-side ability callbacks for the local player's equipped items (see core/sh_abilities.lua).

local function RunLocal(hookName)
    local ply = LocalPlayer()
    if IsValid(ply) and ply:Alive() then
        HLRPG.RunAbilityHook(ply, hookName)
    end
end

hook.Add("RenderScreenspaceEffects", "HLRPG_AbilityScreen", function() RunLocal("RenderScreen") end)
hook.Add("PreDrawHalos", "HLRPG_AbilityHalos", function() RunLocal("DrawHalos") end)
hook.Add("HUDPaint", "HLRPG_AbilityHUD", function() RunLocal("HUDPaint") end)
