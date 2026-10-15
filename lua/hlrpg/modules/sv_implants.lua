-- hlrpg/modules/sv_implants.lua
-- Implant actives (core/sh_gear.lua): the client asks to activate (implant key, cl_implants.lua), the server
-- checks the cooldown and starts it. While it runs, its abilities apply through the networked start time
-- (sh_abilities.lua GetImplantAbilities) and the wearer glows in the implant's colour; a weapon active hands out
-- its weapon and takes it back at the end.

util.AddNetworkString("HLRPG_ImplantActivate")

local function ImplantOf(ply)
    local kind = ply:GetNWString("HLRPG_ImplantKind", "")
    if kind == "" then return nil end
    return HLRPG.Gear.GetImplantValues(kind, ply:GetNWInt("HLRPG_ImplantRarity", 1), ply:GetNWFloat("HLRPG_ImplantRoll", 0.5))
end

local function TimerName(ply, what) return "HLRPG_Implant_" .. what .. "_" .. ply:EntIndex() end

-- Ends a running active early or on time: takes back its weapon and recomputes stats (max armor etc.)
function HLRPG.StopImplantActive(ply)
    if not IsValid(ply) then return end
    for _, what in ipairs({ "end", "stats1", "stats2", "stats3" }) do timer.Remove(TimerName(ply, what)) end

    if ply.HLRPG_ImplantWeapon then
        if ply:HasWeapon(ply.HLRPG_ImplantWeapon) then ply:StripWeapon(ply.HLRPG_ImplantWeapon) end
        if ply.HLRPG_ImplantPrevWeapon and ply:HasWeapon(ply.HLRPG_ImplantPrevWeapon) then
            ply:SelectWeapon(ply.HLRPG_ImplantPrevWeapon)
        end
        ply.HLRPG_ImplantWeapon, ply.HLRPG_ImplantPrevWeapon = nil, nil
    end

    if ply:GetNWFloat("HLRPG_ImplantActiveStart", 0) > 0 then
        ply:SetNWFloat("HLRPG_ImplantActiveStart", 0)
        HLRPG.RefreshStats(ply)
    end
end

