-- hlrpg/modules/sv_leaderboards.lua
-- Time leaderboards (core/sh_leaderboards.lua), stored server-wide in sv.db.
--   Map times: from the map starting (first player loaded in, or Lambda restarting the round) until the
--   group moves on to the next map of the campaign. Everyone present at that moment gets the time.
--   Run times: sent by sv_campaign_runs.lua when a run finishes (hook HLRPG_RunFinished).

util.AddNetworkString("HLRPG_OpenLeaderboards")

local TABLE = "hlrpg_leaderboard"

sql.Query("CREATE TABLE IF NOT EXISTS " .. TABLE .. " (board TEXT, steamid TEXT, name TEXT, seconds REAL, " ..
    "difficulty INTEGER, date INTEGER, PRIMARY KEY (board, steamid))")

-- Top rows of a board, fastest first: { { name, seconds, difficulty, date, steamid }, ... }
function HLRPG.GetLeaderboard(board, limit)
    local rows = sql.Query(string.format("SELECT * FROM %s WHERE board = %s ORDER BY seconds ASC LIMIT %d",
        TABLE, sql.SQLStr(board), limit or HLRPG.LeaderboardSize)) or {}

    for _, row in ipairs(rows) do
        row.seconds, row.difficulty, row.date = tonumber(row.seconds), tonumber(row.difficulty), tonumber(row.date)
    end
    return rows
end

-- 1-based position of a time on a board
local function GetRank(board, seconds)
    local count = sql.QueryValue(string.format("SELECT COUNT(*) FROM %s WHERE board = %s AND seconds < %f",
        TABLE, sql.SQLStr(board), seconds))
    return (tonumber(count) or 0) + 1
end

-- Saves a time if it's the player's best on that board. Returns true if it was.
function HLRPG.RecordTime(ply, board, seconds, difficulty)
    local previous = tonumber(sql.QueryValue(string.format("SELECT seconds FROM %s WHERE board = %s AND steamid = %s",
        TABLE, sql.SQLStr(board), sql.SQLStr(ply:SteamID()))))
    if previous and previous <= seconds then return false end

    sql.Query(string.format("INSERT OR REPLACE INTO %s VALUES (%s, %s, %s, %f, %d, %d)", TABLE,
        sql.SQLStr(board), sql.SQLStr(ply:SteamID()), sql.SQLStr(ply:Nick()), seconds, difficulty or 0, os.time()))
    return true
end

-- Deletes times: a whole board ("all" = every board), or only one SteamID's time on it. Returns rows removed.
function HLRPG.ClearTimes(board, steamID)
    local conditions = {}
    if board ~= "all" then conditions[#conditions + 1] = "board = " .. sql.SQLStr(board) end
    if steamID then conditions[#conditions + 1] = "steamid = " .. sql.SQLStr(steamID) end
    local where = #conditions > 0 and (" WHERE " .. table.concat(conditions, " AND ")) or ""

    local count = tonumber(sql.QueryValue("SELECT COUNT(*) FROM " .. TABLE .. where)) or 0
    sql.Query("DELETE FROM " .. TABLE .. where)
    return count
end

-- Records a finish and tells the player how it went
local function Finish(ply, board, label, seconds, difficulty)
    local best = HLRPG.RecordTime(ply, board, seconds, difficulty)
    local message = string.format("[TIME] %s: %s (%s)", label, HLRPG.FormatTime(seconds), HLRPG.GetDifficultyName(difficulty))
    if best then message = message .. string.format(" - personal best, #%d", GetRank(board, seconds)) end
    ply:ChatPrint(message)
end

-- Map clears

local mapStart

hook.Add("HLRPG_PlayerDataLoaded", "HLRPG_MapTimerStart", function()
    mapStart = mapStart or CurTime()
end)

hook.Add("PostCleanupMap", "HLRPG_MapTimerRestart", function()
    if mapStart then mapStart = CurTime() end
end)

-- Only moving forward to the next map of the campaign through its exit counts (not restarts, going back, or
-- votes skipping the map)
hook.Add("LambdaPreChangelevel", "HLRPG_MapCleared", function(nextMap, landmark, restart)
    if restart or not mapStart or not GAMEMODE.GetMapList then return end
    if HLRPG.IsSkipChange(nextMap, landmark) then return end

    local mapList = GAMEMODE:GetMapList() or {}
    local current = game.GetMap():lower()
    local isNext = false
    for i, map in ipairs(mapList) do
        if map == current then isNext = mapList[i + 1] == string.lower(nextMap or "") break end
    end
    if not isNext then return end

    local seconds = CurTime() - mapStart
    local _, difficulty = HLRPG.GetDifficulty()
    for _, ply in ipairs(player.GetAll()) do
        Finish(ply, HLRPG.GetMapBoard(current), current, seconds, difficulty)
    end
end)

hook.Add("HLRPG_RunFinished", "HLRPG_RunTime", function(ply, campaign, seconds, difficulty)
    Finish(ply, HLRPG.GetRunBoard(campaign.id), campaign.name .. " run", seconds, difficulty)
end)

-- The map's best times, in chat on loading in
hook.Add("HLRPG_PlayerDataLoaded", "HLRPG_MapTopTimes", function(ply)
    local map = game.GetMap():lower()
    local rows = HLRPG.GetLeaderboard(HLRPG.GetMapBoard(map), HLRPG.LeaderboardChatTop)
    if #rows == 0 then
        ply:ChatPrint("[TIME] No clear times for " .. map .. " yet.")
        return
    end

    local parts = {}
    for i, row in ipairs(rows) do
        parts[i] = string.format("%d. %s %s (%s)", i, row.name, HLRPG.FormatTime(row.seconds), HLRPG.GetDifficultyName(row.difficulty))
    end
    ply:ChatPrint("[TIME] Best on " .. map .. ": " .. table.concat(parts, "   "))
end)

-- TAB menu page: the run boards
HLRPG.AddMenuRequest("leaderboards", function(ply)
    local boards = {}
    for _, campaign in ipairs(HLRPG.Campaigns) do
        boards[campaign.id] = HLRPG.GetLeaderboard(HLRPG.GetRunBoard(campaign.id))
    end

    net.Start("HLRPG_OpenLeaderboards")
        net.WriteTable(boards)
    net.Send(ply)
end)
