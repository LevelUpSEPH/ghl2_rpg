-- hlrpg/core/sh_stats.lua
-- Stat points: one per level after the first. Each point in a stat grants its perPoint abilities (scaled by
-- the points spent), and reaching a milestone's point count unlocks that milestone's abilities.
-- Spent points are networked as HLRPG_Stat_<id>, so stat abilities apply the same on server and client.
-- Points saved for stats that no longer exist are simply refunded.

HLRPG.StatResetCost = 1000 -- XP to refund all points

-- milestones[points] = { name = "...", abilities = { { id = <ability>, value = ... } } }
HLRPG.Stats = {
    {
        id = "dmg", name = "DMG", color = Color(230, 90, 70),
        perPoint = { { id = "damage_bonus", value = 0.02 } },
        milestones = {
            [5] = { name = "Vampirism", abilities = { { id = "lifesteal", value = 0.1 } } },
            [10] = { name = "Deadeye", abilities = { { id = "crit_chance", value = 0.25 } } },
            [15] = { name = "Grudge", abilities = { { id = "grudge", value = 1 } } },
        },
    },
    {
        id = "tank", name = "TANK", color = Color(80, 150, 235),
        perPoint = {
            { id = "bonus_health", value = 5 },
            { id = "bonus_armor", value = 10 },
        },
        milestones = {
            [5] = { name = "Circulation", abilities = { { id = "health_to_armor", value = 0.25 } } },
            [10] = { name = "Regeneration", abilities = {
                { id = "combat_health_regen", value = 2 },
                { id = "combat_armor_regen", value = 2 },
            } },
            [15] = { name = "Reflector", abilities = { { id = "reflect_armor_damage", value = 1 } } },
        },
    },
}

HLRPG.StatsByID = {}
for _, stat in ipairs(HLRPG.Stats) do HLRPG.StatsByID[stat.id] = stat end

function HLRPG.GetStatPoints(ply, statID)
    return ply:GetNWInt("HLRPG_Stat_" .. statID, 0)
end

function HLRPG.GetTotalStatPoints(ply)
    return math.max(0, ply:GetNWInt("HLRPG_Level", 1) - 1)
end

function HLRPG.GetSpentStatPoints(ply)
    local spent = 0
    for _, stat in ipairs(HLRPG.Stats) do spent = spent + HLRPG.GetStatPoints(ply, stat.id) end
    return spent
end

function HLRPG.GetFreeStatPoints(ply)
    return math.max(0, HLRPG.GetTotalStatPoints(ply) - HLRPG.GetSpentStatPoints(ply))
end

-- The ability instances ply's stats grant, scaled by points, plus every milestone reached
function HLRPG.GetStatAbilities(ply)
    local list = {}

    for _, stat in ipairs(HLRPG.Stats) do
        local points = HLRPG.GetStatPoints(ply, stat.id)
        if points > 0 then
            for _, ability in ipairs(stat.perPoint) do
                list[#list + 1] = { id = ability.id, value = ability.value * points }
            end

            for threshold, milestone in pairs(stat.milestones) do
                if points >= threshold then
                    for _, ability in ipairs(milestone.abilities or {}) do
                        list[#list + 1] = { id = ability.id, value = ability.value }
                    end
                end
            end
        end
    end

    return list
end

-- Milestone point counts for a stat, lowest first
function HLRPG.GetStatMilestoneThresholds(stat)
    local thresholds = table.GetKeys(stat.milestones)
    table.sort(thresholds)
    return thresholds
end
