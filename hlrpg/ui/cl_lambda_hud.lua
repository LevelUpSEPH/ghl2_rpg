-- hlrpg/ui/cl_lambda_hud.lua
-- "Lambda found" popup on the left side of the screen.
local lambda_draw_queue = {}
local L_PANEL_W, L_PANEL_H = 280, 50
local L_DISPLAY_TIME = 6

net.Receive("HLRPG_LambdaNotify", function()
    local data = {
        id = net.ReadString(),
        xp = net.ReadInt(32),
        time = CurTime(),
        alpha = 0
    }
    table.insert(lambda_draw_queue, data)
    surface.PlaySound("hl1/fvox/blip.wav")
end)

hook.Add("HUDPaint", "HLRPG_LambdaUniqueHUD", function()
    if #lambda_draw_queue == 0 then return end

    local cur = lambda_draw_queue[1]
    local elapsed = CurTime() - cur.time
    
    if elapsed < 0.5 then
        cur.alpha = math.Approach(cur.alpha, 255, FrameTime() * 500)
    elseif elapsed > L_DISPLAY_TIME - 0.5 then
        cur.alpha = math.Approach(cur.alpha, 0, FrameTime() * 500)
    end

    local x, y = 30, 150
    
    surface.SetDrawColor(0, 0, 0, math.min(cur.alpha, 180))
    surface.DrawRect(x, y, L_PANEL_W, L_PANEL_H)
    
    surface.SetDrawColor(255, 150, 0, cur.alpha)
    surface.DrawRect(x, y, 4, L_PANEL_H)

    draw.SimpleText("λ", "DermaLarge", x + 15, y + L_PANEL_H/2, Color(255, 150, 0, cur.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    draw.SimpleText("LAMBDA FOUND", "DermaDefaultBold", x + 50, y + 15, Color(255, 150, 0, cur.alpha))
    draw.SimpleText("Acquired: " .. cur.id .. (cur.xp > 0 and ("   +" .. string.Comma(cur.xp) .. " XP") or ""), "DermaDefault", x + 50, y + 30, Color(200, 200, 200, cur.alpha))

    if elapsed > L_DISPLAY_TIME then
        table.remove(lambda_draw_queue, 1)
    end
end)
