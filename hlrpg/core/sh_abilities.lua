-- hlrpg/core/sh_abilities.lua
-- Every gameplay effect an item can have. Items (suits, hats, upgrades) don't contain logic; they list
-- the abilities they grant in sh_assets.lua:
--   abilities = { { id = "armor_regen", value = 1 } }
-- An item with a `scope` (weapon class) only grants its abilities while that weapon is out.
--
-- Every callback receives (ply, value, ...). Callbacks a definition doesn't need can be left out.
--   Describe(value)                         -> text for the shop / inventory
--   Stats(ply, value, stats)                -> edit stats.maxHealth / stats.maxArmor (sv_abilities.lua)
--   OnEquip(ply, value) / OnUnequip(ply, value)
--   Think(ply, value)                       -> once per second while alive
--   OnFireBullets(ply, value, bulletData)   -> edit bulletData in place
--   OnDealDamage(ply, value, target, dmginfo)
--   OnTakeDamage(ply, value, attacker, dmginfo)
--   OnLethalDamage(ply, value, dmginfo)     -> return true to survive the hit
-- Client only, for the local player:
--   RenderScreen(ply, value) / DrawHalos(ply, value) / HUDPaint(ply, value)

HLRPG.Abilities = {}

local DEF = HLRPG.Abilities

-- Regen abilities wait this long after the player was last hurt
local REGEN_DELAY = 5

local function CanRegen(ply)
    return CurTime() - (ply.HLRPG_LastDamaged or 0) >= REGEN_DELAY
end

local UNDEAD = {
    ["npc_zombie"] = true, ["npc_zombie_torso"] = true,
    ["npc_fastzombie"] = true, ["npc_fastzombie_torso"] = true,
    ["npc_poisonzombie"] = true, ["npc_zombine"] = true,
    ["npc_headcrab"] = true, ["npc_headcrab_fast"] = true, ["npc_headcrab_black"] = true,
}

-- Wild undead only: headcrab pets and the piloted zombie are also these classes
local function IsWildUndead(ent)
    return ent:IsNPC() and UNDEAD[ent:GetClass()] and not ent.IsHLRPGPet and not ent.IsPilotEntity
end

-- Stats

DEF["bonus_health"] = {
    Describe = function(value) return "+" .. value .. " max health" end,
    Stats = function(ply, value, stats) stats.maxHealth = stats.maxHealth + value end
}

DEF["bonus_armor"] = {
    Describe = function(value) return "+" .. value .. " max armor" end,
    Stats = function(ply, value, stats) stats.maxArmor = stats.maxArmor + value end
}

DEF["health_regen"] = {
    Describe = function(value) return "Regenerates " .. value .. " health/s out of combat" end,
    Think = function(ply, value)
        if CanRegen(ply) and ply:Health() < ply:GetMaxHealth() then
            ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + value))
        end
    end
}

DEF["armor_regen"] = {
    Describe = function(value) return "Regenerates " .. value .. " armor/s out of combat" end,
    Think = function(ply, value)
        if CanRegen(ply) and ply:Armor() < ply:GetMaxArmor() then
            ply:SetArmor(math.min(ply:GetMaxArmor(), ply:Armor() + value))
        end
    end
}

-- Combat

DEF["damage_resist"] = {
    Describe = function(value) return "Takes " .. math.Round(value * 100) .. "% less damage" end,
    OnTakeDamage = function(ply, value, attacker, dmginfo)
        dmginfo:ScaleDamage(1 - value)
    end
}

DEF["poison_immunity"] = {
    Describe = function() return "Immune to poison" end,
    OnTakeDamage = function(ply, value, attacker, dmginfo)
        if dmginfo:IsDamageType(DMG_POISON) or dmginfo:IsDamageType(DMG_NERVEGAS) then
            dmginfo:SetDamage(0)
        end
    end
}

DEF["lifesteal"] = {
    Describe = function(value) return "Heals " .. math.Round(value * 100) .. "% of damage dealt" end,
    OnDealDamage = function(ply, value, target, dmginfo)
        if not target:IsNPC() then return end
        local heal = math.floor(dmginfo:GetDamage() * value)
        if heal > 0 then
            ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + heal))
        end
    end
}

-- Zombies leave the player alone until the player hurts one of them
DEF["undead_disguise"] = {
    Describe = function() return "Zombies and headcrabs ignore you until you attack them" end,
    Think = function(ply)
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 2000)) do
            if IsWildUndead(ent) and not (ent.HLRPG_ProvokedBy and ent.HLRPG_ProvokedBy[ply]) then
                ent:AddEntityRelationship(ply, D_NU, 99)
                if ent:GetEnemy() == ply then
                    ent:SetEnemy(NULL)
                    ent:ClearEnemyMemory(ply)
                end
            end
        end
    end,
    OnDealDamage = function(ply, value, target)
        if not IsWildUndead(target) then return end
        target.HLRPG_ProvokedBy = target.HLRPG_ProvokedBy or {}
        target.HLRPG_ProvokedBy[ply] = true
        target:AddEntityRelationship(ply, D_HT, 99)
    end,
    OnUnequip = function(ply)
        for _, ent in ipairs(ents.GetAll()) do
            if IsWildUndead(ent) then
                ent:AddEntityRelationship(ply, D_HT, 99)
            end
        end
    end
}

