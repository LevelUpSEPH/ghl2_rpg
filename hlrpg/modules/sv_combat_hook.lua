-- addons/halflife_rpg/lua/hlrpg/modules/sv_combat_hook.lua

if not SERVER then return end

-- 1. MERMİ ÇIKIŞI
hook.Add("EntityFireBullets", "HLRPG_Core_FireBullets", function(ply, data)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    
    -- O anki duruma göre (Global + Elindeki Silah) hesaplanmış listeyi al
    local activeMods = ply:GetCalculatedModifiers(wep:GetClass())
    
    -- Listeyi gez ve hookları tetikle
    for modID, val in pairs(activeMods) do
        -- Modifier Tanımını bul (sh_modifiers.lua dosyasından)
        local def = HLRPG.Modifiers.Definitions[modID]
        
        if def and def.OnFireBullets then
            -- Modifier'a "Mermi verisini değiştir" diyoruz
            local newData = def.OnFireBullets(ply, data, val)
            if newData then data = newData end
        end
    end
    
    return true
end)

-- 2. HASAR VURMA
hook.Add("EntityTakeDamage", "HLRPG_Core_Damage", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    
    if IsValid(attacker) and attacker:IsPlayer() then
        local wep = attacker:GetActiveWeapon()
        local wepClass = IsValid(wep) and wep:GetClass() or nil
        
        -- Yine hesaplanmış listeyi al
        local activeMods = attacker:GetCalculatedModifiers(wepClass)
        
        for modID, val in pairs(activeMods) do
            local def = HLRPG.Modifiers.Definitions[modID]
            
            if def and def.OnDamage then
                def.OnDamage(attacker, target, dmginfo, val)
            end
        end
    end
end)