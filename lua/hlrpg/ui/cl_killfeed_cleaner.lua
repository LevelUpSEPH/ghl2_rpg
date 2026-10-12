-- hlrpg/ui/cl_killfeed_cleaner.lua
-- Hides the top-right kill feed.

hook.Add("DrawDeathNotice", "HLRPG_HideKillFeed", function()
    return false
end)
