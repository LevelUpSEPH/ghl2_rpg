-- addons/halflife_rpg/lua/hlrpg/core/sh_skills.lua

HLRPG = HLRPG or {}
HLRPG.Skills = {}

local SKILLS = {}

SKILLS["tech_warp_cannon"] = {
    Name = "Warp Cannon",
    Desc = "Düşman öldürerek şarj edilir. Animasyon garantili sürüm.",
    Cooldown = 1,
    
    OnCast = function(ply)
        -- 1. KOŞUL
        local charge = ply:GetUltCharge()
        if charge < 0 then
            ply:ChatPrint("HATA: Çekirdek henüz stabilize olmadı!")
            return false
        end
        
        ply:SetNWBool("HLRPG_IsCastingUlt", true)
        ply:SetUltCharge(0)
        
        ply:DoAnimationEvent(ACT_GMOD_GESTURE_TAUNT_ZOMBIE)
        
        local magicID = ply:LookupSequence("reload_magic")
        if magicID and magicID != -1 then
            ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_VCD, magicID, 0, true)
        end
        
        ply:EmitSound("npc/strider/charging.wav", 100, 100)
        util.ScreenShake(ply:GetPos(), 4, 10, 1.5, 500)
        
        local timerID = "WarpCannon_FX_" .. ply:EntIndex()
        timer.Create(timerID, 0.1, 15, function()
            if not IsValid(ply) or not ply:Alive() then timer.Remove(timerID) return end
            
            local effectdata = EffectData()
            effectdata:SetEntity(ply)
            effectdata:SetMagnitude(3)
            util.Effect("TeslaHitBoxes", effectdata)
            
            local tr = util.TraceLine({
                start = ply:GetShootPos(),
                endpos = ply:GetShootPos() + ply:GetAimVector() * 10000,
                filter = ply
            })
            
            local laserEffect = EffectData()
            laserEffect:SetStart(ply:GetShootPos())
            laserEffect:SetOrigin(tr.HitPos)
            laserEffect:SetEntity(ply)
            util.Effect("Physcannon_Tracer", laserEffect)
        end)
        
        timer.Simple(1.5, function()
            if not IsValid(ply) or not ply:Alive() then 
                if IsValid(ply) then ply:SetNWBool("HLRPG_IsCastingUlt", false) end
                return 
            end
            
            ply:SetArmor(0)
            local aimDir = ply:GetAimVector()
            ply:SetVelocity(aimDir * -1200)
            ply:ViewPunch(Angle(-20, 0, 0))
            ply:EmitSound("npc/strider/fire.wav", 100, 100)
            
            local bullet = {
                Num = 1, Src = ply:GetShootPos(), Dir = aimDir,
                Tracer = 1, TracerName = "StriderTracer", Force = 8000, Damage = 0,
                Callback = function(att, tr)
                    local hp = tr.HitPos
                    local ed = EffectData()
                    ed:SetOrigin(hp)
                    util.Effect("HelicopterMegaBomb", ed) 
                    util.Effect("cball_explode", ed) 
                    util.ScreenShake(hp, 50, 50, 2.5, 3000)
                    
                    local dmg = DamageInfo()
                    dmg:SetAttacker(att)
                    dmg:SetDamage(2000)
                    dmg:SetDamageType(bit.bor(DMG_DISSOLVE, DMG_SHOCK, DMG_BLAST))
                    
                    for _, target in ipairs(ents.FindInSphere(hp, 350)) do
                        if IsValid(target) and target != att and not target:IsWorld() then
                            target:TakeDamageInfo(dmg)
                            if target:GetClass() == "prop_physics" then target:Fire("dissolve", "", 0) end
                        end
                    end
                end
            }
            ply:FireBullets(bullet)
            
            timer.Simple(1, function()
                if IsValid(ply) then ply:SetNWBool("HLRPG_IsCastingUlt", false) end
            end)
        end)
    end
}

HLRPG.Skills.Database = SKILLS