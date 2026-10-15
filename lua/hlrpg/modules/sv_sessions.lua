-- hlrpg/modules/sv_sessions.lua
-- Session log, stored server-wide in sv.db: when each player joined and left, and every map they played on the
-- way, with how long they spent on it. Read it with rpg_sessions / rpg_playtime, or rpg_sessions_export for a CSV.
--
-- A map change reloads all Lua and players come back on the new map without disconnecting, so a session isn't
-- closed by the change: a player who loads in again within RESUME_WINDOW seconds of being last seen continues
-- their open session. Sessions whose player never comes back (or a crash) are closed at their last heartbeat.

local SESSIONS, MAPS = "hlrpg_sessions", "hlrpg_session_maps"
local RESUME_WINDOW = 300 -- seconds a session survives without its player (map changes take far less)
local HEARTBEAT = 60

sql.Query("CREATE TABLE IF NOT EXISTS " .. SESSIONS .. " (id INTEGER PRIMARY KEY AUTOINCREMENT, steamid TEXT, " ..
    "name TEXT, started INTEGER, last_seen INTEGER, ended INTEGER, reason TEXT)")
sql.Query("CREATE TABLE IF NOT EXISTS " .. MAPS .. " (session INTEGER, map TEXT, entered INTEGER, exited INTEGER)")
sql.Query("CREATE INDEX IF NOT EXISTS " .. SESSIONS .. "_steamid ON " .. SESSIONS .. " (steamid)")
sql.Query("CREATE INDEX IF NOT EXISTS " .. MAPS .. "_session ON " .. MAPS .. " (session)")

local function Q(s) return sql.SQLStr(s) end

-- Closes sessions nobody has been seen in for RESUME_WINDOW: they end at their last heartbeat
local function CloseStale()
    local cutoff = os.time() - RESUME_WINDOW
    sql.Query(string.format("UPDATE %s SET exited = (SELECT last_seen FROM %s WHERE id = session) WHERE exited IS NULL AND " ..
        "session IN (SELECT id FROM %s WHERE ended IS NULL AND last_seen < %d)", MAPS, SESSIONS, SESSIONS, cutoff))
    sql.Query(string.format("UPDATE %s SET ended = last_seen, reason = 'timeout' WHERE ended IS NULL AND last_seen < %d",
        SESSIONS, cutoff))
end

-- The player's open session from before a map change, or a new one; then a row for this map
local function StartTracking(ply)
    if ply:IsBot() then return end
    CloseStale()

    local now, steamID = os.time(), ply:SteamID()
    local id = tonumber(sql.QueryValue(string.format("SELECT id FROM %s WHERE steamid = %s AND ended IS NULL ORDER BY id DESC LIMIT 1",
        SESSIONS, Q(steamID))))
    if id then
        sql.Query(string.format("UPDATE %s SET last_seen = %d, name = %s WHERE id = %d", SESSIONS, now, Q(ply:Nick()), id))
        -- The previous map's row is closed already (map change); close it here too in case it wasn't
        sql.Query(string.format("UPDATE %s SET exited = %d WHERE session = %d AND exited IS NULL", MAPS, now, id))
    else
        sql.Query(string.format("INSERT INTO %s (steamid, name, started, last_seen) VALUES (%s, %s, %d, %d)",
            SESSIONS, Q(steamID), Q(ply:Nick()), now, now))
        id = tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
    end
    if not id then return end

    sql.Query(string.format("INSERT INTO %s (session, map, entered) VALUES (%d, %s, %d)", MAPS, id, Q(game.GetMap()), now))
    ply.HLRPG_SessionID = id
end

-- Marks the player as still here, and (when leaving this map) closes this map's row
local function Touch(ply, leavingMap)
    local id = ply.HLRPG_SessionID
    if not id then return end
    local now = os.time()
    sql.Query(string.format("UPDATE %s SET last_seen = %d WHERE id = %d", SESSIONS, now, id))
    if leavingMap then
        sql.Query(string.format("UPDATE %s SET exited = %d WHERE session = %d AND exited IS NULL", MAPS, now, id))
    end
end

hook.Add("PlayerInitialSpawn", "HLRPG_SessionStart", StartTracking)

hook.Add("PlayerDisconnected", "HLRPG_SessionEnd", function(ply)
    local id = ply.HLRPG_SessionID
    if not id then return end
    Touch(ply, true)
    sql.Query(string.format("UPDATE %s SET ended = %d, reason = 'left' WHERE id = %d", SESSIONS, os.time(), id))
    ply.HLRPG_SessionID = nil
end)

