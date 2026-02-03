HLRPG = HLRPG or {}
HLRPG.SafeMaps = {
    "d1_trainstation_01",
    "d1_trainstation_02",
    "d1_trainstation_03",
    "d1_trainstation_04",
    "d1_trainstation_05",
    "d1_trainstation_06",
}

function IsSafeMap()
    local currentMap = game.GetMap()
    for _, safeMap in ipairs(HLRPG.SafeMaps) do
        if currentMap == safeMap then
            return true
        end
    end
    return false
end