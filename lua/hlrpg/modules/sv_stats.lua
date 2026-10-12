-- hlrpg/modules/sv_stats.lua
-- Spending and resetting stat points (definitions in core/sh_stats.lua, page in ui/cl_stats_menu.lua).

util.AddNetworkString("HLRPG_StatSpend")
util.AddNetworkString("HLRPG_StatReset")

local REQUEST_COOLDOWN = 0.1

local function IsThrottled(ply)
    if (ply.HLRPG_NextStatRequest or 0) > CurTime() then return true end
    ply.HLRPG_NextStatRequest = CurTime() + REQUEST_COOLDOWN
    return false
end

local function ApplyStatChange(ply)
    ply:SaveStats()
    HLRPG.RefreshStats(ply)
end

net.Receive("HLRPG_StatSpend", function(len, ply)
    local statID = net.ReadString()
    if IsThrottled(ply) or not HLRPG.StatsByID[statID] then return end

    if HLRPG.GetFreeStatPoints(ply) <= 0 then
        ply:ChatPrint("[STATS] You don't have any stat points to spend.")
        return
    end

    local points = HLRPG.GetStatPoints(ply, statID) + 1
    ply:SetNWInt("HLRPG_Stat_" .. statID, points)
    ApplyStatChange(ply)

    local stat = HLRPG.StatsByID[statID]
    local milestone = stat.milestones[points]
    if milestone then
        ply:ChatPrint("[STATS] " .. stat.name .. " milestone reached: " .. milestone.name)
        ply:EmitSound("items/suitchargeok1.wav")
    end
end)

net.Receive("HLRPG_StatReset", function(len, ply)
    if IsThrottled(ply) or HLRPG.GetSpentStatPoints(ply) == 0 then return end

    if ply:GetXP() < HLRPG.StatResetCost then
        ply:ChatPrint("[STATS] Resetting your stats costs " .. HLRPG.StatResetCost .. " XP.")
        return
    end

    ply:ChangeXP(-HLRPG.StatResetCost)
    for _, stat in ipairs(HLRPG.Stats) do
        ply:SetNWInt("HLRPG_Stat_" .. stat.id, 0)
    end
    ApplyStatChange(ply)

    ply:ChatPrint("[STATS] All stat points refunded (-" .. HLRPG.StatResetCost .. " XP).")
end)
