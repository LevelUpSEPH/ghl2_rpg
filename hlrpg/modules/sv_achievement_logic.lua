-- sv_achievement_logic.lua

util.AddNetworkString("HLRPG_LambdaNotify")

hook.Add("AcceptInput", "HLRPG_Achievement_Bridge", function(ent, input, activator, caller, value)
    local targetName = IsValid(ent) and ent:GetName() or ""
    local callerName = IsValid(caller) and caller:GetName() or ""
    local currentMap = game.GetMap():lower()
    
    local isTriggered = (input == "Trigger" or input == "FireEvent" or input == "OnFound" or input == "Start")
    if not isTriggered then return end

    local name = (targetName != "") and targetName or callerName
    if name == "" then return end

    local lambdaKey = currentMap .. "_" .. name
    local lambdaID = HLRPG.LambdaMap[lambdaKey]
    
    if lambdaID then
        local ply = (IsValid(activator) and activator:IsPlayer()) and activator or player.GetAll()[1]
        
        HLRPG_AwardLambda(ply, lambdaID)
        if HLRPG.Lambda and HLRPG.Lambda.OnFound then
            HLRPG.Lambda.OnFound(ply, lambdaID)
        end

        -- Lambda'ya Özel Bildirim Gönder
        net.Start("HLRPG_LambdaNotify")
            net.WriteString(lambdaID)
        net.Send(ply)
        
        return
    end

    -- print("[HLRPG] Trying for ACH: " .. name)

    local achID = HLRPG.AchievementTriggerMap[name]
    if achID then
        if HLRPG.Achievements[achID] == nil then
            print("[HLRPG] Hata: Başarımlarda tanımlı değil - " .. achID)
            return
        end
        if HLRPG.Achievements[achID].isGlobal then
            for _, ply in ipairs(player.GetAll()) do
                HLRPG_AwardAchievement(ply, achID)
            end
            return
        end
        local ply = (IsValid(activator) and activator:IsPlayer()) and activator or player.GetAll()[1]
        HLRPG_AwardAchievement(ply, achID)
    end
end)

hook.Add("WeaponEquip", "HLRPG_CrowbarAchievement_Pickup", function(weapon, ply)
    if not IsValid(weapon) or not IsValid(ply) then return end

    if weapon:GetClass() == "weapon_crowbar" then
        
        if game.GetMap() == "d1_trainstation_06" then
            HLRPG_AwardAchievement(ply, "HL2_TRUSTY_HARDWARE")
            
        end
    end
end)