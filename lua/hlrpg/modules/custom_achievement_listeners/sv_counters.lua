-- hlrpg/modules/custom_achievement_listeners/sv_counters.lua
-- Feeds the progress counters used by General achievements (core/sh_achievements.lua).

local groupByClass = {}
for groupID, group in pairs(HLRPG.KillCounterGroups) do
    for _, class in ipairs(group.classes) do groupByClass[class] = groupID end
end

hook.Add("OnNPCKilled", "HLRPG_KillCounters", function(npc, attacker)
    local groupID = groupByClass[npc:GetClass()]
    if groupID and IsValid(attacker) and attacker:IsPlayer() and not npc.IsHLRPGPet then
        HLRPG.AddCounter(attacker, "kills_" .. groupID)
    end
end)

hook.Add("PlayerDeath", "HLRPG_DeathCounter", function(ply)
    HLRPG.AddCounter(ply, "deaths")
end)
