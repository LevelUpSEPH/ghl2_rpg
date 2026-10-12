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
