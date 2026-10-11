-- hlrpg/core/sh_abilities.lua
-- Every gameplay effect in the game. Nothing else contains effect logic; abilities are granted by:
--   items (suits, hats, upgrades) in sh_assets.lua:  abilities = { { id = "armor_regen", value = 1 } }
--   stat points and stat milestones in sh_stats.lua
-- An item with a `scope` (weapon class) only grants its abilities while that weapon is out.
--
-- Every callback receives (ply, value, ...). Callbacks a definition doesn't need can be left out.
--   Describe(value)                         -> text for the shop / inventory
--   Stats(ply, value, stats)                -> edit stats.maxHealth / stats.maxArmor (sv_abilities.lua)
--   OnEquip(ply, value) / OnUnequip(ply, value)
--   OnRefill(ply, value)                    -> health was fully restored (spawn, level up, join)
--   Think(ply, value)                       -> once per second while alive
--   OnFireBullets(ply, value, bulletData)   -> edit bulletData in place
--   OnDealDamage(ply, value, target, dmginfo)
--   OnTakeDamage(ply, value, attacker, dmginfo)
--   OnLethalDamage(ply, value, dmginfo)     -> return true to survive the hit
--   AfterTakeDamage(ply, value, attacker, healthLost, armorLost) -> the hit has been applied
--   OnDeath(ply, value, attacker, inflictor)
-- Shared (runs on the server and in the local player's prediction):
--   StartCommand(ply, value, cmd)           -> edit the player's input before it's processed
-- Client only, for the local player:
--   RenderScreen(ply, value) / DrawHalos(ply, value) / HUDPaint(ply, value)

HLRPG.Abilities = {}

local DEF = HLRPG.Abilities

-- Regen abilities wait this long after the player was last hurt
local REGEN_DELAY = 5

local function CanRegen(ply)
    return CurTime() - (ply.HLRPG_LastDamaged or 0) >= REGEN_DELAY
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

local function AddHealth(ply, amount)
    if ply:Health() < ply:GetMaxHealth() then
        ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + amount))
    end
end

local function AddArmor(ply, amount)
    if ply:Armor() < ply:GetMaxArmor() then
        ply:SetArmor(math.min(ply:GetMaxArmor(), ply:Armor() + amount))
    end
end

DEF["health_regen"] = {
    Describe = function(value) return "Regenerates " .. value .. " health/s out of combat" end,
    Think = function(ply, value)
        if CanRegen(ply) then AddHealth(ply, value) end
    end
}

DEF["armor_regen"] = {
    Describe = function(value) return "Regenerates " .. value .. " armor/s out of combat" end,
    Think = function(ply, value)
        if CanRegen(ply) and not HLRPG.HasAbility(ply, "no_armor_regen") then AddArmor(ply, value) end
    end
}

DEF["combat_health_regen"] = {
    Describe = function(value) return "Regenerates " .. value .. " health/s, even in combat" end,
    Think = function(ply, value) AddHealth(ply, value) end
}

DEF["combat_armor_regen"] = {
    Describe = function(value) return "Regenerates " .. value .. " armor/s, even in combat" end,
    Think = function(ply, value)
        if not HLRPG.HasAbility(ply, "no_armor_regen") then AddArmor(ply, value) end
    end
}

-- Overrides max health; hats come after suits, so a hat's value wins over suit health bonuses
DEF["fixed_max_health"] = {
    Describe = function(value) return "Max health is fixed at " .. value end,
    Stats = function(ply, value, stats) stats.maxHealth = value end
}

DEF["armor_refill"] = {
    Describe = function() return "Spawns with full armor" end,
    OnRefill = function(ply) ply:SetArmor(ply:GetMaxArmor()) end
}

