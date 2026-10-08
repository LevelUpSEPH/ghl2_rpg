-- hlrpg/ui/cl_achievement_hud.lua
-- Steam-style "achievement unlocked" popup in the bottom-right corner, one at a time.

local PANEL_W, PANEL_H = 340, 85
local DISPLAY_TIME = 5

local queue = {}

net.Receive("HLRPG_AchievementNotify", function()
    table.insert(queue, {
        id = net.ReadString(),
        name = net.ReadString(),
        desc = net.ReadString(),
        xp = net.ReadInt(32),
        item = net.ReadString(),
        icon = net.ReadString(),
        start_time = CurTime()
    })
end)

hook.Add("HUDPaint", "HLRPG_SteamAchievementHUD", function()
    local cur = queue[1]
    if not cur then return end

    local elapsed = CurTime() - cur.start_time
    local x, y = ScrW() - PANEL_W - 25, ScrH() - PANEL_H - 40

    draw.RoundedBox(4, x, y, PANEL_W, PANEL_H, Color(20, 20, 20, 250))

    if cur.icon ~= "" then
        local iconMat = Material(cur.icon, "noclamp smooth")
        if not iconMat:IsError() then
            surface.SetDrawColor(255, 255, 255)
            surface.SetMaterial(iconMat)
            surface.DrawTexturedRect(x + 12, y + 12, 60, 60)
        end
    end

    local tx = x + 85
    draw.SimpleText("NEW ACHIEVEMENT", "DermaDefault", tx, y + 12, Color(235, 182, 38))
    draw.SimpleText(cur.name, "DermaDefaultBold", tx, y + 28, Color(255, 255, 255))

    local reward = "+" .. cur.xp .. " XP"
    if cur.item ~= "" then reward = reward .. " | 🎁 " .. cur.item end
    draw.SimpleText(reward, "DermaDefaultBold", tx, y + 46, Color(120, 200, 80))
    draw.SimpleText(cur.desc, "DermaDefault", tx, y + 62, Color(150, 150, 150))

    surface.SetDrawColor(102, 192, 244)
    surface.DrawRect(x, y + PANEL_H - 3, PANEL_W * (1 - elapsed / DISPLAY_TIME), 3)

    if elapsed > DISPLAY_TIME then table.remove(queue, 1) end
end)
