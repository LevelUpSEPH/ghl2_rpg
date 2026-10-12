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

-- HUD elements hidden by the local player's abilities (HideHUD in sh_abilities.lua)
local hiddenHUD, hiddenFrame = {}, -1

hook.Add("HUDShouldDraw", "HLRPG_AbilityHideHUD", function(name)
    if hiddenFrame ~= FrameNumber() then
        hiddenFrame = FrameNumber()
        hiddenHUD = {}
        local ply = LocalPlayer()
        if IsValid(ply) and ply:Alive() then
            for _, ability in ipairs(HLRPG.GetActiveAbilities(ply)) do
                local def = HLRPG.Abilities[ability.id]
                if def and def.HideHUD then
                    for element in pairs(def.HideHUD) do hiddenHUD[element] = true end
                end
            end
        end
    end
    if hiddenHUD[name] then return false end
end)
