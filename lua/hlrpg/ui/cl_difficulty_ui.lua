-- hlrpg/ui/cl_difficulty_ui.lua
-- World difficulty page. Everyone can see the tiers; only admins can switch them.
-- Opened from the TAB menu or with !diff.

local menuFrame

local function AddTierButton(list, index, data, isAdmin)
    local btn = list:Add("DButton")
    btn:SetText("")
    btn:Dock(TOP)
    btn:DockMargin(10, 10, 10, 0)
    btn:SetTall(46)
    btn:SetEnabled(isAdmin)
    btn:SetCursor(isAdmin and "hand" or "arrow")

    btn.Paint = function(s, w, h)
        local isCurrent = select(2, HLRPG.GetDifficulty()) == index
        local hovered = isAdmin and s:IsHovered()

        local bg = (isCurrent or hovered) and Color(data.color.r, data.color.g, data.color.b, isCurrent and 120 or 200) or Color(50, 50, 50, 200)
        draw.RoundedBox(4, 0, 0, w, h, bg)
        surface.SetDrawColor(data.color)
        surface.DrawOutlinedRect(0, 0, w, h, isCurrent and 2 or 1)

        draw.SimpleText(data.name:upper(), "HLRPG_HUD_Bold", 12, 8, color_white)
        draw.SimpleText("Enemies spawn at level " .. data.minLvl .. " - " .. data.maxLvl, "DermaDefault", 12, 26, Color(220, 220, 220))

        if isCurrent then
            draw.SimpleText("CURRENT", "DermaDefaultBold", w - 12, h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    btn.DoClick = function()
        net.Start("HLRPG_SetDifficulty")
            net.WriteUInt(index, 8)
        net.SendToServer()
        surface.PlaySound("ui/buttonclick.wav")
    end
end

function HLRPG.OpenDifficultyMenu()
    if IsValid(menuFrame) then menuFrame:Remove() end

    local isAdmin = LocalPlayer():IsAdmin()

    local frame = vgui.Create("DFrame")
    menuFrame = frame
    frame:SetSize(340, 400)
    frame:SetTitle("WORLD DIFFICULTY")
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 240))
        draw.RoundedBox(0, 0, 0, w, 25, Color(0, 150, 255, 150))
    end

    local footer = vgui.Create("DLabel", frame)
    footer:Dock(BOTTOM)
    footer:SetTall(40)
    footer:SetWrap(true)
    footer:SetContentAlignment(5)
    footer:SetTextColor(Color(180, 180, 180))
    footer:SetText(isAdmin
        and "Undamaged enemies are re-leveled right away.\nNew spawns use the new range."
        or "Only admins can change the world difficulty.")

    local list = vgui.Create("DScrollPanel", frame)
    list:Dock(FILL)

    for i, data in ipairs(HLRPG.DifficultyScales) do
        AddTierButton(list, i, data, isAdmin)
    end
end

hook.Add("OnPlayerChat", "HLRPG_OpenDiffMenu", function(ply, text)
    if ply == LocalPlayer() and text == "!diff" then
        HLRPG.OpenDifficultyMenu()
        return true
    end
end)
