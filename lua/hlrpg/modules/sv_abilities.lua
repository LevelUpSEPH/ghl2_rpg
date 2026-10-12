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

local function ThinkAll(hookName)
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not ply.IsZombieForm then
            HLRPG.RunAbilityHook(ply, hookName)
        end
    end
end

timer.Create("HLRPG_AbilityThink", 1, 0, function() ThinkAll("Think") end)
timer.Create("HLRPG_AbilityQuickThink", 0.1, 0, function() ThinkAll("QuickThink") end)

hook.Add("KeyPress", "HLRPG_AbilityKeyPress", function(ply, key)
    if ply:Alive() and not ply.IsZombieForm then
        HLRPG.RunAbilityHook(ply, "OnKeyPress", key)
    end
end)

-- ammo_capacity: Lambda limits ammo to the skill convars (GM.MAX_AMMO_DEF) when ammo changes and before
-- ammo pickups. Both are wrapped so players with the ability get the bigger limit instead.
local function GetAmmoCap(gm, ply, ammoType)
    local bonus = HLRPG.GetAbilityValue(ply, "ammo_capacity")
    local cvar = gm.MAX_AMMO_DEF and gm.MAX_AMMO_DEF[game.GetAmmoName(ammoType) or ""]
    if bonus <= 0 or not cvar then return nil end
    return math.floor(cvar:GetInt() * (1 + bonus))
end

hook.Add("Initialize", "HLRPG_AmmoCapacity", function()
    local limitAmmo = GAMEMODE.LimitPlayerAmmo
    if limitAmmo then
        function GAMEMODE:LimitPlayerAmmo(ply, ammoType, newCount)
            local cap = GetAmmoCap(self, ply, ammoType)
            if not cap then return limitAmmo(self, ply, ammoType, newCount) end
            if self:GetSetting("limit_default_ammo") == false then return end
            if newCount > cap then ply:SetAmmo(cap, ammoType) end
        end
    end

    local canPickupAmmo = GAMEMODE.PlayerCanPickupAmmo
    if canPickupAmmo then
        function GAMEMODE:PlayerCanPickupAmmo(ply, ent)
            local itemDef = self.ITEM_DEF and self.ITEM_DEF[ent:GetClass()]
            local ammoType = itemDef and game.GetAmmoID(itemDef.Type) or -1
            local cap = ammoType ~= -1 and GetAmmoCap(self, ply, ammoType)
            if not cap then return canPickupAmmo(self, ply, ent) end
            return ply:GetAmmoCount(ammoType) < cap
        end
    end
end)
