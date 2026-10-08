-- hlrpg/ui/cl_chat_notify.lua
-- Colored chat messages for XP gains and other players' achievements.

net.Receive("HLRPG_XPNotify", function()
    local xp = net.ReadInt(32)
    local perc = net.ReadInt(16)
    local name = net.ReadString()
    local npcCol = net.ReadColor()

    chat.AddText(
        Color(255, 255, 255), "You got ",
        Color(50, 255, 50), xp .. " xp ",
        Color(255, 255, 255), "for dealing ",
        Color(255, 200, 0), perc .. "% ",
        Color(255, 255, 255), "of the damage to ",
        npcCol, name
    )
end)

net.Receive("HLRPG_AchievementAnnounce", function()
    local ply = net.ReadEntity()
    local achName = net.ReadString()
    if not IsValid(ply) then return end

    chat.AddText(
        Color(0, 160, 255), "[HL2:RPG] ",
        Color(255, 255, 255), ply:Nick(),
        Color(200, 200, 200), " earned an achievement: ",
        Color(120, 200, 80), achName, "!"
    )
end)
