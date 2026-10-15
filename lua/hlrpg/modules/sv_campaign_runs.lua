-- hlrpg/modules/sv_campaign_runs.lua
-- Tracks each player's run through the current campaign (core/sh_runs.lua). A run is saved per player as
-- { campaign, index, minDifficulty, died, elapsed } so it survives map changes; disconnecting deletes it.
-- The outro credits on the campaign's last map complete every valid run.
-- elapsed is the run's play time in seconds, up to the current map; map loading isn't counted.

local RUN_KEY = "HLRPG_CampaignRun"

-- The campaign the gamemode is playing, and its map order (nil outside Lambda's campaigns)
local function GetActiveCampaign()
    if not GAMEMODE.GetMapList then return nil end

    local ok, mapList = pcall(GAMEMODE.GetMapList, GAMEMODE)
    if not ok or not mapList or #mapList == 0 then return nil end

    for _, campaign in ipairs(HLRPG.Campaigns) do
        if mapList[1] == campaign.firstMap then return campaign, mapList end
    end
end

local function IndexOf(list, value)
    for i, v in ipairs(list) do
        if v == value then return i end
    end
end

local function LoadRun(ply)
    local raw = ply:GetPData(RUN_KEY)
    return raw and util.JSONToTable(raw) or nil
end

local function SaveRun(ply, run)
    ply.HLRPG_Run = run
    if run then
        ply:SetPData(RUN_KEY, util.TableToJSON(run))
    else
        ply:RemovePData(RUN_KEY)
    end
end

-- Play time so far: earlier maps plus time on this one since the player loaded in
local function GetRunTime(ply, run)
    return (run.elapsed or 0) + CurTime() - (ply.HLRPG_RunClock or CurTime())
end

-- Banks this map's time into the saved run, before the map changes
local function BankRunTime()
    for _, ply in ipairs(player.GetAll()) do
        local run = ply.HLRPG_Run
        if run then
            run.elapsed = GetRunTime(ply, run)
            ply.HLRPG_RunClock = CurTime()
            SaveRun(ply, run)
        end
    end
end

hook.Add("LambdaPreChangelevel", "HLRPG_RunTime", BankRunTime)
hook.Add("ShutDown", "HLRPG_RunTime", BankRunTime)

-- Skipped maps. Walking through a map's own exit is a changelevel with a landmark; votes (skip map, change map,
-- the end-of-campaign map vote) change level without one. Reloading the same map isn't a skip.
function HLRPG.IsSkipChange(nextMap, landmark)
    return (landmark == nil or landmark == "") and string.lower(nextMap or "") ~= game.GetMap():lower()
end

-- Once maps were skipped, finishing the campaign gives no completion achievements until a campaign is started
-- again from its first map. Kept in a file because the map change reloads all Lua.
local SKIPPED_FILE = "hlrpg/maps_skipped.txt"

local function MapsWereSkipped() return file.Exists(SKIPPED_FILE, "DATA") end

hook.Add("InitPostEntity", "HLRPG_SkippedReset", function()
    local map = game.GetMap():lower()
    for _, campaign in ipairs(HLRPG.Campaigns) do
        if campaign.firstMap == map then file.Delete(SKIPPED_FILE) return end
    end
end)

-- A skip ends everyone's run and fails their running challenges
hook.Add("LambdaPreChangelevel", "HLRPG_MapSkipped", function(nextMap, landmark)
    if not HLRPG.IsSkipChange(nextMap, landmark) then return end
    file.CreateDir("hlrpg")
    file.Write(SKIPPED_FILE, game.GetMap():lower() .. " > " .. tostring(nextMap))

    for _, ply in ipairs(player.GetAll()) do
        if ply.HLRPG_Run then
            SaveRun(ply, nil)
            ply:ChatPrint("[RUN] Your run ended: the map was skipped.")
        end
        HLRPG.FailAllChallenges(ply, "the map was skipped")
    end
end)

local function Notify(ply, message)
    ply:ChatPrint("[RUN] " .. message)
end

local function IsLockedIn(run, campaign, mapList)
    return run.index > (IndexOf(mapList, campaign.lockMap) or 0)
end

