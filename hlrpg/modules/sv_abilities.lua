-- hlrpg/modules/sv_abilities.lua
-- Runs the ability library (core/sh_abilities.lua) for equipped items: stats, equip events and think.
-- Combat callbacks are dispatched from sv_combat.lua.

local BASE_MAX_ARMOR = 100

-- Recomputes max health/armor from level + abilities. refill sets health to the new max (spawn, level up);
-- otherwise current health and armor are only clamped. (Jump power is applied per tick in sh_abilities.lua.)
function HLRPG.RefreshStats(ply, refill)
    if not IsValid(ply) or not ply.HLRPG_Level then return end

    local stats = {
        maxHealth = HLRPG.GetLevelMaxHealth(ply.HLRPG_Level),
        maxArmor = BASE_MAX_ARMOR,
    }
    HLRPG.RunAbilityHook(ply, "Stats", stats)

    ply:SetMaxHealth(stats.maxHealth)
    ply:SetMaxArmor(stats.maxArmor)

    ply:SetHealth(refill and stats.maxHealth or math.min(ply:Health(), stats.maxHealth))
    ply:SetArmor(math.min(ply:Armor(), stats.maxArmor))

    if refill then HLRPG.RunAbilityHook(ply, "OnRefill") end
end

-- Equipment controllers call this after an item slot changes (either ID may be "none")
function HLRPG.OnEquipmentChanged(ply, oldItemID, newItemID)
    if oldItemID and oldItemID ~= newItemID then
        HLRPG.RunItemAbilityHook(ply, oldItemID, "OnUnequip")
    end
    if newItemID and oldItemID ~= newItemID then
        HLRPG.RunItemAbilityHook(ply, newItemID, "OnEquip")
    end

    HLRPG.RefreshStats(ply)
end

hook.Add("PlayerSpawn", "HLRPG_ApplyStats", function(ply)
    -- Delayed so it runs after the gamemode's own spawn setup
    timer.Simple(0.1, function()
        HLRPG.RefreshStats(ply, true)
    end)
end)

hook.Add("PlayerDeath", "HLRPG_AbilityDeath", function(ply, inflictor, attacker)
    HLRPG.RunAbilityHook(ply, "OnDeath", attacker, inflictor)
end)

timer.Create("HLRPG_AbilityThink", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not ply.IsZombieForm then
            HLRPG.RunAbilityHook(ply, "Think")
        end
    end
end)