DEF["incendiary_rounds"] = {
    Describe = function(value) return value .. "% chance to set targets on fire" end,
    OnFireBullets = function(ply, value, data)
        data.TracerName = "AR2Tracer"
    end,
    OnDealDamage = function(ply, value, target, dmginfo)
        if (target:IsNPC() or target:IsPlayer()) and math.random(1, 100) <= value then
            target:Ignite(3)
            target:EmitSound("ambient/fire/ignite.wav")
        end
    end
}

DEF["pellet_multiplier"] = {
    Describe = function(value) return "x" .. value .. " pellets, wider spread" end,
    OnFireBullets = function(ply, value, data)
        data.Num = math.floor(data.Num * value)
        data.Spread = data.Spread * 1.2
    end
}

-- Once per life: a lethal hit turns the player into a pilotable zombie instead (sv_zombie_pilot.lua)
DEF["second_wind"] = {
    Describe = function() return "Once per life, survive a lethal hit as a zombie" end,
    OnLethalDamage = function(ply, value, dmginfo)
        if ply.UsedZombieLife then return end

        dmginfo:SetDamage(0)
        ply:SetHealth(1)
        ply.UsedZombieLife = true

        if pcall(HLRPG.StartZombiePilot, ply) then
            ply:SetSaveValue("m_takedamage", 0)
        else
            ply:Kill()
        end
        return true
    end
}

-- Vision

DEF["combine_vision"] = {
    Describe = function() return "Combine tactical vision: highlights Combine forces" end,
    RenderScreen = function()
        DrawColorModify({
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0.02,
            ["$pp_colour_addb"] = 0.1,
            ["$pp_colour_brightness"] = -0.05,
            ["$pp_colour_contrast"] = 1.2,
            ["$pp_colour_colour"] = 0.4,
        })
    end,
    HUDPaint = function()
        surface.SetDrawColor(0, 0, 0, 80)
        local w, h = ScrW(), ScrH()
        for i = 0, h, 3 do
            surface.DrawRect(0, i, w, 1)
        end

        draw.SimpleText("• SYSTEM ONLINE", "DermaDefault", 20, 20, Color(0, 200, 255, 150))
    end,
    DrawHalos = function()
        local targets = ents.FindByClass("npc_combine_s")
        table.Add(targets, ents.FindByClass("npc_metropolice"))
        halo.Add(targets, Color(0, 150, 255), 2, 2, 1, true, true)
    end
}

-- Dispatch (shared; equipment state comes from networked vars, so the client sees the same abilities)

-- Item IDs ply currently has equipped: suit, hat and every active upgrade
function HLRPG.GetEquippedItems(ply)
    local items = {}

    for _, key in ipairs({ "HLRPG_ActiveSuit", "HLRPG_ActiveHat" }) do
        local itemID = ply:GetNWString(key, "none")
        if HLRPG.Assets[itemID] then items[#items + 1] = itemID end
    end

    for itemID, asset in pairs(HLRPG.Assets) do
        if asset.type == "modifier" and ply:GetNWBool("HLRPG_ModActive_" .. itemID, false) then
            items[#items + 1] = itemID
        end
    end

    return items
end

-- Calls callback(def, value) for each ability on one item
local function ForEachItemAbility(itemID, callback)
    local item = HLRPG.Assets[itemID]
    if not item or not item.abilities then return end

    for _, ability in ipairs(item.abilities) do
        local def = HLRPG.Abilities[ability.id]
        if def then
            local result = callback(def, ability.value)
            if result ~= nil then return result end
        end
    end
end

-- Runs hookName on every active ability of ply. Stops at, and returns, the first non-nil result.
function HLRPG.RunAbilityHook(ply, hookName, ...)
    local args, argCount = { ... }, select("#", ...)

    local wep = ply:GetActiveWeapon()
    local weaponClass = IsValid(wep) and wep:GetClass() or nil

    for _, itemID in ipairs(HLRPG.GetEquippedItems(ply)) do
        local scope = HLRPG.Assets[itemID].scope
        if not scope or scope == weaponClass then
            local result = ForEachItemAbility(itemID, function(def, value)
                if def[hookName] then
                    return def[hookName](ply, value, unpack(args, 1, argCount))
                end
            end)
            if result ~= nil then return result end
        end
    end
end

-- Runs hookName for one item's abilities only (OnEquip / OnUnequip)
function HLRPG.RunItemAbilityHook(ply, itemID, hookName)
    ForEachItemAbility(itemID, function(def, value)
        if def[hookName] then def[hookName](ply, value) end
    end)
end

-- Sum of an ability's values across everything ply has active (0 if none)
function HLRPG.GetAbilityValue(ply, abilityID)
    local total = 0
    for _, itemID in ipairs(HLRPG.GetEquippedItems(ply)) do
        for _, ability in ipairs(HLRPG.Assets[itemID].abilities or {}) do
            if ability.id == abilityID then total = total + (ability.value or 0) end
        end
    end
    return total
end

-- One line per ability, for the shop and inventory
function HLRPG.DescribeAbilities(item)
    local lines = {}
    for _, ability in ipairs(item.abilities or {}) do
        local def = HLRPG.Abilities[ability.id]
        if def and def.Describe then lines[#lines + 1] = def.Describe(ability.value) end
    end
    return table.concat(lines, "  •  ")
end