-- Marker checked by armor_regen; batteries and chargers still work
DEF["no_armor_regen"] = {
    Describe = function() return "Armor doesn't regenerate over time" end
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

-- Movement

-- Holding jump keeps hopping. Jump is removed from the player's input while airborne, so holding it reads
-- as a fresh press on the landing tick. This has to happen on the usercmd: stripping it from the move data
-- instead leaves jump in the previous tick's buttons, the engine waits on the ground, and friction eats speed.
DEF["auto_bhop"] = {
    Describe = function() return "Hold jump to bunny hop" end,
    StartCommand = function(ply, value, cmd)
        if ply:OnGround() or ply:WaterLevel() >= 2 or ply:GetMoveType() ~= MOVETYPE_WALK then return end
        cmd:RemoveKey(IN_JUMP)
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

DEF["damage_bonus"] = {
    Describe = function(value) return "+" .. math.Round(value * 100) .. "% damage" end,
    OnDealDamage = function(ply, value, target, dmginfo)
        dmginfo:ScaleDamage(1 + value)
    end
}

local CRIT_MULTIPLIER = 1.5

DEF["crit_chance"] = {
    Describe = function(value) return math.Round(value * 100) .. "% chance to crit for x" .. CRIT_MULTIPLIER .. " damage" end,
    OnDealDamage = function(ply, value, target, dmginfo)
        if math.random() < value then dmginfo:ScaleDamage(CRIT_MULTIPLIER) end
    end
}

-- Bonus damage grows with missing health: value 1 means +1% damage per 1% of health missing
DEF["grudge"] = {
    Describe = function(value) return "Up to +" .. math.Round(value * 100) .. "% damage the lower your health is" end,
    OnDealDamage = function(ply, value, target, dmginfo)
        local missing = 1 - math.Clamp(ply:Health() / math.max(ply:GetMaxHealth(), 1), 0, 1)
        dmginfo:ScaleDamage(1 + missing * value)
    end
}

-- Part of the damage that reaches health comes back as armor
DEF["health_to_armor"] = {
    Describe = function(value) return math.Round(value * 100) .. "% of health damage taken becomes armor" end,
    AfterTakeDamage = function(ply, value, attacker, healthLost)
        local gained = math.floor(healthLost * value)
        if gained > 0 then AddArmor(ply, gained) end
    end
}

-- Armor damage taken is dealt back to the NPC that caused it
DEF["reflect_armor_damage"] = {
    Describe = function(value) return "Armor damage taken is reflected back at the attacker" end,
    AfterTakeDamage = function(ply, value, attacker, healthLost, armorLost)
        if armorLost <= 0 or not IsValid(attacker) or not attacker:IsNPC() then return end

        local dmg = DamageInfo()
        dmg:SetDamage(armorLost * value)
        dmg:SetDamageType(DMG_SHOCK)
        dmg:SetAttacker(ply)
        dmg:SetInflictor(ply)
        attacker:TakeDamageInfo(dmg)
    end
}

-- Only enemy attacks can be dodged (not falls, drowning, explosions you caused, etc.)
DEF["dodge_chance"] = {
    Describe = function(value) return math.Round(value * 100, 1) .. "% chance to dodge enemy attacks" end,
    OnTakeDamage = function(ply, value, attacker, dmginfo)
        if not IsValid(attacker) or not attacker:IsNPC() or math.random() >= value then return end

        dmginfo:SetDamage(0)
        ply:EmitSound("weapons/fx/nearmiss/bulletltor0" .. math.random(3, 7) .. ".wav", 60)
    end
}

-- All damage drains armor before health, so the player can't die while armor is above 0
DEF["armor_shield"] = {
    Describe = function() return "Damage hits armor first; you can't die while you have armor" end,
    OnTakeDamage = function(ply, value, attacker, dmginfo)
        local armor, damage = ply:Armor(), dmginfo:GetDamage()
        if armor <= 0 or damage <= 0 then return end

        local absorbed = math.min(armor, damage)
        ply:SetArmor(armor - absorbed)
        dmginfo:SetDamage(damage - absorbed)
    end
}

-- Melee attackers (claws, stunsticks, bites) take shock damage back
local MELEE_DAMAGE = bit.bor(DMG_SLASH, DMG_CLUB)

DEF["shock_attacker"] = {
    Describe = function(value) return "Melee attackers take " .. value .. " shock damage" end,
    OnTakeDamage = function(ply, value, attacker, dmginfo)
        if not IsValid(attacker) or not attacker:IsNPC() then return end
        if bit.band(dmginfo:GetDamageType(), MELEE_DAMAGE) == 0 then return end

        local shock = DamageInfo()
        shock:SetDamage(value)
        shock:SetDamageType(DMG_SHOCK)
        shock:SetAttacker(ply)
        shock:SetInflictor(ply)
        attacker:TakeDamageInfo(shock)

        local effect = EffectData()
        effect:SetEntity(attacker)
        effect:SetMagnitude(2)
        util.Effect("TeslaHitBoxes", effect)
        attacker:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 75, 110)
    end
}

DEF["combine_ball_chance"] = {
    Describe = function(value) return value .. "% chance per shot to also fire a Combine ball" end,
    OnFireBullets = function(ply, value, data)
        if math.random() * 100 >= value then return end

        local dir = ply:GetAimVector()
        local ball = ents.Create("prop_combine_ball")
        if not IsValid(ball) then return end

        ball:SetPos(ply:GetShootPos() + dir * 32)
        ball:SetOwner(ply)
        ball:SetSaveValue("m_flRadius", 10)
        ball:Spawn()
        ball:Activate()
        ball:SetSaveValue("m_nState", 3)
        ball:SetSaveValue("m_flSpeed", 1500)
        ball:SetSaveValue("m_bWeaponLaunched", true)

        local phys = ball:GetPhysicsObject()
        if IsValid(phys) then phys:SetVelocity(dir * 1500) end

        ball:EmitSound("Weapon_AR2.Double")
        ball:Fire("Explode", "", 3)
    end
}

-- Dissolves the NPC that killed the player, credited to the player. Bosses are skipped: dissolving
-- them could break the story scripts that wait for their normal death.
DEF["fizzle_killer"] = {
    Describe = function() return "Whatever kills you is dissolved" end,
    OnDeath = function(ply, value, attacker)
        if not IsValid(attacker) or not attacker:IsNPC() or HLRPG.BossNPCs[attacker:GetClass()] then return end

        local dmg = DamageInfo()
        dmg:SetDamage(attacker:Health() + 1000)
        dmg:SetDamageType(DMG_DISSOLVE)
        dmg:SetAttacker(ply)
        dmg:SetInflictor(ply)
        attacker:TakeDamageInfo(dmg)
    end
}

-- The blast counts as the player's damage: other players, friendly NPCs and pets are protected by
-- sv_combat.lua, and enemies it kills give the player XP as usual
local DEATH_EXPLOSION_RADIUS = 300

DEF["death_explosion"] = {
    Describe = function(value) return "Explodes on death, dealing up to " .. value .. " damage nearby" end,
    OnDeath = function(ply, value)
        local pos = ply:GetPos() + Vector(0, 0, 32)

        local effect = EffectData()
        effect:SetOrigin(pos)
        util.Effect("Explosion", effect)
        util.Effect("HelicopterMegaBomb", effect)

        util.BlastDamage(ply, ply, pos, DEATH_EXPLOSION_RADIUS, value)
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

-- A client setting's value. The server sees it through the player's userinfo; the client reads its own convar.
local function GetSetting(ply, name)
    if CLIENT then
        local cvar = GetConVar(name)
        return cvar and cvar:GetInt() or 1
    end
    return ply:GetInfoNum(name, 1)
end

-- Whether ply has a feature item switched on: owned, and its client setting (cl_player_hub.lua) not 0
function HLRPG.IsFeatureEnabled(ply, itemID)
    local asset = HLRPG.Assets[itemID]
    return ply:GetNWBool("HLRPG_Owned_" .. itemID, false) and GetSetting(ply, asset.setting) ~= 0
end

-- Item IDs ply currently has equipped: suit, hat, every active upgrade and every enabled feature
function HLRPG.GetEquippedItems(ply)
    local items = {}

    for _, key in ipairs({ "HLRPG_ActiveSuit", "HLRPG_ActiveHat" }) do
        local itemID = ply:GetNWString(key, "none")
        if HLRPG.Assets[itemID] then items[#items + 1] = itemID end
    end

    for itemID, asset in pairs(HLRPG.Assets) do
        if asset.type == "modifier" and ply:GetNWBool("HLRPG_ModActive_" .. itemID, false) then
            items[#items + 1] = itemID
        elseif asset.type == "feature" and HLRPG.IsFeatureEnabled(ply, itemID) then
            items[#items + 1] = itemID
        end
    end

    return items
end

-- Every ability instance ply has right now, as { id, value, scope }: stat points and milestones first
-- (so items, e.g. a hat's fixed max health, can override them), then equipped items.
function HLRPG.GetActiveAbilities(ply)
    local list = HLRPG.GetStatAbilities(ply)

    for _, itemID in ipairs(HLRPG.GetEquippedItems(ply)) do
        local item = HLRPG.Assets[itemID]
        for _, ability in ipairs(item.abilities or {}) do
            list[#list + 1] = { id = ability.id, value = ability.value, scope = item.scope }
        end
    end

    return list
end

-- Active abilities that apply right now (weapon-scoped ones only while that weapon is out)
local function GetApplicableAbilities(ply)
    local wep = ply:GetActiveWeapon()
    local weaponClass = IsValid(wep) and wep:GetClass() or nil

    local list = {}
    for _, ability in ipairs(HLRPG.GetActiveAbilities(ply)) do
        if not ability.scope or ability.scope == weaponClass then list[#list + 1] = ability end
    end
    return list
end

-- Runs hookName on every applicable ability of ply. Stops at, and returns, the first non-nil result.
function HLRPG.RunAbilityHook(ply, hookName, ...)
    for _, ability in ipairs(GetApplicableAbilities(ply)) do
        local def = HLRPG.Abilities[ability.id]
        if def and def[hookName] then
            local result = def[hookName](ply, ability.value, ...)
            if result ~= nil then return result end
        end
    end
end

-- Runs hookName for one item's abilities only (OnEquip / OnUnequip)
function HLRPG.RunItemAbilityHook(ply, itemID, hookName)
    for _, ability in ipairs(HLRPG.Assets[itemID] and HLRPG.Assets[itemID].abilities or {}) do
        local def = HLRPG.Abilities[ability.id]
        if def and def[hookName] then def[hookName](ply, ability.value) end
    end
end

function HLRPG.HasAbility(ply, abilityID)
    for _, ability in ipairs(GetApplicableAbilities(ply)) do
        if ability.id == abilityID then return true end
    end
    return false
end

-- Sum of an ability's values across everything that applies right now (0 if none)
function HLRPG.GetAbilityValue(ply, abilityID)
    local total = 0
    for _, ability in ipairs(GetApplicableAbilities(ply)) do
        if ability.id == abilityID then total = total + (ability.value or 0) end
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

-- Input abilities run on both realms so the client's prediction matches the server
hook.Add("StartCommand", "HLRPG_AbilityInput", function(ply, cmd)
    HLRPG.RunAbilityHook(ply, "StartCommand", cmd)
end)
