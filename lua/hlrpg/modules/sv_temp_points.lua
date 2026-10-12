-- hlrpg/modules/sv_temp_points.lua
-- Temp Points (TP): a per-session shop currency for consumables, reset on join.
-- Earned from kills in sv_progression.lua at HLRPG.TempPointsPerXP.

hook.Add("PlayerInitialSpawn", "HLRPG_InitTempPoints", function(ply)
    ply.HLRPG_TempPoints = 0
    ply.HLRPG_TempPointsFraction = 0
    ply:SetNWInt("HLRPG_TempPoints", 0)
end)

-- Fractions carry over, so many small kills still add up
function HLRPG.AddTempPoints(ply, amount)
    if not IsValid(ply) or amount <= 0 then return end

    local total = (ply.HLRPG_TempPointsFraction or 0) + amount
    local whole = math.floor(total)
    ply.HLRPG_TempPointsFraction = total - whole
    if whole <= 0 then return end

    ply.HLRPG_TempPoints = (ply.HLRPG_TempPoints or 0) + whole
    ply:SetNWInt("HLRPG_TempPoints", ply.HLRPG_TempPoints)

    ply:SendLua([[surface.PlaySound("buttons/lightswitch2.wav")]])
end
