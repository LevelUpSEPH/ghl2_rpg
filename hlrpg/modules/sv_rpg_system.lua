-- addons/halflife_rpg/lua/hlrpg/modules/sv_rpg_system.lua

if not SERVER then return end

util.AddNetworkString("HLRPG_XPNotify")

print("[HLRPG] Core RPG System Yukleniyor...")

local function PerformLevelUp(ply)
    local currentLevel = ply.HLRPG_Level or 1
    local levelsGained = 0
    local xp = ply:GetXP()
    
    while xp >= HLRPG_GetRequiredXP(currentLevel + levelsGained) do
        levelsGained = levelsGained + 1
    end

    if levelsGained > 0 then
        local newLevel = currentLevel + levelsGained
        ply.HLRPG_Level = newLevel
        
        ply:SaveLevel(newLevel) 

        local newMax = 100 + ((newLevel - 1) * 10) + (ply.HLRPG_BonusHP or 0)
        ply:SetMaxHealth(newMax)
        ply:SetHealth(newMax)

        ply:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 100, 120)
        ply:ChatPrint(">>> LEVEL UP: " .. newLevel .. " <<<")
    end

    ply:SetNWInt("HLRPG_MaxXP", HLRPG_GetRequiredXP(ply.HLRPG_Level))
end

function HLRPG_AddXP(ply, amount)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not amount or amount <= 0 then return end

    ply:SaveXP(amount) 

    PerformLevelUp(ply)
end

hook.Add("PlayerSpawn", "HLRPG_ApplyStats", function(ply)    
    timer.Simple(0.1, function()
        if IsValid(ply) and ply.HLRPG_Level then
            local maxHealth = 100 + ((ply.HLRPG_Level - 1) * 10)
            ply:SetMaxHealth(maxHealth)
            ply:SetHealth(maxHealth)
        end
    end)
end)

hook.Add("OnNPCKilled", "HLRPG_XP_System", function(npc, attacker, inflictor)
    if not npc.HLRPG_DamageTable then return end

    local totalXPAward =  HLRPG.NPC_XP[npc:GetClass()] or HLRPG.DefaultXP
    local totalDamage = 0
    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) then totalDamage = totalDamage + dmg end
    end

    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) and ply:IsPlayer() and totalDamage > 0 then
            local ratio = dmg / totalDamage
            local xpGain = math.Round(totalXPAward * ratio)

            if xpGain > 0 then
                HLRPG_AddXP(ply, xpGain)

                net.Start("HLRPG_XPNotify")
                    net.WriteInt(xpGain, 32)
                    net.WriteInt(math.Round(ratio * 100), 16)
                    net.WriteString((HLRPG_GetNPCName and HLRPG_GetNPCName(npc)) or npc:GetClass():upper())
                    net.WriteColor(Color(255, 255, 255))
                net.Send(ply)
            end
        end
    end
end)