-- Difficulty only counts after the lock-in map; from then on the lowest one is kept.
-- Returns true if the counted difficulty went down.
local function TrackDifficulty(run, campaign, mapList)
    if not IsLockedIn(run, campaign, mapList) then return false end

    local _, current = HLRPG.GetDifficulty()
    local previous = run.minDifficulty
    run.minDifficulty = math.min(previous or current, current)
    return previous ~= nil and run.minDifficulty < previous
end

local function DescribeProgress(run, campaign, mapList)
    local status = string.format("%s run: map %d/%d, %s", campaign.name, run.index, #mapList, HLRPG.FormatTime(run.elapsed))
    if not run.died then status = status .. ", no deaths" end
    if run.minDifficulty then
        return status .. ", counting difficulty: " .. HLRPG.DifficultyScales[run.minDifficulty].name
    end
    return status .. ", difficulty locks in after " .. campaign.lockMap
end

-- On join and after every map change: start, continue or drop the player's run
local function UpdateRun(ply)
    local campaign, mapList = GetActiveCampaign()
    if not campaign then return end

    local map = game.GetMap():lower()
    local run = LoadRun(ply)
    local hadRun = run ~= nil and run.campaign == campaign.id

    if run and run.campaign == campaign.id then
        if mapList[run.index + 1] == map then
            run.index = run.index + 1
        elseif mapList[run.index] ~= map then
            run = nil -- skipped ahead or joined somewhere else
        end
    else
        run = nil
    end

    local started = false
    if not run and map == campaign.firstMap then
        run = { campaign = campaign.id, index = 1 }
        started = true
    end

    if run then TrackDifficulty(run, campaign, mapList) end
    ply.HLRPG_RunClock = CurTime()
    SaveRun(ply, run)

    if started then
        Notify(ply, campaign.name .. " run started! Stay connected until the end.")
    elseif run then
        Notify(ply, DescribeProgress(run, campaign, mapList))
    elseif hadRun then
        Notify(ply, "Your " .. campaign.name .. " run ended: you missed a map.")
    end
end

hook.Add("HLRPG_PlayerDataLoaded", "HLRPG_CampaignRun", UpdateRun)

hook.Add("PlayerDisconnected", "HLRPG_CampaignRunBreak", function(ply)
    SaveRun(ply, nil)
end)

hook.Add("PlayerDeath", "HLRPG_CampaignRunDeath", function(ply)
    local run = ply.HLRPG_Run
    if not run or run.died then return end

    run.died = true
    SaveRun(ply, run)
    Notify(ply, "You died: no more No Death Run this time. The run itself still counts.")
end)

hook.Add("HLRPG_DifficultyChanged", "HLRPG_CampaignRunDifficulty", function()
    local campaign, mapList = GetActiveCampaign()
    if not campaign then return end

    for _, ply in ipairs(player.GetAll()) do
        local run = ply.HLRPG_Run
        if run then
            if TrackDifficulty(run, campaign, mapList) then
                Notify(ply, "Run difficulty lowered to " .. HLRPG.DifficultyScales[run.minDifficulty].name .. ".")
            end
            SaveRun(ply, run)
        end
    end
end)

-- Every campaign ends by rolling the outro credits on its last map
hook.Add("AcceptInput", "HLRPG_CampaignRunEnd", function(ent, input)
    if input ~= "RollOutroCredits" or not IsValid(ent) or ent:GetClass() ~= "env_credits" then return end

    local campaign, mapList = GetActiveCampaign()
    if not campaign then return end

    if MapsWereSkipped() then
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[ACH] Maps were skipped on the way here, so this ending gives no completion achievements. " ..
                "Start from " .. campaign.firstMap .. " to earn them.")
        end
        return
    end

    hook.Run("HLRPG_CampaignCompleted", campaign.id)

    for _, ply in ipairs(player.GetAll()) do
        local run = ply.HLRPG_Run
        if run and run.campaign == campaign.id and run.index == #mapList and run.minDifficulty then
            hook.Run("HLRPG_RunFinished", ply, campaign, GetRunTime(ply, run), run.minDifficulty)
            HLRPG.AwardAchievement(ply, HLRPG.GetCampaignRunAchievement(campaign.id, run.minDifficulty))
            if not run.died then
                HLRPG.AwardAchievement(ply, HLRPG.GetDeathlessRunAchievement(campaign.id))
            end
            SaveRun(ply, nil)
        end
    end
end)
