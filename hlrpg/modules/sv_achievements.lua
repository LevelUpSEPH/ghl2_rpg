-- hlrpg/modules/sv_achievements.lua
-- Achievements and lambda caches. Map events come from sh_achievement_events.lua;
-- custom listeners live in modules/custom_achievement_listeners/.

util.AddNetworkString("HLRPG_AchievementNotify")
util.AddNetworkString("HLRPG_AchievementAnnounce")
util.AddNetworkString("HLRPG_OpenAchievementMenu")
util.AddNetworkString("HLRPG_LambdaNotify")
util.AddNetworkString("HLRPG_OpenLambdaMenu")

function HLRPG.AwardAchievement(ply, achID)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local ach = HLRPG.Achievements[achID]
    if not ach then return end

    ply.UnlockedAchievements = ply.UnlockedAchievements or {}
    if ply.UnlockedAchievements[achID] then return end
    ply.UnlockedAchievements[achID] = true

    local xp = HLRPG.GetKillEquivalentXP(ach.kills or 0, ply:GetLevel())
    if xp > 0 then
        HLRPG.AddXP(ply, xp)
    end

    if ach.rewardItem then
        HLRPG.GiveItem(ply, ach.rewardItem, "Achievement: " .. ach.name)
    end

    net.Start("HLRPG_AchievementNotify")
        net.WriteString(achID)
        net.WriteString(ach.name)
        net.WriteString(ach.desc or "")
        net.WriteInt(xp, 32)
        net.WriteString(ach.rewardItem or "")
        net.WriteString(ach.icon or "")
    net.Send(ply)

    ply:SaveAchievements()

    net.Start("HLRPG_AchievementAnnounce")
        net.WriteEntity(ply)
        net.WriteString(ach.name)
    net.Broadcast()
end

-- Gives rewards for achievements unlocked before their reward existed (or changed)
hook.Add("HLRPG_PlayerDataLoaded", "HLRPG_MissingAchievementRewards", function(ply)
    for achID in pairs(ply.UnlockedAchievements or {}) do
        local ach = HLRPG.Achievements[achID]
        if ach and ach.rewardItem and HLRPG.Assets[ach.rewardItem] and not ply:OwnsItem(ach.rewardItem) then
            HLRPG.GiveItem(ply, ach.rewardItem, "Achievement: " .. ach.name)
        end
    end
end)

-- Progress counters live in ply.HLRPG_Counters (saved). A counter is a number, or for collections a set
-- of found items; either way its value is what achievements with that `counter` compare to their goal.
local function GetCounterValue(value)
    return istable(value) and table.Count(value) or (value or 0)
end

local function CheckCounterAchievements(ply, counter)
    local value = GetCounterValue(ply.HLRPG_Counters[counter])
    for achID, ach in pairs(HLRPG.Achievements) do
        if ach.counter == counter and value >= ach.goal then
            HLRPG.AwardAchievement(ply, achID)
        end
    end
end

-- Adds to a number counter
function HLRPG.AddCounter(ply, counter, amount)
    if not IsValid(ply) or not ply.HLRPG_Counters then return end

    ply.HLRPG_Counters[counter] = (ply.HLRPG_Counters[counter] or 0) + (amount or 1)
    ply:SaveCounters()
    CheckCounterAchievements(ply, counter)
end

-- Adds an item to a collection counter (finding the same item twice does nothing).
-- quiet skips the chat line, for big collections like the 333 grubs.
function HLRPG.AddCollectionItem(ply, collection, item, quiet)
    if not IsValid(ply) or not ply.HLRPG_Counters then return end

    local found = ply.HLRPG_Counters[collection]
    if not istable(found) then found = {} ply.HLRPG_Counters[collection] = found end
    if found[item] then return end

    found[item] = true
    ply:SaveCounters()
    if not quiet then
        ply:ChatPrint("[ACH] Found " .. table.Count(found) .. " for " .. collection:gsub("_", " ") .. ".")
    end
    CheckCounterAchievements(ply, collection)
end

-- Challenges: started for everyone present, failed per player, awarded at the end to whoever is still in.
-- State is kept in the counters ("challenge_<id>" = 1 active, 0 failed) so it survives map changes.
local function ChallengeKey(challenge) return "challenge_" .. challenge end

function HLRPG.IsChallengeActive(ply, challenge)
    return ply.HLRPG_Counters ~= nil and ply.HLRPG_Counters[ChallengeKey(challenge)] == 1
end

function HLRPG.FailChallenge(ply, challenge, achID)
    if not HLRPG.IsChallengeActive(ply, challenge) then return end

    ply.HLRPG_Counters[ChallengeKey(challenge)] = 0
    ply:SaveCounters()
    local ach = HLRPG.Achievements[achID]
    ply:ChatPrint("[ACH] Challenge failed: " .. (ach and ach.name or challenge))
end

local function StartChallenge(challenge, achID)
    local ach = HLRPG.Achievements[achID]
    for _, ply in ipairs(player.GetAll()) do
        if ply.HLRPG_Counters and not (ply.UnlockedAchievements or {})[achID] then
            ply.HLRPG_Counters[ChallengeKey(challenge)] = 1
            ply:SaveCounters()
            ply:ChatPrint("[ACH] Challenge started: " .. ach.name .. " (" .. ach.desc .. ")")
        end
    end
