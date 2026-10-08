-- hlrpg/modules/sv_difficulty.lua
-- World difficulty picks the level range NPCs spawn at; their level then drives health, damage
-- (sv_combat.lua) and XP reward (sv_progression.lua) through HLRPG.NPCLevelScaling.

-- Pets and the Headcrab Hat's piloted zombie belong to players and use their own stats
function HLRPG.IsLeveledNPC(ent)
    return IsValid(ent) and ent:IsNPC() and not ent.IsHLRPGPet and not ent.IsPilotEntity
end

function HLRPG.GetNPCLevel(npc)
    return npc:GetNWInt("HLRPG_NPCLevel", 1)
end

local function RollNPCLevel(npc)
    local diffData = HLRPG.GetDifficulty()
    npc:SetNWInt("HLRPG_NPCLevel", math.random(diffData.minLvl, diffData.maxLvl))
end

-- Sets max health from the NPC's original max health, so it can be re-run when the level changes
local function ApplyNPCHealth(npc)
    npc.HLRPG_BaseHealth = npc.HLRPG_BaseHealth or npc:GetMaxHealth()
    if npc.HLRPG_BaseHealth <= 0 then return end

    local hp = npc.HLRPG_BaseHealth * HLRPG.GetNPCLevelMultiplier("HP", HLRPG.GetNPCLevel(npc))
    if npc:GetNWBool("HLRPG_IsBoss") then hp = hp * HLRPG.BossHealthMultiplier end

    hp = math.max(1, math.floor(hp))
    npc:SetMaxHealth(hp)
    npc:SetHealth(hp)
end

local function SetupBoss(npc)
    if not HLRPG.BossNPCs[npc:GetClass()] then return end

    npc:SetNWBool("HLRPG_IsBoss", true)

    npc:CallOnRemove("BossDeathCharge", function(ent)
        local attacker = ent:GetInternalVariable("m_hLastAttacker")
        if IsValid(attacker) and attacker:IsPlayer() then
            attacker:AddUltCharge(HLRPG.BossKillUltCharge)
        end
    end)
end

hook.Add("OnEntityCreated", "HLRPG_SetupNPC", function(ent)
    if not ent:IsNPC() then return end

    -- Delayed so the NPC has spawned and pets/pilot zombies have been flagged
    timer.Simple(0.1, function()
        if not HLRPG.IsLeveledNPC(ent) then return end

        SetupBoss(ent)
        RollNPCLevel(ent)
        ApplyNPCHealth(ent)
    end)
end)

-- Re-levels every undamaged NPC to the new range
function HLRPG.SetDifficulty(level)
    level = math.Clamp(tonumber(level) or 1, 1, #HLRPG.DifficultyScales)
    SetGlobalInt("HLRPG_CurrentDifficulty", level)

    for _, ent in ipairs(ents.GetAll()) do
        if HLRPG.IsLeveledNPC(ent) and ent:Health() == ent:GetMaxHealth() then
            RollNPCLevel(ent)
            ApplyNPCHealth(ent)
        end
    end

    local diffName = HLRPG.DifficultyScales[level].name:upper()
    for _, ply in ipairs(player.GetAll()) do
        ply:PrintMessage(HUD_PRINTCENTER, "WORLD DIFFICULTY: " .. diffName)
    end
end

local function RequestSetDifficulty(ply, level)
    if not ply:IsAdmin() then
        ply:ChatPrint("You don't have permission to do that.")
        return
    end
    HLRPG.SetDifficulty(level)
end

HLRPG.AddChatCommand("!setdiff", function(ply, args)
    RequestSetDifficulty(ply, args[1])
end)

-- Sent by the difficulty page in the TAB menu
util.AddNetworkString("HLRPG_SetDifficulty")
net.Receive("HLRPG_SetDifficulty", function(len, ply)
    RequestSetDifficulty(ply, net.ReadUInt(8))
end)
