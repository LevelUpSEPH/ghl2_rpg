-- hlrpg/core/sh_leaderboards.lua
-- Time leaderboards (sv_leaderboards.lua): one board per campaign run and one per map. Each player keeps
-- only their best time on a board; the difficulty it was set on is shown next to it.

HLRPG.LeaderboardSize = 10 -- rows sent to the TAB menu page
HLRPG.LeaderboardChatTop = 3 -- times printed in chat when a map loads

function HLRPG.GetRunBoard(campaignID) return "run_" .. campaignID end
function HLRPG.GetMapBoard(map) return "map_" .. string.lower(map) end

-- 754.2 -> "12:34", 4000 -> "1:06:40"
function HLRPG.FormatTime(seconds)
    seconds = math.floor(seconds or 0)
    local h, m, s = math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

function HLRPG.GetDifficultyName(difficulty)
    local scale = HLRPG.DifficultyScales[difficulty or 0]
    return scale and scale.name or "?"
end
