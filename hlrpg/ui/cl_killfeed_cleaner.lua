-- addons/halflife_rpg/lua/hlrpg/modules/cl_killfeed_cleaner.lua
if not CLIENT then return end

-- Sağ üstteki ölüm bildirimlerini tamamen engelle
hook.Add("DrawDeathNotice", "HLRPG_HideKillFeed", function()
    return false
end)