-- Map change or shutdown: the sessions stay open, waiting for their players to load in again
local function LeavingMap()
    for _, ply in ipairs(player.GetHumans()) do Touch(ply, true) end
end
hook.Add("LambdaPreChangelevel", "HLRPG_SessionMapChange", LeavingMap)
hook.Add("ShutDown", "HLRPG_SessionMapChange", LeavingMap)

timer.Create("HLRPG_SessionHeartbeat", HEARTBEAT, 0, function()
    sql.Begin()
    for _, ply in ipairs(player.GetHumans()) do Touch(ply, false) end
    sql.Commit()
    CloseStale()
end)

-- Hot reload: pick up players already on the server
for _, ply in ipairs(player.GetHumans()) do
    if not ply.HLRPG_SessionID then StartTracking(ply) end
end

-- Reading -------------------------------------------------------------------------------------------------------

-- "1h 05m", "12m", "40s"
function HLRPG.FormatDuration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    if seconds < 60 then return seconds .. "s" end
    local h, m = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60)
    return h > 0 and string.format("%dh %02dm", h, m) or (m .. "m")
end

-- Sessions newest first: { { id, steamid, name, started, ended, reason, seconds, maps = { { map, seconds }, ... } }, ... }
-- steamID nil = everyone. Open sessions run until now.
function HLRPG.GetSessions(steamID, limit)
    local where = steamID and (" WHERE steamid = " .. Q(steamID)) or ""
    local rows = sql.Query(string.format("SELECT * FROM %s%s ORDER BY id DESC LIMIT %d", SESSIONS, where, limit or 10)) or {}
    local now = os.time()
    for _, row in ipairs(rows) do
        row.started = tonumber(row.started)
        row.ended = tonumber(row.ended)
        row.seconds = (row.ended or now) - row.started
        row.maps = {}
        for _, m in ipairs(sql.Query(string.format("SELECT * FROM %s WHERE session = %s ORDER BY entered", MAPS, row.id)) or {}) do
            row.maps[#row.maps + 1] = { map = m.map, seconds = (tonumber(m.exited) or now) - tonumber(m.entered) }
        end
    end
    return rows
end

-- Total play time per player, most first: { { steamid, name, sessions, seconds, last }, ... }
function HLRPG.GetPlaytimes(limit)
    local now = os.time()
    local rows = sql.Query(string.format("SELECT steamid, MAX(name) AS name, COUNT(*) AS sessions, " ..
        "SUM(COALESCE(ended, %d) - started) AS seconds, MAX(started) AS last FROM %s GROUP BY steamid " ..
        "ORDER BY seconds DESC LIMIT %d", now, SESSIONS, limit or 15)) or {}
    for _, row in ipairs(rows) do
        row.sessions, row.seconds, row.last = tonumber(row.sessions), tonumber(row.seconds), tonumber(row.last)
    end
    return rows
end

-- Writes every session to data/hlrpg_sessions.csv (one line per map visited). Returns the line count.
function HLRPG.ExportSessions()
    local rows = sql.Query(string.format("SELECT s.id, s.steamid, s.name, s.started, s.ended, s.reason, m.map, m.entered, m.exited " ..
        "FROM %s s LEFT JOIN %s m ON m.session = s.id ORDER BY s.id, m.entered", SESSIONS, MAPS)) or {}
    local function Date(t) return t and t ~= "NULL" and os.date("%Y-%m-%d %H:%M:%S", tonumber(t)) or "" end
    local function Cell(v) return '"' .. string.gsub(tostring(v or ""), '"', '""') .. '"' end

    local lines = { "session,steamid,name,session_start,session_end,end_reason,map,map_enter,map_leave,map_seconds" }
    for _, r in ipairs(rows) do
        local seconds = (tonumber(r.exited) and tonumber(r.entered)) and (tonumber(r.exited) - tonumber(r.entered)) or ""
        lines[#lines + 1] = table.concat({ r.id, Cell(r.steamid), Cell(r.name), Date(r.started), Date(r.ended),
            (r.reason and r.reason ~= "NULL") and r.reason or "open", Cell(r.map), Date(r.entered), Date(r.exited), seconds }, ",")
    end
    file.Write("hlrpg_sessions.csv", table.concat(lines, "\n"))
    return #rows
end
