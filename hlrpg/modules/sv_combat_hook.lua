-- addons/halflife_rpg/lua/hlrpg/modules/sv_combat_hook.lua

if not SERVER then return end

hook.Add("EntityFireBullets", "HLRPG_Core_FireBullets", function(ply, data)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    
    local activeMods = ply:GetCalculatedModifiers(wep:GetClass())
    
    for modID, val in pairs(activeMods) do
        local def = HLRPG.Modifiers.Definitions[modID]
        
        if def and def.OnFireBullets then
            local newData = def.OnFireBullets(ply, data, val)
            if newData then data = newData end
        end
    end
    
    return true
end)