-- addons/halflife_rpg/lua/hlrpg/modules/cl_difficulty_ui.lua
if not CLIENT then return end

local function OpenDifficultyMenu()
    if not LocalPlayer():IsAdmin() then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 400)
    frame:SetTitle("WORLD DIFFICULTY CONTROL")
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 240))
        draw.RoundedBox(0, 0, 0, w, 25, Color(0, 150, 255, 150))
    end

    local list = vgui.Create("DScrollPanel", frame)
    list:Dock(FILL)

    for i, data in ipairs(HLRPG_DifficultyScales or {}) do
        local btn = list:Add("DButton")
        btn:SetText(data.name:upper())
        btn:SetFont("HLRPG_HUD_Bold")
        btn:SetTextColor(Color(255, 255, 255))
        btn:Dock(TOP)
        btn:DockMargin(10, 10, 10, 0)
        btn:SetHeight(40)
        
        btn.Paint = function(s, w, h)
            local col = s:IsHovered() and Color(data.color.r, data.color.g, data.color.b, 200) or Color(50, 50, 50, 200)
            draw.RoundedBox(4, 0, 0, w, h, col)
            surface.SetDrawColor(data.color)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        btn.DoClick = function()
            RunConsoleCommand("say", "!setdiff " .. i)
            frame:Close()
        end
    end
    
    local label = list:Add("DLabel")
    label:SetText("Warning: Changes take effect on next spawn\nor update global NPCs.")
    label:SetWrap(true)
    label:Dock(BOTTOM)
    label:SetContentAlignment(5)
    label:SetTall(40)
end

-- Komutla açma
hook.Add("OnPlayerChat", "HLRPG_OpenDiffMenu", function(ply, text)
    if ply == LocalPlayer() and text == "!diff" then
        OpenDifficultyMenu()
        return true
    end
end)