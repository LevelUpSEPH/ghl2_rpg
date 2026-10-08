-- hlrpg/modules/sv_zombie_pilot.lua
-- "Second Wind" from the Headcrab Hat: instead of dying, the player pilots a zombie.
-- A kill lets them burst out (JUMP); DUCK gives up. Client side lives in cl_zombie_pilot.lua.

local ATTACK_DAMAGE = 40
local REVIVE_HEALTH = 100
local GIB_MODELS = {
    "models/zombie/classic_torso.mdl",
    "models/zombie/classic_legs.mdl"
}

local function SetZombieForm(ply, active)
    ply.IsZombieForm = active
    ply:SetNWBool("HLRPG_InZombieForm", active)
end

function HLRPG.StartZombiePilot(ply)
    if not IsValid(ply) then return end

    local zombie = ents.Create("npc_zombie")
    zombie:SetPos(ply:GetPos())
    zombie:SetAngles(ply:GetAngles())
    zombie:Spawn()
    zombie:Activate()

    zombie.IsPilotEntity = true
    zombie.OwnerPly = ply
    zombie:SetNPCState(NPC_STATE_COMBAT)

    ply.PilotedNPC = zombie
    SetZombieForm(ply, true)

    ply:SetActiveWeapon(nil)
    ply:SetNoDraw(true)
    ply:SetNotSolid(true)
    ply:SetMoveType(MOVETYPE_NOCLIP)
    ply:SetNWEntity("HLRPG_PilotedZombie", zombie)

    ply:ChatPrint("[SECOND WIND] You are zombified thanks to your headcrab! Get a kill and press JUMP to revive or DUCK to give up!")

    zombie:EmitSound("npc/zombie/zombie_alert1.wav", 100, 80)
end

local function MoveZombie(ply, npc)
    npc:SetAngles(Angle(0, ply:EyeAngles().y, 0))

    local moveVec = Vector(0, 0, 0)
    if ply:KeyDown(IN_FORWARD) then moveVec = moveVec + ply:GetForward() end
    if ply:KeyDown(IN_BACK) then moveVec = moveVec - ply:GetForward() end
    if ply:KeyDown(IN_MOVELEFT) then moveVec = moveVec - ply:GetRight() end
    if ply:KeyDown(IN_MOVERIGHT) then moveVec = moveVec + ply:GetRight() end

    if moveVec:Length() > 0 then
        npc:SetLastPosition(npc:GetPos() + moveVec * 100)
        npc:SetSchedule(SCHED_FORCED_GO)
    end
end

local function ZombieAttack(ply, npc)
    npc:SetNPCState(NPC_STATE_COMBAT)
    npc:RestartGesture(ACT_MELEE_ATTACK1)
    npc:EmitSound("npc/zombie/zo_attack" .. math.random(1, 2) .. ".wav", 75, 100)

    timer.Simple(0.4, function()
        if not IsValid(npc) or not IsValid(ply) then return end

        local dmgPos = npc:GetPos() + npc:GetForward() * 65 + Vector(0, 0, 50)
        local hit = false

        for _, victim in ipairs(ents.FindInSphere(dmgPos, 80)) do
            if victim ~= npc and victim ~= ply and (victim:IsNPC() or victim:IsPlayer() or victim:GetClass() == "prop_physics") then
                local d = DamageInfo()
                d:SetDamage(ATTACK_DAMAGE)
                d:SetAttacker(npc)
                d:SetInflictor(npc)
                d:SetDamageType(DMG_SLASH)
                victim:TakeDamageInfo(d)
                hit = true
            end
        end

        if hit then
            npc:EmitSound("npc/zombie/claw_strike" .. math.random(1, 3) .. ".wav")
        else
            npc:EmitSound("npc/zombie/claw_miss" .. math.random(1, 2) .. ".wav")
        end
    end)
end

local function BurstRevive(ply, npc)
    local pos = npc:GetPos()
    local ang = npc:GetAngles()

    npc.IsPilotEntity = false
    npc.OwnerPly = nil
    ply.CanBurstRevive = false
    SetZombieForm(ply, false)

    for _, model in ipairs(GIB_MODELS) do
        local gib = ents.Create("prop_ragdoll")
        gib:SetModel(model)
        gib:SetPos(pos + Vector(0, 0, 30))
        gib:SetAngles(ang)
        gib:Spawn()
        gib:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

        local phys = gib:GetPhysicsObject()
        if IsValid(phys) then
            phys:ApplyForceCenter(VectorRand() * 500 + Vector(0, 0, 300))
        end

        SafeRemoveEntityDelayed(gib, 10)
    end

    npc:Remove()

    ply:SetNoDraw(false)
    ply:SetNotSolid(false)
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetPos(pos)
    ply:SetSaveValue("m_takedamage", 2)
    ply:SetHealth(REVIVE_HEALTH)

    ply:EmitSound("physics/flesh/flesh_bloody_break.wav", 100, 80)
    local ed = EffectData()
    ed:SetOrigin(pos + Vector(0, 0, 40))
    util.Effect("AntlionGib", ed)

    ply:ViewPunch(Angle(-15, 0, 0))
end

local function GiveUp(npc)
    local d = DamageInfo()
    d:SetDamage(1000)
    d:SetDamageType(DMG_BLAST)
    npc:TakeDamageInfo(d)
end

hook.Add("Think", "HLRPG_ZombiePilot_Logic", function()
    for _, ply in ipairs(player.GetAll()) do
        local npc = ply.PilotedNPC
        if not ply.IsZombieForm or not IsValid(npc) then continue end

        MoveZombie(ply, npc)

        if ply:KeyPressed(IN_ATTACK) then ZombieAttack(ply, npc) end

        if ply:KeyPressed(IN_JUMP) and ply.CanBurstRevive then
            BurstRevive(ply, npc)
        end

        if ply:KeyPressed(IN_DUCK) then GiveUp(npc) end

        if IsValid(npc) then
            ply:SetPos(npc:GetPos() + Vector(0, 0, 60))
        end
    end
end)

hook.Add("PostEntityTakeDamage", "HLRPG_ZombieDeath_Sync", function(ent, dmg, took)
    if not ent.IsPilotEntity or ent:Health() > 0 then return end

    local ply = ent.OwnerPly
    if not IsValid(ply) then return end

    ply:SetSaveValue("m_takedamage", 2)
    SetZombieForm(ply, false)
    ply:Kill()
    ply:EmitSound("npc/zombie/zombie_die1.wav")
end)

hook.Add("OnNPCKilled", "HLRPG_ZombieRevive_Grant", function(victim, attacker, inflictor)
    if IsValid(attacker) and attacker.IsPilotEntity and IsValid(attacker.OwnerPly) then
        attacker.OwnerPly.CanBurstRevive = true
        attacker.OwnerPly:ChatPrint("[SOUL REAPED] Press [SPACE] to burst out!")
    end
end)

hook.Add("StartCommand", "HLRPG_Zombie_BlockInputs", function(ply, cmd)
    if not ply:GetNWBool("HLRPG_InZombieForm") then return end

    cmd:RemoveKey(IN_RELOAD)

    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        wep:SetNextPrimaryFire(CurTime() + 0.5)
        wep:SetNextSecondaryFire(CurTime() + 0.5)
    end
end)

hook.Add("PlayerSpawn", "HLRPG_ZombiePilot_ResetOnSpawn", function(ply)
    ply.UsedZombieLife = false
    ply.CanBurstRevive = false
    SetZombieForm(ply, false)
end)
