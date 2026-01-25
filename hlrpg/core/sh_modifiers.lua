-- addons/halflife_rpg/lua/hlrpg/core/sh_modifiers.lua

HLRPG = HLRPG or {}
HLRPG.Modifiers = {}

-- MODIFIER TANIMLARI
-- Her modifier'ın hooklarda nasıl davranacağını burada belirleriz.

local DEF = {}

DEF["mod_fire_ammo"] = {
    Name = "Incendiary Rounds",
    Desc = "Mermiler hedefini yakar.",
    
    OnFireBullets = function(ply, data, val)
        data.TracerName = "AR2Tracer"
        return data
    end,
    
    OnDamage = function(ply, target, dmginfo, val)
        if math.random(1, 100) <= (val or 30) then
            if target:IsNPC() or target:IsPlayer() then
                target:Ignite(3)
                target:EmitSound("ambient/fire/ignite.wav")
            end
        end
    end
}

DEF["mod_double_pellet"] = {
    Name = "Splitter",
    Desc = "Shotgun saçma sayısını artırır.",
    
    OnFireBullets = function(ply, data, val)
        local mult = val or 2
        data.Num = math.floor(data.Num * mult)
        data.Spread = data.Spread * 1.2
        return data
    end
}

DEF["mod_lifesteal"] = {
    Name = "Vampirism",
    Desc = "Verilen hasarın bir kısmını can olarak çeker.",
    
    OnDamage = function(ply, target, dmginfo, val)
        local dmg = dmginfo:GetDamage()
        local heal = dmg * (val or 0.1) -- %10 varsayılan
        
        local max = ply:GetMaxHealth()
        local current = ply:Health()
        if current < max then
            ply:SetHealth(math.min(max, current + heal))
        end
    end
}

DEF["mod_knockback"] = {
    Name = "Heavy Impact",
    Desc = "Hedefi geri iter.",
    
    OnDamage = function(ply, target, dmginfo, val)
        local force = val or 300
        local dir = ply:GetAimVector() * force
        dir.z = 50 -- Hafif yukarı
        target:SetVelocity(dir)
    end
}

HLRPG.Modifiers.Definitions = DEF