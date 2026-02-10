-- addons/halflife_rpg/lua/hlrpg/modules/sv_zombie_pilot.lua
if not SERVER then return end

function HLRPG_StartZombiePilot(ply)
    if not IsValid(ply) then return end
    local spawnPos = ply:GetPos()

    local zombie = ents.Create("npc_zombie")
    zombie:SetPos(spawnPos)
    zombie:SetAngles(ply:GetAngles())
    zombie:Spawn()
    zombie:Activate()
    
    zombie.IsPilotEntity = true
    zombie.OwnerPly = ply
    zombie:SetNPCState(NPC_STATE_COMBAT) 
    
    ply.PilotedNPC = zombie
    ply.IsZombieForm = true

    ply:SetActiveWeapon(nil)

    ply:SetNoDraw(true)
    ply:SetNotSolid(true)
    ply:SetMoveType(MOVETYPE_NOCLIP) 
    
    ply:SetNWBool("HLRPG_InZombieForm", true)
    ply:SetNWEntity("HLRPG_PilotedZombie", zombie)

    ply:ChatPrint("[SECOND WIND] You are zombified thanks to your headcrab! Get a kill and press JUMP to revive or DUCK to give up!")

    zombie:EmitSound("npc/zombie/zombie_alert1.wav", 100, 80)
end

hook.Add("Think", "HLRPG_ZombiePilot_Logic", function()
    for _, ply in ipairs(player.GetAll()) do
        if ply.IsZombieForm and IsValid(ply.PilotedNPC) then
            local npc = ply.PilotedNPC
            npc:SetAngles(Angle(0, ply:EyeAngles().y, 0))
            
            local moveVec = Vector(0,0,0)
            if ply:KeyDown(IN_FORWARD) then moveVec = moveVec + ply:GetForward() end
            if ply:KeyDown(IN_BACK) then moveVec = moveVec - ply:GetForward() end
            if ply:KeyDown(IN_MOVELEFT) then moveVec = moveVec - ply:GetRight() end
            if ply:KeyDown(IN_MOVERIGHT) then moveVec = moveVec + ply:GetRight() end

            if moveVec:Length() > 0 then
                npc:SetLastPosition(npc:GetPos() + moveVec * 100)
                npc:SetSchedule(SCHED_FORCED_GO)
            end

            if ply:KeyPressed(IN_ATTACK) then
                local targetPos = npc:GetPos() + npc:GetForward() * 50 + Vector(0, 0, 50)
                npc:SetNPCState(NPC_STATE_COMBAT)
                npc:RestartGesture(ACT_MELEE_ATTACK1) 

                npc:EmitSound("npc/zombie/zo_attack" .. math.random(1, 2) .. ".wav", 75, 100)

                timer.Simple(0.4, function()
                    if IsValid(npc) and IsValid(ply) then
                        local dmgPos = npc:GetPos() + npc:GetForward() * 65 + Vector(0,0,50)
                        local targetEnts = ents.FindInSphere(dmgPos, 80)
                        
                        local hit = false
                        for _, victim in ipairs(targetEnts) do
                            if victim != npc and victim != ply and (victim:IsNPC() or victim:IsPlayer() or victim:GetClass() == "prop_physics") then
                                local d = DamageInfo()
                                d:SetDamage(40)
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
                    end
                end)
            end

            if ply:KeyPressed(IN_JUMP) and ply.CanBurstRevive then
                local pos = npc:GetPos()
                local ang = npc:GetAngles()

                npc.IsPilotEntity = false
                npc.OwnerPly = nil
                ply.IsZombieForm = false
                ply.CanBurstRevive = false
                ply:SetNWBool("HLRPG_InZombieForm", false)

                local gibs = {
                    "models/zombie/classic_torso.mdl",
                    "models/zombie/classic_legs.mdl"
                }

                for _, model in ipairs(gibs) do
                    local gib = ents.Create("prop_ragdoll")
                    gib:SetModel(model)
                    gib:SetPos(pos + Vector(0,0,30))
                    gib:SetAngles(ang)
                    gib:Spawn()
                    gib:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
                    
                    local phys = gib:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:ApplyForceCenter(VectorRand() * 500 + Vector(0,0,300))
                    end
                    
                    SafeRemoveEntityDelayed(gib, 10)
                end

                npc:Remove()
                
                ply:SetNoDraw(false)
                ply:SetNotSolid(false)
                ply:SetMoveType(MOVETYPE_WALK)
                ply:SetPos(pos)
                ply:SetSaveValue("m_takedamage", 2)
                ply:SetHealth(100)

                ply:EmitSound("physics/flesh/flesh_bloody_break.wav", 100, 80)
                local ed = EffectData()
                ed:SetOrigin(pos + Vector(0,0,40))
                util.Effect("AntlionGib", ed)
                
                ply:ViewPunch(Angle(-15, 0, 0))
            end
            if ply:KeyPressed(IN_DUCK) then
                local d = DamageInfo()
                d:SetDamage(1000)
                d:SetDamageType(DMG_BLAST)
                npc:TakeDamageInfo(d)
            end
            ply:SetPos(npc:GetPos() + Vector(0,0,60))
        end
    end
end)

hook.Add("PostEntityTakeDamage", "HLRPG_ZombieDeath_Sync", function(ent, dmg, took)
    if ent.IsPilotEntity and ent:Health() <= 0 then
        local ply = ent.OwnerPly
        if IsValid(ply) then
            ply:SetSaveValue("m_takedamage", 2) 
            ply.IsZombieForm = false 
            ply:SetNWBool("HLRPG_InZombieForm", false)
            ply:Kill() 
            ply:EmitSound("npc/zombie/zombie_die1.wav")
        end
    end
end)

hook.Add("OnNPCKilled", "HLRPG_ZombieRevive_Grant", function(victim, attacker, inflictor)
    if IsValid(attacker) and attacker.IsPilotEntity and IsValid(attacker.OwnerPly) then
        local ply = attacker.OwnerPly
        
        ply.CanBurstRevive = true
        ply:ChatPrint("[SOUL REAPED] Press [SPACE] to burst out!")
    end
end)

hook.Add("StartCommand", "HLRPG_Zombie_BlockInputs", function(ply, cmd)
    if ply:GetNWBool("HLRPG_InZombieForm") then
        cmd:RemoveKey(IN_RELOAD)
        
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            wep:SetNextPrimaryFire(CurTime() + 0.5)
            wep:SetNextSecondaryFire(CurTime() + 0.5)
        end
    end
end)

hook.Add("PlayerBindPress", "HLRPG_Zombie_NoWeaponChange", function(ply, bind, pressed)
    if ply:GetNWBool("HLRPG_InZombieForm") then
        if string.find(bind, "slot") or string.find(bind, "invprev") or string.find(bind, "invnext") or string.find(bind, "lastinv") then
            return true
        end
    end
end)

hook.Add("PlayerSpawn", "HLRPG_ZombiePilot_ResetOnSpawn", function(ply)
    ply.UsedZombieLife = false
    ply.CanBurstRevive = false
    ply.IsZombieForm = false

    ply:SetNWBool("HLRPG_InZombieForm", false)
end)

hook.Add("PrePlayerDraw", "HLRPG_HideZombiePilot", function(ply)
    if ply:GetNWBool("HLRPG_InZombieForm") then
        return true
    end
end)