-- One-off actives (an implant definition's active.action). Each gets the player and the action's scaled numbers;
-- returning false means it couldn't be used right now (nothing to hit), which costs no cooldown.
util.AddNetworkString("HLRPG_VortalChain")
util.AddNetworkString("HLRPG_StrikeMarker")

HLRPG.ImplantActions = {}
local ACTIONS = HLRPG.ImplantActions

local function IsHostile(ent)
    return IsValid(ent) and ent:IsNPC() and ent:Health() > 0 and not HLRPG.FriendlyNPCs[ent:GetClass()]
        and not ent:GetNWBool("HLRPG_ISPET", false)
end

local function CanSee(from, ent, filter)
    local tr = util.TraceLine({ start = from, endpos = ent:WorldSpaceCenter(), filter = filter, mask = MASK_SHOT })
    return tr.Entity == ent or tr.Fraction > 0.98
end

-- The visible enemy nearest the crosshair (within 25 degrees and VORTAL_RANGE)
local VORTAL_RANGE, VORTAL_JUMP = 1500, 500
local VORTAL_CHARGE_SOUND = "npc/vort/attack_charge.wav"

local function VortalFirstTarget(ply)
    local eye, forward = ply:EyePos(), ply:GetAimVector()
    local best, bestDot = nil, math.cos(math.rad(25))
    for _, ent in ipairs(ents.FindInSphere(eye, VORTAL_RANGE)) do
        if IsHostile(ent) then
            local dot = (ent:WorldSpaceCenter() - eye):GetNormalized():Dot(forward)
            if dot > bestDot and CanSee(eye, ent, ply) then best, bestDot = ent, dot end
        end
    end
    return best
end

-- Vortal Blast: a short charge, then lightning that jumps from enemy to enemy, losing 15% per jump
function ACTIONS.vortal_blast(ply, act)
    local first = VortalFirstTarget(ply)
    if not first then return false end
    ply:EmitSound(VORTAL_CHARGE_SOUND, 75, 110)

    timer.Simple(0.6, function()
        if not IsValid(ply) then return end
        ply:StopSound(VORTAL_CHARGE_SOUND) -- it loops (vortigaunts stop it when they fire)
        if not ply:Alive() then return end
        local current = IsHostile(first) and first or VortalFirstTarget(ply)
        if not current then return end

        local points, hit, damage = { ply:GetShootPos() - Vector(0, 0, 8) }, {}, act.damage
        for _ = 1, act.jumps do
            hit[current] = true
            local center = current:WorldSpaceCenter()
            points[#points + 1] = center

            local dmg = DamageInfo()
            dmg:SetDamage(damage)
            dmg:SetDamageType(DMG_SHOCK)
            dmg:SetAttacker(ply)
            dmg:SetInflictor(ply)
            dmg:SetDamagePosition(center)
            current:TakeDamageInfo(dmg)
            local effect = EffectData()
            effect:SetEntity(current)
            effect:SetMagnitude(3)
            util.Effect("TeslaHitBoxes", effect)
            damage = damage * 0.85

            -- Next: the nearest enemy not hit yet that the bolt can reach from here
            local nextTarget, nextDist = nil, VORTAL_JUMP ^ 2
            for _, ent in ipairs(ents.FindInSphere(center, VORTAL_JUMP)) do
                if IsHostile(ent) and not hit[ent] then
                    local dist = ent:WorldSpaceCenter():DistToSqr(center)
                    if dist < nextDist and CanSee(center, ent, current) then nextTarget, nextDist = ent, dist end
                end
            end
            if not nextTarget then break end
            current = nextTarget
        end

        ply:EmitSound("npc/vort/attack_shoot.wav", 80, 100)
        net.Start("HLRPG_VortalChain")
            net.WriteUInt(#points, 4)
            for _, point in ipairs(points) do net.WriteVector(point) end
        net.Broadcast()
    end)
end

-- Canister Strike: mark the aimed-at spot for everyone, then a headcrab canister lands there. The canister is
-- only the show (empty, no damage of its own); the blast is the player's own damage, so it gives XP and kill
-- credit and spares teammates like any player damage.
local STRIKE_DELAY, STRIKE_RANGE = 2, 4000

function ACTIONS.canister_strike(ply, act)
    local eye = ply:EyePos()
    local tr = util.TraceLine({ start = eye, endpos = eye + ply:GetAimVector() * STRIKE_RANGE, filter = ply, mask = MASK_SOLID_BRUSHONLY })
    if not tr.Hit or tr.HitSky then return false end
    local pos = tr.HitPos

    net.Start("HLRPG_StrikeMarker")
        net.WriteVector(pos)
        net.WriteFloat(act.radius)
        net.WriteFloat(STRIKE_DELAY)
    net.Broadcast()

    local canister = ents.Create("env_headcrabcanister")
    if IsValid(canister) then
        canister:SetPos(pos)
        canister:SetAngles(Angle(-60, ply:EyeAngles().y, 0))
        canister:SetKeyValue("HeadcrabType", "0")
        canister:SetKeyValue("HeadcrabCount", "0")
        canister:SetKeyValue("FlightSpeed", "3000")
        canister:SetKeyValue("FlightTime", tostring(STRIKE_DELAY))
        canister:SetKeyValue("StartingHeight", "0")
        canister:SetKeyValue("Damage", "0")
        canister:SetKeyValue("DamageRadius", "0")
        canister:SetKeyValue("SmokeLifetime", "8")
        canister:Spawn()
        canister:Fire("FireCanister", "", 0)
        SafeRemoveEntityDelayed(canister, 30)
    end

    timer.Simple(STRIKE_DELAY, function()
        if not IsValid(ply) then return end
        util.BlastDamage(ply, ply, pos + Vector(0, 0, 16), act.radius, act.damage)
        local effect = EffectData()
        effect:SetOrigin(pos)
        util.Effect("Explosion", effect)
        util.ScreenShake(pos, 12, 5, 1.5, act.radius * 3)
    end)
end

local function Activate(ply)
    if not IsValid(ply) or not ply:Alive() or ply.IsZombieForm then return end
    local implant = ImplantOf(ply)
    local active = implant and implant.active
    if not active then return end
    if CurTime() < ply:GetNWFloat("HLRPG_ImplantReady", 0) then return end
    if ply:GetNWFloat("HLRPG_ImplantActiveStart", 0) > 0 then return end

    if active.action then
        local run = ACTIONS[active.action.id]
        if not run or run(ply, active.action) == false then
            ply:EmitSound("buttons/button10.wav", 60) -- nothing to hit: no cooldown
            return
        end
    end

    ply:SetNWFloat("HLRPG_ImplantActiveStart", CurTime())
    ply:SetNWFloat("HLRPG_ImplantReady", CurTime() + active.cooldown)
    ply:EmitSound("buttons/combine_button1.wav", 70, 120)
    HLRPG.RefreshStats(ply) -- abilities like extra max armor apply now

    -- Stats are recomputed again as each ability's own duration runs out
    local seen = {}
    for _, ability in ipairs(active.abilities) do
        if ability.duration < active.duration and not seen[ability.duration] then
            seen[ability.duration] = true
            timer.Create(TimerName(ply, "stats" .. table.Count(seen)), ability.duration, 1, function()
                if IsValid(ply) then HLRPG.RefreshStats(ply) end
            end)
        end
    end

    if active.weapon then
        local wep = ply:GetActiveWeapon()
        ply.HLRPG_ImplantPrevWeapon = IsValid(wep) and wep:GetClass() or nil
        ply:SetNWFloat("HLRPG_ImplantFireRate", active.weapon.rate or 0)
        ply.HLRPG_ImplantWeapon = active.weapon.class -- before Give: the pickup check below allows only this
        ply:Give(active.weapon.class)
        ply:SelectWeapon(active.weapon.class)
    end

    timer.Create(TimerName(ply, "end"), active.duration, 1, function() HLRPG.StopImplantActive(ply) end)
end

net.Receive("HLRPG_ImplantActivate", function(len, ply) Activate(ply) end)
concommand.Add("hlrpg_implant", function(ply) Activate(ply) end) -- for players who'd rather bind it themselves

-- Dying ends it (the summoned weapon must not be dropped or kept)
hook.Add("PlayerDeath", "HLRPG_ImplantDeath", function(ply) HLRPG.StopImplantActive(ply) end)
hook.Add("PlayerDisconnected", "HLRPG_ImplantLeave", function(ply)
    for _, what in ipairs({ "end", "stats1", "stats2", "stats3" }) do timer.Remove(TimerName(ply, what)) end
end)

-- Implant weapons only go to the player whose implant summoned them
local IMPLANT_WEAPONS = { hlrpg_implant_smg = true, hlrpg_highnoon = true }

hook.Add("PlayerCanPickupWeapon", "HLRPG_ImplantWeaponOnly", function(ply, wep)
    if IsValid(wep) and IMPLANT_WEAPONS[wep:GetClass()] and ply.HLRPG_ImplantWeapon ~= wep:GetClass() then
        return false
    end
end)
