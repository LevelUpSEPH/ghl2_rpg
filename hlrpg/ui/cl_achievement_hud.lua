-- cl_achievement_hud.lua
local achievement_queue = {}
local PANEL_W, PANEL_H = 340, 85
local DISPLAY_TIME = 5

net.Receive("HLRPG_AchievementNotify", function()
    local data = {
        id = net.ReadString(),
        name = net.ReadString(),
        desc = net.ReadString(),
        xp = net.ReadInt(32),
        item = net.ReadString(),
        icon = net.ReadString(),
        start_time = CurTime()
    }

    table.insert(achievement_queue, data)
end)

hook.Add("HUDPaint", "HLRPG_SteamAchievementHUD", function()
    if #achievement_queue == 0 then return end
    local cur = achievement_queue[1]
    local elapsed = CurTime() - cur.start_time

    -- Ekranın sağ alt köşesi
    local x, y = ScrW() - PANEL_W - 25, ScrH() - PANEL_H - 40
    
    -- Panel Arkaplanı
    draw.RoundedBox(4, x, y, PANEL_W, PANEL_H, Color(20, 20, 20, 250))
    
    -- İkon
    surface.SetDrawColor(255, 255, 255)
    local iconMat = Material(cur.icon, "noclamp smooth")
    surface.SetMaterial(iconMat)
    surface.DrawTexturedRect(x + 12, y + 12, 60, 60)

    -- Metinler
    local tx = x + 85
    draw.SimpleText("NEW ACHIEVEMENT", "DermaDefault", tx, y + 12, Color(235, 182, 38))
    draw.SimpleText(cur.name, "DermaDefaultBold", tx, y + 28, Color(255, 255, 255))
    
    local reward = "+" .. cur.xp .. " XP"
    if cur.item ~= "" then reward = reward .. " | 🎁 " .. cur.item end
    draw.SimpleText(reward, "DermaDefaultBold", tx, y + 46, Color(120, 200, 80))
    draw.SimpleText(cur.desc, "DermaDefault", tx, y + 62, Color(150, 150, 150))

    -- Mavi Alt Çizgi (Steam Mavisi)
    surface.SetDrawColor(102, 192, 244)
    surface.DrawRect(x, y + PANEL_H - 3, PANEL_W * (1 - elapsed/DISPLAY_TIME), 3)

    if elapsed > DISPLAY_TIME then table.remove(achievement_queue, 1) end
end)