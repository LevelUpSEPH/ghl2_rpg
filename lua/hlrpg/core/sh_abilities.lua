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
--   QuickThink(ply, value)                  -> ten times per second while alive
--   OnKeyPress(ply, value, key)             -> the player pressed a key (IN_ATTACK2, ...)
--   OnFireBullets(ply, value, bulletData)   -> edit bulletData in place
--   OnDealDamage(ply, value, target, dmginfo)
--   OnTakeDamage(ply, value, attacker, dmginfo)
--   OnLethalDamage(ply, value, dmginfo)     -> return true to survive the hit
--   AfterTakeDamage(ply, value, attacker, healthLost, armorLost) -> the hit has been applied
--   OnDeath(ply, value, attacker, inflictor)
-- Shared (runs on the server and in the local player's prediction):
--   StartCommand(ply, value, cmd)           -> edit the player's input before it's processed
--   Move(ply, value, mv)                    -> edit movement (velocity) before it's processed
-- Client only, for the local player:
--   RenderScreen(ply, value) / DrawHalos(ply, value) / HUDPaint(ply, value)
--   HideHUD = { CHudHealth = true, ... }     -> HUD elements hidden while the ability applies (not a function)

HLRPG.Abilities = {}

-- Button that carries mid-air jump presses (see the StartCommand hook at the bottom)
local AIR_JUMP_KEY = IN_BULLRUSH

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

DEF["blast_resist"] = {
    Describe = function(value) return "Takes " .. math.Round(value * 100) .. "% less explosion damage" end,
    OnTakeDamage = function(ply, value, attacker, dmginfo)
        if dmginfo:IsExplosionDamage() then dmginfo:ScaleDamage(1 - value) end
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

DEF["shotgun_damage"] = {
    Describe = function(value) return "+" .. math.Round(value * 100) .. "% shotgun damage" end,
    OnDealDamage = function(ply, value, target, dmginfo)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_shotgun" then dmginfo:ScaleDamage(1 + value) end
    end
}

DEF["melee_damage"] = {
    Describe = function(value) return "+" .. math.Round(value * 100) .. "% melee damage" end,
    OnDealDamage = function(ply, value, target, dmginfo)
        if bit.band(dmginfo:GetDamageType(), bit.bor(DMG_CLUB, DMG_SLASH)) ~= 0 then dmginfo:ScaleDamage(1 + value) end
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

-- Bullets that hit an NPC sometimes dissolve it outright, like a Combine ball. Bosses are skipped for
-- the same reason as fizzle_killer.
DEF["dissolve_chance"] = {
    Describe = function(value) return value .. "% chance per hit to dissolve the target" end,
    OnDealDamage = function(ply, value, target, dmginfo)
        if not target:IsNPC() or HLRPG.BossNPCs[target:GetClass()] or not dmginfo:IsBulletDamage() then return end
        if math.random() * 100 >= value then return end

        dmginfo:SetDamageType(bit.bor(dmginfo:GetDamageType(), DMG_DISSOLVE))
        dmginfo:SetDamage(math.max(dmginfo:GetDamage(), target:Health() + 100))
    end
}

-- Shots sometimes also launch a Hunter flechette, which sticks and explodes. Marked so it can't count as
-- a Hunter's own flechette (EP2 Payback).
local FLECHETTE_SPEED = 2000

DEF["flechette_chance"] = {
    Describe = function(value) return value .. "% chance per shot to also fire a Hunter flechette" end,
    OnFireBullets = function(ply, value, data)
        if math.random() * 100 >= value then return end

        local dir = ply:GetAimVector()
        local flechette = ents.Create("hunter_flechette")
        if not IsValid(flechette) then return end

        flechette:SetPos(ply:GetShootPos() + dir * 32)
        flechette:SetAngles(dir:Angle())
        flechette:SetOwner(ply)
        flechette.HLRPG_PlayerFired = true
        flechette:Spawn()
        flechette:SetVelocity(dir * FLECHETTE_SPEED)
        flechette:EmitSound("NPC_Hunter.FlechetteShoot")
    end
}

-- Right click with the crowbar throws a spinning crowbar that hits the first thing it touches.
-- The hit is credited to the player (not the prop), so it doesn't count as a physics kill.
local CROWBAR_THROW_SPEED = 1500
local CROWBAR_THROW_COOLDOWN = 1

local function ThrownCrowbarHit(crowbar, data)
    if crowbar.HLRPG_Hit then return end
    local ply, target = crowbar:GetOwner(), data.HitEntity
    crowbar.HLRPG_Hit = true
    SafeRemoveEntityDelayed(crowbar, 3)

    if not IsValid(ply) or not IsValid(target) or target:IsWorld() then
        crowbar:EmitSound("Weapon_Crowbar.Melee_HitWorld")
        return
    end

    -- Damage is dealt after the physics callback; killing things inside it can crash the game
    local damage, hitPos = crowbar.HLRPG_Damage, data.HitPos
    crowbar:EmitSound("Weapon_Crowbar.Melee_Hit")
    timer.Simple(0, function()
        if not IsValid(ply) or not IsValid(target) then return end

        local dmg = DamageInfo()
        dmg:SetDamage(damage)
        dmg:SetDamageType(DMG_CLUB)
        dmg:SetAttacker(ply)
        dmg:SetInflictor(ply)
        dmg:SetDamagePosition(hitPos)
        target:TakeDamageInfo(dmg)
    end)
end

DEF["crowbar_throw"] = {
    Describe = function(value) return "Right click throws a crowbar for " .. value .. " damage" end,
    OnKeyPress = function(ply, value, key)
        if key ~= IN_ATTACK2 or CurTime() < (ply.HLRPG_NextCrowbarThrow or 0) then return end
        ply.HLRPG_NextCrowbarThrow = CurTime() + CROWBAR_THROW_COOLDOWN

        local dir = ply:GetAimVector()
        local crowbar = ents.Create("prop_physics")
        if not IsValid(crowbar) then return end

        crowbar:SetModel("models/weapons/w_crowbar.mdl")
        crowbar:SetPos(ply:GetShootPos() + dir * 24)
        crowbar:SetAngles(dir:Angle())
        crowbar:SetOwner(ply)
        crowbar.HLRPG_Damage = value
        crowbar:Spawn()
        crowbar:AddCallback("PhysicsCollide", ThrownCrowbarHit)
        SafeRemoveEntityDelayed(crowbar, 10)

        local phys = crowbar:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(dir * CROWBAR_THROW_SPEED + ply:GetVelocity())
            phys:AddAngleVelocity(Vector(0, 1500, 0))
        end
        ply:EmitSound("Weapon_Crowbar.Single")
        ply:SetAnimation(PLAYER_ATTACK1)
    end
}

-- Poison headcrab bites leave you at 1 health instead of killing you (the original HL2 behaviour)
local POISON_HEADCRABS = { npc_headcrab_black = true, npc_headcrab_poison = true }

DEF["poison_resistance"] = {
    Describe = function() return "Poison headcrab bites leave you at 1 health instead of killing you" end,
    OnTakeDamage = function(ply, value, attacker, dmginfo)
        local poisoned = dmginfo:IsDamageType(DMG_POISON) or (IsValid(attacker) and POISON_HEADCRABS[attacker:GetClass()])
        if not poisoned then return end
        dmginfo:SetDamage(math.min(dmginfo:GetDamage(), math.max(0, ply:Health() - 1)))
    end
}

-- One extra jump in mid-air; value is the upward speed it gives. Mid-air jump presses arrive as
-- AIR_JUMP_KEY (see the StartCommand hook below), since the jump key itself is removed while airborne.
DEF["double_jump"] = {
    Describe = function() return "Jump again in mid-air" end,
    Move = function(ply, value, mv)
        if ply:OnGround() or ply:GetMoveType() ~= MOVETYPE_WALK or ply:WaterLevel() >= 2 then
            ply.HLRPG_AirJumped = false
            return
        end
        if ply.HLRPG_AirJumped or not mv:KeyPressed(AIR_JUMP_KEY) then return end

        ply.HLRPG_AirJumped = true
        local vel = mv:GetVelocity()
        vel.z = value
        mv:SetVelocity(vel)
        if SERVER then ply:EmitSound("weapons/physcannon/superphys_small_zap" .. math.random(1, 4) .. ".wav", 60, 140) end
    end
}

-- Lambda's suit power (sprint, flashlight, air) has a fixed max of 100, so instead of raising it, part of
-- what was drained since the last second is given back. value 0.5 = drains half as fast = lasts twice as long.
DEF["aux_efficiency"] = {
    Describe = function(value) return "Suit power lasts " .. math.Round(1 / (1 - value), 1) .. "x as long" end,
    Think = function(ply, value)
        if not ply.GetLambdaSuitPower then return end

        local power = ply:GetLambdaSuitPower()
        local last = ply.HLRPG_LastAuxPower or power
        if power < last then
            power = math.min(100, power + (last - power) * value)
            ply:SetLambdaSuitPower(power)
        end
        ply.HLRPG_LastAuxPower = power
    end
}

-- More reserve ammo (the limit itself is applied in sv_abilities.lua, around Lambda's ammo limits) and
-- bigger magazines: when a reload fills the clip to its normal size, it's topped up from the reserve.
DEF["ammo_capacity"] = {
    Describe = function(value) return "+" .. math.Round(value * 100) .. "% max ammo and magazine size" end,
    QuickThink = function(ply, value)
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetMaxClip1() <= 1 then return end

        local clip, maxClip = wep:Clip1(), wep:GetMaxClip1()
        local last = wep.HLRPG_LastClip
        wep.HLRPG_LastClip = clip
        if clip ~= maxClip or not last or last >= clip then return end

        local ammoType = wep:GetPrimaryAmmoType()
        local reserve = ply:GetAmmoCount(ammoType)
        local extra = math.min(math.ceil(maxClip * value), reserve)
        if extra <= 0 then return end

        wep:SetClip1(maxClip + extra)
        ply:SetAmmo(reserve - extra, ammoType)
        wep.HLRPG_LastClip = maxClip + extra
    end
}

-- Kill XP bonus, applied where kill XP is split (sv_progression.lua)
DEF["xp_bonus"] = {
    Describe = function(value) return "+" .. math.Round(value * 100) .. "% XP from kills" end
}

-- Heals every player nearby, the wearer included, once per second
local HEAL_AURA_RADIUS = 250

DEF["heal_aura"] = {
    Describe = function(value) return "Heals you and players near you " .. value .. " health/s" end,
    Think = function(ply, value)
        for _, other in ipairs(player.GetAll()) do
            if other:Alive() and other:GetPos():DistToSqr(ply:GetPos()) <= HEAL_AURA_RADIUS ^ 2 then
                AddHealth(other, value)
            end
        end
    end
}

-- Vision

-- Combine visor: an Overwatch tactical AI. Tints the view slightly and overlays a status readout, a compass,
-- a rangefinder on whatever is under the crosshair, and an analysis of every NPC in line of sight: hostiles get
-- a level-based threat, motion vector and weak point; friendlies and pets are marked as such. Nothing is shown
-- through walls.
local VISOR = Color(130, 215, 255)
local THREAT_COLORS = { Color(130, 215, 255), Color(255, 190, 60), Color(255, 70, 55) }
local THREAT_NAMES = { "LOW", "ELEVATED", "SEVERE" }
local FRIENDLY_COLOR = Color(110, 230, 140)
-- Short tag and full designation per NPC class; others get a name made from their class
local VISOR_UNITS = {
    npc_combine_s = { "OTA", "OVERWATCH SOLDIER" }, npc_metropolice = { "CP", "CIVIL PROTECTION" },
    npc_manhack = { "MANHACK", "VISCERATOR" }, npc_cscanner = { "SCANNER", "CITY SCANNER" },
    npc_clawscanner = { "SCANNER", "CLAW SCANNER" }, npc_rollermine = { "ROLLERMINE", "ROLLERMINE" },
    npc_turret_floor = { "TURRET", "AUTO-TURRET" }, npc_hunter = { "HUNTER", "HUNTER SYNTH" },
    npc_strider = { "STRIDER", "STRIDER SYNTH" }, npc_combinegunship = { "GUNSHIP", "GUNSHIP SYNTH" },
    npc_helicopter = { "HELI", "HUNTER-CHOPPER" }, npc_combinedropship = { "DROPSHIP", "DROPSHIP SYNTH" },
    npc_zombie = { "ZOMBIE", "NECROTIC: STANDARD" }, npc_zombie_torso = { "ZOMBIE", "NECROTIC: TORSO" },
    npc_fastzombie = { "FAST ZOMBIE", "NECROTIC: FAST" }, npc_fastzombie_torso = { "FAST ZOMBIE", "NECROTIC: FAST TORSO" },
    npc_poisonzombie = { "POISON ZOMBIE", "NECROTIC: POISON CARRIER" }, npc_zombine = { "ZOMBINE", "NECROTIC: EX-OVERWATCH" },
    npc_headcrab = { "HEADCRAB", "PARASITE: STANDARD" }, npc_headcrab_fast = { "HEADCRAB", "PARASITE: FAST" },
    npc_headcrab_black = { "HEADCRAB", "PARASITE: VENOMOUS" }, npc_headcrab_poison = { "HEADCRAB", "PARASITE: VENOMOUS" },
    npc_antlion = { "ANTLION", "XENOFAUNA: ANTLION" }, npc_antlion_worker = { "ANTLION", "XENOFAUNA: ACID WORKER" },
    npc_antlionguard = { "GUARD", "XENOFAUNA: ANTLION GUARD" }, npc_barnacle = { "BARNACLE", "XENOFAUNA: BARNACLE" },
    npc_ichthyosaur = { "ICHTHYOSAUR", "XENOFAUNA: ICHTHYOSAUR" }, npc_advisor = { "ADVISOR", "COMBINE ADVISOR" },
    npc_citizen = { "CITIZEN", "CIVILIAN / RESISTANCE" }, npc_alyx = { "VANCE", "ALYX VANCE" },
    npc_barney = { "CALHOUN", "BARNEY CALHOUN" }, npc_kleiner = { "KLEINER", "DR. ISAAC KLEINER" },
    npc_eli = { "VANCE", "DR. ELI VANCE" }, npc_magnusson = { "MAGNUSSON", "DR. ARNE MAGNUSSON" },
    npc_mossman = { "MOSSMAN", "DR. JUDITH MOSSMAN" }, npc_vortigaunt = { "VORTIGAUNT", "XENOFAUNA: VORTIGAUNT" },
    npc_dog = { "DOG", "ROBOT: DOG" }, npc_monk = { "GRIGORI", "FATHER GRIGORI" }, npc_breen = { "BREEN", "DR. WALLACE BREEN" },
    npc_crow = { "CROW", "FAUNA: CROW" }, npc_pigeon = { "PIGEON", "FAUNA: PIGEON" }, npc_seagull = { "SEAGULL", "FAUNA: SEAGULL" },
}

local function UnitNames(ent)
    local known = VISOR_UNITS[ent:GetClass()]
    if known then return known end
    local name = string.upper(string.gsub(string.gsub(ent:GetClass(), "^npc_", ""), "_", " "))
    return { name, name }
end

-- "pet", "friendly" or "hostile"
local function Allegiance(ent)
    if ent:GetNWBool("HLRPG_ISPET", false) then return "pet" end
    if HLRPG.FriendlyNPCs[ent:GetClass()] then return "friendly" end
    return "hostile"
end

local WEAK_BONES = { "ValveBiped.Bip01_Head1", "Combine_Strider.Head_Bone", "MiniStrider.head_bone", "Antlion.Head_Bone", "Antlion_Guard.head" }
local VISOR_RANGE = 3000
local UNITS_TO_M = 0.01905
local visorTargets, nextTargetScan, visorMats = {}, 0, nil

if CLIENT then
    surface.CreateFont("HLRPG_Visor", { font = "Lucida Console", size = 13, weight = 600, antialias = true })
    surface.CreateFont("HLRPG_VisorSmall", { font = "Lucida Console", size = 11, weight = 500, antialias = true })
    surface.CreateFont("HLRPG_VisorBig", { font = "Lucida Console", size = 30, weight = 700, antialias = true })
    surface.CreateFont("HLRPG_VisorHuge", { font = "Consolas", size = 46, weight = 800, antialias = true })
end

-- Visor damage, 0 (fine) .. 1 (suit power empty); set each frame from SuitGlitch
local visorGlitch, jitterX, jitterY = 0, 0, 0
local GLITCH_GLYPHS = { "#", "%", "&", "@", "$", "*", "!", "?", "/", "|", "0", "1" }

local function Corrupt(text)
    if visorGlitch <= 0 then return text end
    return (string.gsub(text, "%S", function(c)
        if math.random() < visorGlitch * 0.06 then return GLITCH_GLYPHS[math.random(#GLITCH_GLYPHS)] end
    end))
end

-- Text with a dark drop shadow so it reads on bright backgrounds; shakes and corrupts while the visor is damaged
local function VText(text, font, x, y, col, alpha, align)
    if visorGlitch > 0 then text, x, y = Corrupt(text), x + jitterX, y + jitterY end
    draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, alpha * 0.8), align or TEXT_ALIGN_LEFT)
    draw.SimpleText(text, font, x, y, ColorAlpha(col, alpha), align or TEXT_ALIGN_LEFT)
end

-- 1 low .. 3 severe, from the unit's level against the player's
local function ThreatLevel(ply, ent)
    local diff = ent:GetNWInt("HLRPG_NPCLevel", 1) - ply:GetNWInt("HLRPG_Level", 1)
    if ent:GetNWBool("HLRPG_IsBoss", false) or diff >= 5 then return 3 end
    return diff >= 0 and 2 or 1
end

-- NPCs in range and in line of sight (bullet trace, so the NPC's own body counts), refreshed 5x/s
local function ScanVisorTargets(ply)
    if CurTime() < nextTargetScan then return visorTargets end
    nextTargetScan = CurTime() + 0.2
    visorTargets = {}

    local eye = ply:EyePos()
    for _, ent in ipairs(ents.FindInSphere(eye, VISOR_RANGE)) do
        if ent:IsNPC() and ent:Health() > 0 then
            local tr = util.TraceLine({ start = eye, endpos = ent:WorldSpaceCenter(), filter = ply, mask = MASK_SHOT })
            if tr.Entity == ent or tr.Fraction > 0.98 then visorTargets[#visorTargets + 1] = ent end
        end
    end
    return visorTargets
end

local function Corners(x, y, w, h, len, col, alpha)
    surface.SetDrawColor(col.r, col.g, col.b, alpha)
    surface.DrawRect(x, y, len, 2); surface.DrawRect(x, y, 2, len)
    surface.DrawRect(x + w - len, y, len, 2); surface.DrawRect(x + w - 2, y, 2, len)
    surface.DrawRect(x, y + h - 2, len, 2); surface.DrawRect(x, y + h - len, 2, len)
    surface.DrawRect(x + w - len, y + h - 2, len, 2); surface.DrawRect(x + w - 2, y + h - len, 2, len)
end

-- Screen-space box around an entity's bounds, or nil if any part is behind the camera
local function ScreenBox(ent)
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
    for i = 0, 7 do
        local corner = Vector(bit.band(i, 1) > 0 and maxs.x or mins.x, bit.band(i, 2) > 0 and maxs.y or mins.y, bit.band(i, 4) > 0 and maxs.z or mins.z)
        local s = ent:LocalToWorld(corner):ToScreen()
        if not s.visible then return nil end
        x0, y0, x1, y1 = math.min(x0, s.x), math.min(y0, s.y), math.max(x1, s.x), math.max(y1, s.y)
    end
    return x0, y0, x1 - x0, y1 - y0
end

-- World position of the unit's head (or equivalent), if it has one
local function WeakPoint(ent)
    for _, name in ipairs(WEAK_BONES) do
        local bone = ent:LookupBone(name)
        if bone then
            local pos = ent:GetBonePosition(bone)
            if pos then return pos end
        end
    end
end

local COMPASS_NAMES = { [0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SW", [270] = "W", [315] = "NW" }

local function DrawCompass(w, yaw, alpha)
    local cx, y, span = w / 2, 46, 360
    local heading = (90 - yaw) % 360
    surface.SetDrawColor(VISOR.r, VISOR.g, VISOR.b, alpha * 0.6)
    surface.DrawRect(cx - span, y + 14, span * 2, 1)
    for deg = 0, 345, 15 do
        local d = (deg - heading + 540) % 360 - 180
        if math.abs(d) <= 60 then
            local x = cx + d / 60 * span
            local major = deg % 45 == 0
            surface.SetDrawColor(VISOR.r, VISOR.g, VISOR.b, alpha * 0.6)
            surface.DrawRect(x, y + (major and 4 or 9), 1, major and 10 or 5)
            if COMPASS_NAMES[deg] then VText(COMPASS_NAMES[deg], "HLRPG_VisorSmall", x, y - 10, VISOR, alpha, TEXT_ALIGN_CENTER) end
        end
    end
    surface.SetDrawColor(VISOR.r, VISOR.g, VISOR.b, alpha)
    surface.DrawRect(cx - 1, y + 16, 2, 8)
    VText(string.format("%03d", math.Round(heading) % 360), "HLRPG_Visor", cx, y + 26, VISOR, alpha, TEXT_ALIGN_CENTER)
end

-- Full readout next to the unit under the crosshair
local function DrawLockPanel(ply, ent, x, y, threat, allegiance)
    local col = threat and THREAT_COLORS[threat] or FRIENDLY_COLOR
    local maxHP = ent:GetMaxHealth()
    local integrity = maxHP > 0 and math.Clamp(ent:Health() / maxHP, 0, 1) or 1
    local lines = {
        "> TARGET LOCK",
        "DESIGNATION  " .. UnitNames(ent)[2],
        "STATUS       " .. (allegiance == "pet" and "ALLY UNIT" or string.upper(allegiance)),
        "LEVEL        " .. (allegiance == "pet" and ent:GetNWInt("HLRPG_PetEntityLevel", 1) or ent:GetNWInt("HLRPG_NPCLevel", 1)),
        "INTEGRITY    " .. math.Round(integrity * 100) .. "%",
        string.format("VELOCITY     %.1f m/s", ent:GetVelocity():Length() * UNITS_TO_M),
    }
    if threat then
        lines[#lines + 1] = "THREAT       " .. THREAT_NAMES[threat]
        lines[#lines + 1] = WeakPoint(ent) and "ADVISE       TARGET CRANIAL UNIT" or "ADVISE       SUSTAIN FIRE"
    else
        lines[#lines + 1] = "ADVISE       DO NOT ENGAGE"
    end
    surface.SetDrawColor(0, 0, 0, 120)
    surface.DrawRect(x - 6, y - 4, 236, #lines * 14 + 8)
    surface.SetDrawColor(col.r, col.g, col.b, 200)
    surface.DrawRect(x - 6, y - 4, 2, #lines * 14 + 8)
    for i, text in ipairs(lines) do
        VText(text, "HLRPG_VisorSmall", x, y + (i - 1) * 14, i == 1 and col or VISOR, 230)
    end
end

local function DrawUnit(ply, ent, eye, locked, t)
    local x, y, bw, bh = ScreenBox(ent)
    if not x or bw <= 2 or bh <= 2 then return end

    local allegiance = Allegiance(ent)
    local threat = allegiance == "hostile" and ThreatLevel(ply, ent) or nil
    local col = threat and THREAT_COLORS[threat] or FRIENDLY_COLOR
    Corners(x - 5, y - 5, bw + 10, bh + 10, math.Clamp(math.min(bw, bh) / 4, 5, 16), col, 220)

    -- Tag, range and integrity bar
    local meters = math.Round(eye:Distance(ent:WorldSpaceCenter()) * UNITS_TO_M)
    local level = allegiance == "pet" and ent:GetNWInt("HLRPG_PetEntityLevel", 1) or ent:GetNWInt("HLRPG_NPCLevel", 1)
    local tag = UnitNames(ent)[1] .. "  " .. (threat and ("LV" .. level) or (allegiance == "pet" and "ALLY" or "FRIENDLY"))
    VText(tag .. "  " .. meters .. "m", "HLRPG_VisorSmall", x - 5, y + bh + 8, col, 230)
    local maxHP = ent:GetMaxHealth()
    local frac = maxHP > 0 and math.Clamp(ent:Health() / maxHP, 0, 1) or 1
    local barW = math.max(bw + 10, 50)
    surface.SetDrawColor(0, 0, 0, 150); surface.DrawRect(x - 5, y + bh + 22, barW, 3)
    surface.SetDrawColor(col.r, col.g, col.b, 220); surface.DrawRect(x - 5, y + bh + 22, barW * frac, 3)

    -- Motion vector: where it will be in half a second
    local vel = ent:GetVelocity()
    if vel:Length() > 20 then
        local a, b = ent:WorldSpaceCenter():ToScreen(), (ent:WorldSpaceCenter() + vel * 0.5):ToScreen()
        if a.visible and b.visible then
            surface.SetDrawColor(col.r, col.g, col.b, 160)
            surface.DrawLine(a.x, a.y, b.x, b.y)
            surface.DrawRect(b.x - 2, b.y - 2, 4, 4)
        end
    end

    -- Weak point: a pulsing diamond on the head (hostiles only)
    local weak = threat and WeakPoint(ent)
    local ws = weak and weak:ToScreen()
    if ws and ws.visible then
        local r = 5 + math.sin(t * 6) * 1.5
        surface.SetDrawColor(255, 80, 60, 230)
        surface.DrawLine(ws.x, ws.y - r, ws.x + r, ws.y); surface.DrawLine(ws.x + r, ws.y, ws.x, ws.y + r)
        surface.DrawLine(ws.x, ws.y + r, ws.x - r, ws.y); surface.DrawLine(ws.x - r, ws.y, ws.x, ws.y - r)
        VText("CRIT", "HLRPG_VisorSmall", ws.x + r + 4, ws.y - 6, Color(255, 80, 60), 210)
    end

    if ent == locked then DrawLockPanel(ply, ent, x + bw + 18, y, threat, allegiance) end
end

-- Overwatch comm feed: random dispatch traffic, typed out in the upper right and pushed out by newer lines
local COMM_TEMPLATES = {
    "DISPATCH > ALL UNITS: ANTI-CITIZEN ONE SIGHTED IN SECTOR {S}",
    "OVERWATCH > HUNT DOWN AND AMPUTATE: POST {N}",
    "DISPATCH > FREEMAN ON THE LOOSE. ALL TEAMS RESPOND",
    "OVERWATCH > REBEL BASE {N} CAPTURED. SANITIZE AND HOLD",
    "OVERWATCH > RESISTANCE CELL {N} CONTAINED",
    "DISPATCH > NON-CITIZEN ACTIVITY REPORTED, SECTOR {S}",
    "OVERWATCH > PROTECTION TEAM {T}: HOLD POSITION AT {S}-{N}",
    "OVERWATCH > STABILIZATION TEAM {T} DEPLOYED TO CANAL {N}",
    "DISPATCH > INOCULATE, CAUTERIZE, STERILIZE: BLOCK {N}",
    "OVERWATCH > AIRWATCH: GUNSHIP {N} EN ROUTE TO SECTOR {S}",
    "DISPATCH > CIVIL PROTECTION: APPLY PRESSURE AT CHECKPOINT {N}",
    "OVERWATCH > SUSPECT {N}{N} PROCESSED. RELOCATION COMPLETE",
    "OVERWATCH > EXOGEN BREACH AT PERIMETER {S}{N}. CONTAIN",
    "DISPATCH > CITIZEN REMINDER: INACTION IS CONSPIRACY",
    "OVERWATCH > SECTOR {S} NOT SECURE. LOCKDOWN IN EFFECT",
    "OVERWATCH > UNIT {T}-{N} BIOSIGNAL LOST. RESPOND",
    "DISPATCH > ANTLION INCURSION, OUTLANDS GRID {N}",
    "OVERWATCH > NOVA PROSPEKT TRANSFER {N}{N} AUTHORIZED",
    "DISPATCH > ATTENTION GROUND UNITS: MISCOUNT DETECTED, BLOCK {N}",
    "OVERWATCH > CODE 7: RESTRICT AND PURGE, SECTOR {S}",
    "DISPATCH > ANTI-CITIZEN COLLABORATION ON RAIL LINE {N}",
    "OVERWATCH > SCANNER {N}{N} DEPLOYED. AERIAL SWEEP {S}",
    "OVERWATCH > VORTIGAUNT ACTIVITY CONFIRMED. EXPUNGE",
    "DISPATCH > ALL UNITS: ISOLATE, ISOLATE, ISOLATE",
}
local COMM_TEAMS = { "ECHO", "VICE", "JURY", "RANGER", "UNION", "GRID", "STAB", "HELIX", "RAZOR", "SAVAGE" }
local COMM_MAX, COMM_TYPE_SPEED = 6, 45
local commLog, nextComm = {}, 0

local function NewCommLine()
    local text = table.Random(COMM_TEMPLATES)
    text = string.gsub(text, "{S}", function() return string.char(math.random(65, 90)) end)
    text = string.gsub(text, "{N}", function() return tostring(math.random(1, 49)) end)
    text = string.gsub(text, "{T}", function() return table.Random(COMM_TEAMS) end)
    return { text = "[" .. os.date("%H:%M:%S") .. "] " .. text, born = CurTime() }
end

local function DrawCommFeed(w, t)
    if t >= nextComm then
        nextComm = t + math.Rand(3.5, 9)
        table.insert(commLog, NewCommLine())
        if #commLog > COMM_MAX then table.remove(commLog, 1) end
    end

    local x, y = w - 52, 44
    for i = #commLog, 1, -1 do
        local line = commLog[i]
        local age = #commLog - i                                          -- 0 for the newest line
        local alpha = 95 * (1 - age / (COMM_MAX + 1)) * math.Clamp(1 - (t - line.born - 40) / 10, 0, 1)
        local shown = math.min(#line.text, math.floor((t - line.born) * COMM_TYPE_SPEED))
        local text = string.sub(line.text, 1, shown)
        if shown < #line.text then text = text .. "_" end
        if alpha > 1 then VText(text, "HLRPG_VisorSmall", x, y + age * 14, VISOR, alpha, TEXT_ALIGN_RIGHT) end
    end
end

-- Damage to the visor follows suit power (armor): none at 40% or more, worst at 0%
local GLITCH_START = 0.4
local VISOR_MIN_FADE = 0.3 -- how visible the visor's elements still are at 0% suit power
local ANALYSIS_OFF = 0.2   -- suit power at which unit analysis (brackets, tags, weak points) is gone

local function SuitGlitch(ply)
    local maxArmor = ply:GetMaxArmor()
    local frac = maxArmor > 0 and ply:Armor() / maxArmor or 0
    return math.Clamp((GLITCH_START - frac) / GLITCH_START, 0, 1)
end

-- A parallelogram leaning right; slant is how far the top edge is shifted
local function Slant(x, y, w, h, slant)
    return { { x = x + slant, y = y }, { x = x + w, y = y }, { x = x + w - slant, y = y + h }, { x = x, y = y + h } }
end

local function SlantBar(x, y, w, h, frac, col, alpha)
    x, y = x + jitterX, y + jitterY
    draw.NoTexture()
    surface.SetDrawColor(0, 4, 10, 170)
    surface.DrawPoly(Slant(x, y, w, h, h))
    if frac > 0 then
        surface.SetDrawColor(col.r, col.g, col.b, alpha)
        surface.DrawPoly(Slant(x, y, math.max(w * frac, h + 1), h, h))
    end
    surface.SetDrawColor(col.r, col.g, col.b, 140)
    for i = 0, 10 do
        surface.DrawRect(x + h + (w - h) * i / 10 - 1, y - (i % 5 == 0 and 7 or 4), 1, i % 5 == 0 and 5 or 2)
    end
end

-- A large readout: label, value, slanted bar. Turns red and pulses below 25%.
local function DrawVital(x, y, label, value, max, t)
    local frac = max > 0 and math.Clamp(value / max, 0, 1) or 0
    local critical = frac < 0.25
    local col = critical and THREAT_COLORS[3] or VISOR
    local alpha = critical and (160 + math.abs(math.sin(t * 5)) * 95) or 245

    surface.SetDrawColor(col.r, col.g, col.b, alpha)
    surface.DrawRect(x - 12 + jitterX, y + 2 + jitterY, 3, 54)
    VText(label, "HLRPG_Visor", x, y, col, 235)
    VText(string.format("%03d", math.max(math.floor(value), 0)), "HLRPG_VisorHuge", x - 2, y + 12, col, alpha)
    VText("/" .. max, "HLRPG_Visor", x + 84, y + 40, col, 170)
    VText(math.Round(frac * 100) .. "%", "HLRPG_Visor", x + 450, y + 26, col, 220, TEXT_ALIGN_RIGHT)
    SlantBar(x + 130, y + 28, 270, 16, frac, col, alpha)
end

local function DrawAux(ply, x, y)
    local power = ply.GetLambdaSuitPower and ply:GetLambdaSuitPower() or 100
    local col = power < 25 and THREAT_COLORS[2] or VISOR
    VText("AUX POWER", "HLRPG_VisorSmall", x, y, col, 220)
    VText(math.Round(power) .. "%", "HLRPG_VisorSmall", x + 450, y, col, 200, TEXT_ALIGN_RIGHT)
    SlantBar(x + 130, y + 2, 270, 7, power / 100, col, 230)
end

-- Ammo for the held weapon, bottom right
local function DrawAmmo(ply, w, h)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or ply:InVehicle() then return end
    local primary, secondary = wep:GetPrimaryAmmoType(), wep:GetSecondaryAmmoType()
    if primary < 0 and secondary < 0 then return end

    local rx, y = w - 52, h - 210
    local name = string.upper(language.GetPhrase(wep:GetPrintName()))
    local clip, maxClip = wep:Clip1(), wep:GetMaxClip1()
    local reserve = primary >= 0 and ply:GetAmmoCount(primary) or 0
    local empty = (clip == 0) or (clip < 0 and reserve == 0)
    local col = empty and THREAT_COLORS[3] or VISOR

    surface.SetDrawColor(col.r, col.g, col.b, 245)
    surface.DrawRect(rx + 9 + jitterX, y + 2 + jitterY, 3, 54)
    VText(name, "HLRPG_Visor", rx, y, col, 235, TEXT_ALIGN_RIGHT)
    if clip >= 0 then
        VText(string.format("%03d", clip), "HLRPG_VisorHuge", rx - 70, y + 12, col, 245, TEXT_ALIGN_RIGHT)
        VText("/" .. reserve, "HLRPG_Visor", rx, y + 40, col, 190, TEXT_ALIGN_RIGHT)
        SlantBar(rx - 290, y + 66, 290, 10, maxClip > 0 and clip / maxClip or 0, col, 235)
    else
        VText(string.format("%03d", reserve), "HLRPG_VisorHuge", rx, y + 12, col, 245, TEXT_ALIGN_RIGHT)
    end
    if secondary >= 0 then
        VText("ALT  x" .. ply:GetAmmoCount(secondary), "HLRPG_Visor", rx, y + 84, VISOR, 210, TEXT_ALIGN_RIGHT)
    end
end

-- Screen damage: static, colour bars and a warning (the tearing happens in RenderScreen)
local function DrawGlitchOverlay(ply, w, h, t)
    local g = visorGlitch
    if g <= 0 then return end
    for _ = 1, math.floor(g * 90) do
        local v = math.random(40, 220)
        surface.SetDrawColor(v, v, v, math.random(15, 70 * g + 15))
        surface.DrawRect(math.random(0, w), math.random(0, h), math.random(2, 7), math.random(1, 3))
    end
    if math.random() < g * 0.3 then
        local c = math.random() < 0.5 and THREAT_COLORS[3] or VISOR
        surface.SetDrawColor(c.r, c.g, c.b, 25 + g * 35)
        surface.DrawRect(0, math.random(0, h), w, math.random(2, 8))
    end
    if g > 0.35 and (t * 2) % 1 < 0.6 then
        local maxArmor = ply:GetMaxArmor()
        local pct = maxArmor > 0 and math.Round(ply:Armor() / maxArmor * 100) or 0
        VText("! SUIT POWER " .. pct .. "% - VISOR INTEGRITY COMPROMISED", "HLRPG_Visor", w / 2, 112, THREAT_COLORS[3], 230, TEXT_ALIGN_CENTER)
    end
end

local tearMat

DEF["combine_vision"] = {
    HideHUD = { CHudHealth = true, CHudBattery = true, CHudAmmo = true, CHudSecondaryAmmo = true },
    Describe = function() return "Overwatch tactical AI: analyses every NPC in sight, rangefinder, compass" end,
    RenderScreen = function(ply)
        -- Steady brightness on purpose: the damage effects never flash the whole screen dark
        local g = SuitGlitch(ply)
        DrawColorModify({
            ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0.01, ["$pp_colour_addb"] = 0.035 + g * 0.03,
            ["$pp_colour_brightness"] = -0.04, ["$pp_colour_contrast"] = 1.06 + g * 0.2,
            ["$pp_colour_colour"] = 0.65 - g * 0.45,
            ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
        })

        -- Tearing: strips of this frame, copied out first, redrawn shifted sideways (never blank)
        if g > 0 and math.random() < 0.1 + g * 0.5 then
            local w, h = ScrW(), ScrH()
            render.UpdateScreenEffectTexture()
            tearMat = tearMat or CreateMaterial("hlrpg_visor_tear", "UnlitGeneric", { ["$basetexture"] = "_rt_FullFrameFB", ["$ignorez"] = 1 })
            tearMat:SetTexture("$basetexture", render.GetScreenEffectTexture())
            cam.Start2D()
            surface.SetMaterial(tearMat)
            surface.SetDrawColor(255, 255, 255, 255)
            for _ = 1, math.random(1, 1 + math.floor(g * 6)) do
                local y0 = math.random(0, h)
                local th = math.random(3, 8 + math.floor(g * 40))
                local dx = (math.random() < 0.5 and -1 or 1) * math.random(4, 8 + math.floor(g * 70))
                surface.DrawTexturedRectUV(dx, y0, w, th, 0, y0 / h, 1, (y0 + th) / h)
            end
            cam.End2D()
        end
    end,
    HUDPaint = function(ply)
        local w, h = ScrW(), ScrH()
        local t = CurTime()
        visorGlitch = SuitGlitch(ply)
        if visorGlitch > 0 and math.random() < visorGlitch * 0.4 then
            jitterX, jitterY = math.random(-3, 3), math.random(-2, 2)
        else
            jitterX, jitterY = 0, 0
        end

        -- The whole visor fades with suit power (down to VISOR_MIN_FADE at 0%); the damage overlay and its
        -- warning are drawn after the reset below, at full strength
        surface.SetAlphaMultiplier(1 - visorGlitch * (1 - VISOR_MIN_FADE))

        -- Mask edges
        visorMats = visorMats or { down = Material("gui/gradient_down"), up = Material("gui/gradient_up"), side = Material("gui/gradient") }
        surface.SetDrawColor(0, 8, 16, 170)
        surface.SetMaterial(visorMats.down); surface.DrawTexturedRect(0, 0, w, h * 0.18)
        surface.SetMaterial(visorMats.up); surface.DrawTexturedRect(0, h * 0.82, w, h * 0.18)
        surface.SetMaterial(visorMats.side); surface.DrawTexturedRect(0, 0, w * 0.14, h)
        surface.DrawTexturedRectUV(w * 0.86, 0, w * 0.14, h, 1, 0, 0, 1)

        -- Scanlines and sweep
        surface.SetDrawColor(0, 0, 0, 22)
        for y = 0, h, 3 do surface.DrawRect(0, y, w, 1) end
        surface.SetDrawColor(VISOR.r, VISOR.g, VISOR.b, 10)
        surface.DrawRect(0, (t % 5) / 5 * h, w, 2)

        Corners(28, 28, w - 56, h - 56, 44, VISOR, 160)
        DrawCompass(w, ply:EyeAngles().y, 200)
        DrawCommFeed(w, t)
        DrawVital(60, h - 236, "BIOSIGNAL", ply:Health(), ply:GetMaxHealth(), t)
        DrawVital(60, h - 164, "SUIT POWER", ply:Armor(), ply:GetMaxArmor(), t)
        DrawAux(ply, 60, h - 92)
        DrawAmmo(ply, w, h)

        local targets = ScanVisorTargets(ply)
        local eye = ply:EyePos()

        local worst, hostiles = 0, 0
        for _, ent in ipairs(targets) do
            if IsValid(ent) and Allegiance(ent) == "hostile" then
                hostiles = hostiles + 1
                worst = math.max(worst, ThreatLevel(ply, ent))
            end
        end

        -- Status readout
        local status = {
            { "OVERWATCH TACTICAL LINK" .. ((t % 1 < 0.5) and " _" or ""), VISOR },
            { "UNIT       " .. string.upper(ply:Nick()), VISOR },
            { "BIOSIGNAL  " .. math.max(ply:Health(), 0) .. "%   SUIT POWER " .. ply:Armor(), VISOR },
            { "SECTOR     " .. string.upper(game.GetMap()), VISOR },
            { "CONTACTS   " .. hostiles .. " HOSTILE  " .. (#targets - hostiles) .. " FRIENDLY", VISOR },
            { "THREAT     " .. (worst > 0 and THREAT_NAMES[worst] or "NONE"), worst > 0 and THREAT_COLORS[worst] or VISOR },
        }
        for i, line in ipairs(status) do
            VText(line[1], "HLRPG_Visor", 48, 44 + (i - 1) * 16, line[2], i == 1 and 240 or 210)
        end

        -- Rangefinder on whatever is under the crosshair
        local tr = ply:GetEyeTrace()
        local cx, cy = w / 2, h / 2
        surface.SetDrawColor(VISOR.r, VISOR.g, VISOR.b, 150)
        surface.DrawRect(cx - 22, cy, 10, 1); surface.DrawRect(cx + 13, cy, 10, 1)
        surface.DrawRect(cx, cy - 22, 1, 10); surface.DrawRect(cx, cy + 13, 1, 10)

        local locked = IsValid(tr.Entity) and tr.Entity:IsNPC() and tr.Entity or nil
        VText(string.format("RNG %.1fm", tr.HitPos:Distance(eye) * UNITS_TO_M), "HLRPG_VisorSmall", cx + 30, cy - 10, VISOR, 220)
        VText(string.format("ELV %+d", math.Round(-ply:EyeAngles().p)), "HLRPG_VisorSmall", cx + 30, cy + 3, VISOR, 170)
        if locked then
            local hostile = Allegiance(locked) == "hostile"
            VText("TGT " .. UnitNames(locked)[1], "HLRPG_VisorSmall", cx + 30, cy + 16, hostile and THREAT_COLORS[ThreatLevel(ply, locked)] or FRIENDLY_COLOR, 210)
        end

        -- Unit analysis needs more suit power than the rest: it fades out between 40% and 20%
        local maxArmor = ply:GetMaxArmor()
        local suitFrac = maxArmor > 0 and ply:Armor() / maxArmor or 0
        local analysis = math.Clamp((suitFrac - ANALYSIS_OFF) / (GLITCH_START - ANALYSIS_OFF), 0, 1)
        if analysis > 0 then
            local base = surface.GetAlphaMultiplier()
            surface.SetAlphaMultiplier(base * analysis)
            for _, ent in ipairs(targets) do
                if IsValid(ent) then DrawUnit(ply, ent, eye, locked, t) end
            end
            surface.SetAlphaMultiplier(base)
        end

        surface.SetAlphaMultiplier(1)
        DrawGlitchOverlay(ply, w, h, t)
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

-- Input abilities run on both realms so the client's prediction matches the server.
-- Lambda's auto jump and auto_bhop strip the jump key while airborne, before the command reaches the
-- server. So the client marks a fresh mid-air jump press with AIR_JUMP_KEY (unused by HL2 movement) first.
hook.Add("StartCommand", "HLRPG_AbilityInput", function(ply, cmd)
    if CLIENT then
        local jumpDown = cmd:KeyDown(IN_JUMP)
        if jumpDown and not ply.HLRPG_JumpDown and not ply:OnGround() then cmd:AddKey(AIR_JUMP_KEY) end
        ply.HLRPG_JumpDown = jumpDown
    end
    HLRPG.RunAbilityHook(ply, "StartCommand", cmd)
end)

hook.Add("SetupMove", "HLRPG_AbilityMove", function(ply, mv)
    HLRPG.RunAbilityHook(ply, "Move", mv)
end)
