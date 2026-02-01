-- sv_achievement_logic.lua

hook.Add("AcceptInput", "HLRPG_Achievement_Bridge", function(ent, input, activator, caller, value)
    local targetName = IsValid(ent) and ent:GetName() or ""
    local callerName = IsValid(caller) and caller:GetName() or ""
    local currentMap = game.GetMap():lower()
    
    local isTriggered = (input == "Trigger" or input == "FireEvent" or input == "OnFound" or input == "Start")
    if not isTriggered then return end

    -- Öncelik ismini belirle (Target varsa target, yoksa caller)
    local name = (targetName != "") and targetName or callerName
    if name == "" then return end

    -- 1. LAMBDA KONTROLÜ (Harita Önemli!)
    -- Lambda anahtarını harita ön ekiyle oluşturuyoruz: "d1_canals_01_relay_achievement_cache_1"
    local lambdaKey = currentMap .. "_" .. name
    print("[HLRPG] Lambda Kontrolü: " .. lambdaKey)
    local lambdaID = HLRPG.LambdaMap[lambdaKey]
    
    if lambdaID then
        print("[HLRPG] Lambda Başarımları Tetiklendi: " .. lambdaKey .. " -> " .. lambdaID)
        local ply = (IsValid(activator) and activator:IsPlayer()) and activator or player.GetAll()[1]
        if HLRPG.Lambda and HLRPG.Lambda.OnFound then
            HLRPG.Lambda.OnFound(ply, lambdaID)
        else
            print("[HLRPG] Lambda Yakalandı: " .. lambdaID)
        end
        return
    end

    -- 2. ACHIEVEMENT KONTROLÜ (Harita Önemli DEĞİL!)
    -- Sadece 'name' üzerinden (lcs_CupCop_Fail gibi) saf kontrol yapıyoruz
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