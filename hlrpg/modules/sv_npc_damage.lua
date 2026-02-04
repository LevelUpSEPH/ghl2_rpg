-- hlrpg/modules/sv_combat_master.lua
if not SERVER then return end

print("[HLRPG] Master Combat System Yükleniyor...")

hook.Add("EntityTakeDamage", "HLRPG_Combat_Master", function(target, dmginfo)
    if not IsValid(target) then return end
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()

    if IsValid(attacker) and attacker:IsPlayer() then
        if target:IsPlayer() and target != attacker then
            dmginfo:SetDamage(0)
            return true
        end

        local friendlyNPCs = { 
            ["npc_kleiner"] = true, ["npc_barney"] = true, ["npc_citizen"] = true, 
            ["npc_alyx"] = true, ["npc_dog"] = true, ["npc_vortigaunt"] = true,
            ["npc_eli"] = true, ["npc_magnusson"] = true
        }
        if target:IsNPC() and friendlyNPCs[target:GetClass()] then
            dmginfo:SetDamage(0)
            return true
        end
    end

    if IsValid(attacker) and attacker:IsNPC() then
        local npcLevel = attacker:GetNWInt("HLRPG_NPCLevel", 1)
        
        if HLRPG_CalculateStat then
            local baseDamage = dmginfo:GetDamage()
            local scaledDamage = HLRPG_CalculateStat(baseDamage, "DMG", npcLevel)
            
            if attacker:GetNWBool("HLRPG_IsBoss") then
                scaledDamage = scaledDamage * 1.5
            end
            dmginfo:SetDamage(scaledDamage)
        end
    end

    if attacker.IsHLRPGPet and IsValid(attacker.OwnerPly) then
        local stats = attacker.CurrentStats
        if stats then
            local finalScale = stats.dmgMultiplier + ((stats.level - 1) * 0.1)
            dmginfo:ScaleDamage(finalScale)
        end

        if target:IsPlayer() or (target:IsNPC() and target:Disposition(attacker.OwnerPly) == D_LI) then
            dmginfo:SetDamage(0)
            return true
        end
    end

    if target.IsHLRPGPet and IsValid(target.OwnerPly) then
        if attacker:IsPlayer() or (attacker:IsNPC() and attacker:Disposition(target.OwnerPly) == D_LI) then
            dmginfo:SetDamage(0)
            return true
        end

        timer.Simple(0, function()
            if IsValid(target) and IsValid(target.OwnerPly) then
                target.OwnerPly:SetNWInt("HLRPG_Pet_CurHP", target:Health())
                target.OwnerPly:SetNWInt("HLRPG_Pet_MaxHP", target:GetMaxHealth())
            end
        end)
    end

    if IsValid(attacker) and attacker:IsPlayer() then
        local wep = attacker:GetActiveWeapon()
        local wepClass = IsValid(wep) and wep:GetClass() or nil
        local activeMods = attacker:GetCalculatedModifiers(wepClass)
        
        for modID, val in pairs(activeMods) do
            local def = HLRPG.Modifiers.Definitions[modID]
            if def and def.OnDamage then
                def.OnDamage(attacker, target, dmginfo, val)
            end
        end
    end

    if target:IsNPC() and IsValid(attacker) and attacker:IsPlayer() then
        target.HLRPG_DamageTable = target.HLRPG_DamageTable or {}
        local actualDmg = math.min(dmginfo:GetDamage(), target:Health())
        target.HLRPG_DamageTable[attacker] = (target.HLRPG_DamageTable[attacker] or 0) + actualDmg
    end

    if target:IsPlayer() and not target.IsZombieForm then
        local currentHealth = target:Health()
        local incomingDamage = dmginfo:GetDamage()
        
        if (currentHealth - incomingDamage) <= 0 then
            local hatID = target:GetNWString("HLRPG_ActiveHat", "")
            local asset = HLRPG_Assets[hatID]

            if asset and asset.OnDeathPrevention and not target.UsedZombieLife then
                dmginfo:SetDamage(0)
                target:SetHealth(1)
                target.UsedZombieLife = true
                
                local success, err = pcall(function()
                    asset.OnDeathPrevention(target)
                end)

                if not success then
                    print("[HLRPG ERROR] OnDeathPrevention Hatası: ", err)
                    target:Kill() 
                else
                    print("[HLRPG] OnDeathPrevention başarıyla çalıştırıldı.")
                    target:SetSaveValue("m_takedamage", 0)
                end
                return true
            end
        end
    end
end)