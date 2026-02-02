-- sv_achievement_core.lua
util.AddNetworkString("HLRPG_AchievementNotify")
util.AddNetworkString("HLRPG_OpenAchievementMenu")
util.AddNetworkString("HLRPG_AchievementAnnounce")

function HLRPG_AwardAchievement(ply, achID)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local ach = HLRPG.Achievements[achID]
    if not ach then return end

    -- 1. BAŞARIMI SUNUCUDA İŞLE (Persistence/Kayıt için burası asıl kaynaktır)
    ply.UnlockedAchievements = ply.UnlockedAchievements or {}
    
    -- Eğer zaten açılmışsa fonksiyondan çık
    if ply.UnlockedAchievements[achID] then return end
    
    ply.UnlockedAchievements[achID] = true

    -- 2. RPG SİSTEMİNE XP AKTAR
    if ach.xp and ach.xp > 0 then
        HLRPG_AddXP(ply, ach.xp)
    end

    if ach.rewardItem then
        HLRPG_GiveItem(ply, ach.rewardItem, "Başarım: " .. ach.name)
    end

    -- 3. HEMEN HUD BİLDİRİMİ GÖNDER
    net.Start("HLRPG_AchievementNotify")
        net.WriteString(achID)
        net.WriteString(ach.name)
        net.WriteString(ach.desc or "")
        net.WriteInt(ach.xp or 0, 32)
        net.WriteString(ach.rewardItem or "")
        net.WriteString(ach.icon or "")
    net.Send(ply)

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
end

-- 4. MENÜ İSTEĞİNİ KARŞILA (Sadece sunucudaki güncel tabloyu gönderir)
hook.Add("PlayerSay", "HLRPG_AchievementChatCommand", function(ply, text)
    local cmd = string.lower(text)
    if cmd == "!achievement" or cmd == "!ach" then
        net.Start("HLRPG_OpenAchievementMenu")
            net.WriteTable(ply.UnlockedAchievements or {}) 
        net.Send(ply)
        return ""
    end
end)