end

local function EndChallenge(challenge, achID)
    for _, ply in ipairs(player.GetAll()) do
        if HLRPG.IsChallengeActive(ply, challenge) then
            HLRPG.AwardAchievement(ply, achID)
        end
        if ply.HLRPG_Counters and ply.HLRPG_Counters[ChallengeKey(challenge)] ~= nil then
            ply.HLRPG_Counters[ChallengeKey(challenge)] = nil
            ply:SaveCounters()
        end
    end
end

function HLRPG.AwardAchievementToAll(achID)
    for _, ply in ipairs(player.GetAll()) do
        HLRPG.AwardAchievement(ply, achID)
    end
end

-- Returns the XP given (0 if the cache was already found).
-- Other addons can react with hook.Add("HLRPG_LambdaFound", ..., function(ply, lambdaID) end)
function HLRPG.AwardLambda(ply, lambdaID)
    if not IsValid(ply) or not ply:IsPlayer() then return 0 end

    ply.HLRPG_FoundLambdas = ply.HLRPG_FoundLambdas or {}
    if ply.HLRPG_FoundLambdas[lambdaID] then return 0 end
    ply.HLRPG_FoundLambdas[lambdaID] = true

    hook.Run("HLRPG_LambdaFound", ply, lambdaID)

    local xp = HLRPG.GetKillEquivalentXP(HLRPG.LambdaCacheKills, ply:GetLevel())
    HLRPG.AddXP(ply, xp)

    if table.Count(ply.HLRPG_FoundLambdas) == table.Count(HLRPG.LambdaMap) then
        HLRPG.AwardAchievement(ply, "HL2_LAMBDA_LOCATOR")
    end

    ply:SaveLambdas()
    return xp
end

local function GetTriggeringPlayer(activator)
    if IsValid(activator) and activator:IsPlayer() then return activator end
    return player.GetAll()[1]
end

local function AwardFromEvent(achID, activator)
    local ach = HLRPG.Achievements[achID]
    if not ach then
        print("[HLRPG] Error: achievement event points to an undefined achievement - " .. achID)
    elseif ach.isGlobal then
        HLRPG.AwardAchievementToAll(achID)
    else
        HLRPG.AwardAchievement(GetTriggeringPlayer(activator), achID)
    end
end

-- Called by the maps' logic_achievement entities (entities/logic_achievement.lua).
-- Other addons can react with hook.Add("HLRPG_AchievementEvent", ..., function(event, activator) end)
function HLRPG.OnAchievementEvent(event, activator)
    hook.Run("HLRPG_AchievementEvent", event, activator)

    local lambda = HLRPG.LambdaMap[event]
    if lambda then
        local ply = GetTriggeringPlayer(activator)
        if not IsValid(ply) then return end

        local xp = HLRPG.AwardLambda(ply, lambda.id)
        net.Start("HLRPG_LambdaNotify")
            net.WriteString(lambda.id)
            net.WriteInt(xp, 32)
        net.Send(ply)
        return
    end

    local handler = HLRPG.AchievementEvents[event]
    if isstring(handler) then
        AwardFromEvent(handler, activator)
    elseif istable(handler) then
        if handler.collection then
            local ply = GetTriggeringPlayer(activator)
            if IsValid(ply) then HLRPG.AddCollectionItem(ply, handler.collection, handler.item) end
        elseif handler.challengeStart then
            StartChallenge(handler.challengeStart, handler.achievement)
        elseif handler.challengeEnd then
            EndChallenge(handler.challengeEnd, handler.achievement)
        end
    end
end

-- Achievements for finishing a campaign (completeCampaign), when its ending credits roll (sv_campaign_runs.lua)
hook.Add("HLRPG_CampaignCompleted", "HLRPG_CampaignAchievements", function(campaignID)
    for achID, ach in pairs(HLRPG.Achievements) do
        if ach.completeCampaign == campaignID then HLRPG.AwardAchievementToAll(achID) end
    end
end)

hook.Add("WeaponEquip", "HLRPG_CrowbarAchievement_Pickup", function(weapon, ply)
    if not IsValid(weapon) or not IsValid(ply) then return end

    if weapon:GetClass() == "weapon_crowbar" and game.GetMap() == "d1_trainstation_06" then
        HLRPG.AwardAchievement(ply, "HL2_TRUSTY_HARDWARE")
    end
end)

local function OpenAchievementMenu(ply)
    net.Start("HLRPG_OpenAchievementMenu")
        net.WriteTable(ply.UnlockedAchievements or {})
        net.WriteTable(ply.HLRPG_Counters or {})
    net.Send(ply)
end

local function OpenLambdaMenu(ply)
    net.Start("HLRPG_OpenLambdaMenu")
        net.WriteTable(ply.HLRPG_FoundLambdas or {})
    net.Send(ply)
end

HLRPG.AddChatCommand("!achievement", OpenAchievementMenu)
HLRPG.AddChatCommand("!ach", OpenAchievementMenu)
HLRPG.AddChatCommand("!lambda", OpenLambdaMenu)

-- Opened from the TAB menu with HLRPG.RequestMenu
HLRPG.AddMenuRequest("achievements", OpenAchievementMenu)
HLRPG.AddMenuRequest("lambdas", OpenLambdaMenu)
