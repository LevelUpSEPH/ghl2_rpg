-- hlrpg/modules/custom_achievement_listeners/sv_barnacle_bowling.lua
-- HL2_BARNACLE_BOWLING: kill enough barnacles with a single physics prop.

local BARNACLES_REQUIRED = 5

local killsPerProp = {}

hook.Add("OnNPCKilled", "HLRPG_BarnacleBowling_Tracker", function(npc, attacker, inflictor)
    if npc:GetClass() ~= "npc_barnacle" then return end
    if not IsValid(inflictor) or inflictor:GetClass() ~= "prop_physics" then return end

    local propIndex = inflictor:EntIndex()
    killsPerProp[propIndex] = (killsPerProp[propIndex] or 0) + 1

    if killsPerProp[propIndex] >= BARNACLES_REQUIRED then
        HLRPG.AwardAchievementToAll("HL2_BARNACLE_BOWLING")
        killsPerProp[propIndex] = nil
    end
end)

hook.Add("EntityRemoved", "HLRPG_BarnacleBowling_Cleanup", function(ent)
    local propIndex = ent:EntIndex()
    if killsPerProp[propIndex] then
        timer.Simple(2, function() killsPerProp[propIndex] = nil end)
    end
end)
