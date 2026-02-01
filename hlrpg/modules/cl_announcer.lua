-- hlrpg/modules/cl_announcer.lua

net.Receive("HLRPG_AchievementAnnounce", function()
    local ply = net.ReadEntity()
    local achName = net.ReadString()

    if not IsValid(ply) then return end

    chat.AddText(
        Color(0, 160, 255), "[HL2:RPG] ", 
        Color(255, 255, 255), ply:Nick(), 
        Color(200, 200, 200), " bir başarım kazandı: ", 
        Color(120, 200, 80), achName, "!"
    )
end)