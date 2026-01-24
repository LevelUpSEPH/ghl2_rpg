-- lua/hlrpg/core/sv_database.lua

if not SERVER then return end

HLRPG.DB = HLRPG.DB or {}

function HLRPG.DB.Initialize()
    local query = [[
        CREATE TABLE IF NOT EXISTS hlrpg_players (
            steamid TEXT PRIMARY KEY,
            xp INTEGER DEFAULT 0,
            level INTEGER DEFAULT 1,
            money INTEGER DEFAULT 0,
            inventory TEXT,
            equipment TEXT,
            pet_data TEXT
        );
    ]]

    local result = sql.Query(query)

    if result == false then
        print("[HLRPG] [ERROR] SQL Hatasi: " .. sql.LastError())
    else
        print("[HLRPG] [SQL] Veritabani tablosu (hlrpg_players) hazir.")
    end
end

HLRPG.DB.Initialize()