-- hlrpg/modules/sv_progression.lua
-- Player XP and levels. Max health from level is applied through HLRPG.RefreshStats (sv_abilities.lua).

util.AddNetworkString("HLRPG_XPNotify")

function HLRPG.GetLevelMaxHealth(level)
    return 100 + ((level - 1) * 10)
end

local function PerformLevelUp(ply)
    local level = ply:GetLevel()
    local xp = ply:GetXP()

    local newLevel = level
    while xp >= HLRPG.GetRequiredXP(newLevel) do
        newLevel = newLevel + 1
    end

    if newLevel > level then
        ply:SaveLevel(newLevel)
        HLRPG.RefreshStats(ply, true)

        ply:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 100, 120)
        ply:ChatPrint(">>> LEVEL UP: " .. newLevel .. " <<<")
    end

    ply:SetNWInt("HLRPG_MaxXP", HLRPG.GetRequiredXP(ply.HLRPG_Level))
end

function HLRPG.AddXP(ply, amount)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not amount or amount <= 0 then return end

    ply:ChangeXP(amount)
    PerformLevelUp(ply)
end

-- Returns the level-scaled XP reward and the unscaled base XP (used for Temp Points)
local function GetKillXP(npc)
    local baseXP = HLRPG.NPCXP[npc:GetClass()] or HLRPG.DefaultXP
    if not HLRPG.IsLeveledNPC(npc) then return baseXP, baseXP end

    return baseXP * HLRPG.GetNPCLevelMultiplier("XP", HLRPG.GetNPCLevel(npc)), baseXP
end

-- XP and TP are split between every player who damaged the NPC, by share of damage dealt (tracked in sv_combat.lua)
hook.Add("OnNPCKilled", "HLRPG_XP_System", function(npc, attacker, inflictor)
    if not npc.HLRPG_DamageTable then return end

    local totalXPAward, baseXP = GetKillXP(npc)
    local totalDamage = 0
    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) then totalDamage = totalDamage + dmg end
    end
    if totalDamage <= 0 then return end

    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) and ply:IsPlayer() then
            local ratio = dmg / totalDamage
            local xpGain = math.Round(totalXPAward * ratio)

            HLRPG.AddTempPoints(ply, baseXP * ratio * HLRPG.TempPointsPerXP)

            if xpGain > 0 then
                HLRPG.AddXP(ply, xpGain)

                net.Start("HLRPG_XPNotify")
                    net.WriteInt(xpGain, 32)
                    net.WriteInt(math.Round(ratio * 100), 16)
                    net.WriteString(HLRPG.GetNPCName(npc))
                    net.WriteColor(Color(255, 255, 255))
                net.Send(ply)
            end
        end
    end
end)
