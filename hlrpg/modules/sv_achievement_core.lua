-- sv_achievement_core.lua
util.AddNetworkString("HLRPG_AchievementNotify")
util.AddNetworkString("HLRPG_OpenAchievementMenu")
util.AddNetworkString("HLRPG_AchievementAnnounce")

function HLRPG_AwardAchievement(ply, achID)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local ach = HLRPG.Achievements[achID]
    if not ach then return end

    ply.UnlockedAchievements = ply.UnlockedAchievements or {}
    
    if ply.UnlockedAchievements[achID] then return end
    
    ply.UnlockedAchievements[achID] = true

    if ach.xp and ach.xp > 0 then
        HLRPG_AddXP(ply, ach.xp)
    end

    if ach.rewardItem then
        HLRPG_GiveItem(ply, ach.rewardItem, "Başarım: " .. ach.name)
    end

    net.Start("HLRPG_AchievementNotify")
        net.WriteString(achID)
        net.WriteString(ach.name)
        net.WriteString(ach.desc or "")
        net.WriteInt(ach.xp or 0, 32)
        net.WriteString(ach.rewardItem or "")
        net.WriteString(ach.icon or "")
    net.Send(ply)

    ply:SaveAchievements()

    net.Start("HLRPG_AchievementAnnounce")
        net.WriteEntity(ply)
        net.WriteString(ach.name)
    net.Broadcast()
end

function HLRPG_AwardLambda(ply, lambdaID)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    ply.HLRPG_FoundLambdas = ply.HLRPG_FoundLambdas or {}

    if ply.HLRPG_FoundLambdas[lambdaID] then return end

    ply.HLRPG_FoundLambdas[lambdaID] = true

    if HLRPG.Lambda and HLRPG.Lambda.OnFound then
        HLRPG.Lambda.OnFound(ply, lambdaID)
    end

    if table.Count(ply.HLRPG_FoundLambdas) == table.Count(HLRPG.LambdaMap) then
        HLRPG_AwardAchievement(ply, "HL2_LAMBDA_LOCATOR")
    end

    ply:SaveLambdas()
end

hook.Add("PlayerSay", "HLRPG_AchievementChatCommand", function(ply, text)
    local cmd = string.lower(text)
    if cmd == "!achievement" or cmd == "!ach" then
        net.Start("HLRPG_OpenAchievementMenu")
            net.WriteTable(ply.UnlockedAchievements or {}) 
        net.Send(ply)
        return ""
    end
end)