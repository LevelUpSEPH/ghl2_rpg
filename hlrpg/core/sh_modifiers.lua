-- addons/halflife_rpg/lua/hlrpg/core/sh_modifiers.lua

HLRPG = HLRPG or {}
HLRPG.Modifiers = {}

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

HLRPG.Modifiers.Definitions = DEF