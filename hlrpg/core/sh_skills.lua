-- addons/halflife_rpg/lua/hlrpg/core/sh_skills.lua

HLRPG = HLRPG or {}
HLRPG.Skills = {}

local SKILLS = {}

SKILLS["tech_stimpack"] = {
    Name = "Bio-Stimpack",
    Desc = "HEV Suit rezervlerini kullanarak doku onarımı yapar.",
    Cooldown = 15,
    
    OnCast = function(ply)
        local baseHeal = 20
        
        local boost = ply:GetModifierVal("mod_med_efficiency") or 0 
        local finalHeal = baseHeal * (1 + boost)
        
        local max = ply:GetMaxHealth()
        ply:SetHealth(math.min(max, ply:Health() + finalHeal))
        
        ply:EmitSound("items/medshot4.wav")
        ply:ChatPrint("Biyo-Onarım Tamamlandı: +" .. math.floor(finalHeal) .. " HP")
    end
}

SKILLS["tech_micro_missile"] = {
    Name = "Micro-Missile",
    Desc = "Patlayıcı bir mini roket fırlatır.",
    Cooldown = 8,
    
    OnCast = function(ply)
        local missile = ents.Create("rpg_missile")
        if IsValid(missile) then
            local aim = ply:GetAimVector()
            local pos = ply:GetShootPos() + aim * 10 + Vector(0,0,-5) -- Biraz aşağıdan çıksın
            
            missile:SetPos(pos)
            missile:SetAngles(aim:Angle())
            missile:SetOwner(ply)
            missile:Spawn()
            missile:SetSaveValue("m_flDamage", 50) -- 50 Hasar
            
            -- Roketi fırlat
            local phys = missile:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(aim * 1500)
            end
        end
        
        ply:EmitSound("weapons/rpg/rocketfire1.wav")
    end
}

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
        
        ply:DoAnimationEvent(ACT_GMOD_GESTURE_TAUNT_ZOMBIE) -- Bu her modelde kolların açılmasını sağlar
        
        local magicID = ply:LookupSequence("reload_magic")
        if magicID and magicID != -1 then
            ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_VCD, magicID, 0, true)
        end
        
        -- Ses ve Görsel Efektler
        ply:EmitSound("npc/strider/charging.wav", 100, 100)
        util.ScreenShake(ply:GetPos(), 4, 10, 1.5, 500)
        
        -- Görsel Telegraph (Ateş edene kadar her 0.1 saniyede çakar)
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
        
        -- 3. ATEŞLEME (1.5sn Sonra)
        timer.Simple(1.5, function()
            if not IsValid(ply) or not ply:Alive() then 
                if IsValid(ply) then ply:SetNWBool("HLRPG_IsCastingUlt", false) end
                return 
            end
            
            -- Mekanikler
            ply:SetArmor(0)
            local aimDir = ply:GetAimVector()
            ply:SetVelocity(aimDir * -1200)
            ply:ViewPunch(Angle(-20, 0, 0))
            ply:EmitSound("npc/strider/fire.wav", 100, 100)
            
            -- Mermi ve Patlama (Callback)
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