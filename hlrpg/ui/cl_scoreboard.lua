-- hlrpg/ui/cl_scoreboard.lua
-- TAB menu: player list with progression, plus a navigation bar to every HLRPG page.

local BOARD_W, BOARD_H = 950, 650
local ACCENT = Color(255, 180, 0)
local HEADER_TEXT = Color(150, 150, 150)

-- Each page closes the scoreboard and opens on its own, so it stays open after TAB is released
local NAV_PAGES = {
    { label = "SHOP & INVENTORY", icon = "icon16/cart.png",       open = function() HLRPG.OpenPlayerHub() end },
    { label = "ACHIEVEMENTS",     icon = "icon16/award_star_gold_1.png", open = function() HLRPG.RequestMenu("achievements") end },
    { label = "LAMBDA CACHES",    icon = "icon16/map.png",        open = function() HLRPG.RequestMenu("lambdas") end },
    { label = "DIFFICULTY",       icon = "icon16/chart_bar.png",  open = function() HLRPG.OpenDifficultyMenu() end },
    { label = "CHARACTER",        icon = "icon16/user_suit.png",  open = function() HLRPG.OpenModelMenu() end },
}

-- Column x positions, shared by the headers and the rows
local COL = { name = 60, level = 330, xp = 410, ach = 640, lambda = 745, tp = 815, ping = 885 }

local BoardPanel = nil

local function AddLabel(parent, text, x, y, font, color)
    local label = vgui.Create("DLabel", parent)
    label:SetPos(x, y)
    label:SetText(tostring(text))
    if font then label:SetFont(font) end
    if color then label:SetColor(color) end
    label:SizeToContents()
    return label
end

local function CreateNavBar(parent)
    local bar = vgui.Create("DPanel", parent)
    bar:SetPos(20, 78)
    bar:SetSize(BOARD_W - 40, 34)
    bar.Paint = nil

    local spacing = 8
    local btnW = (bar:GetWide() - spacing * (#NAV_PAGES - 1)) / #NAV_PAGES

    for i, page in ipairs(NAV_PAGES) do
        local btn = vgui.Create("DButton", bar)
        btn:SetPos((i - 1) * (btnW + spacing), 0)
        btn:SetSize(btnW, 34)
        btn:SetText("")
        local icon = Material(page.icon)

        btn.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(255, 150, 0) or Color(55, 55, 55, 255))

            surface.SetDrawColor(255, 255, 255)
            surface.SetMaterial(icon)
            surface.DrawTexturedRect(10, h / 2 - 8, 16, 16)

            draw.SimpleText(page.label, "DermaDefaultBold", w / 2 + 8, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            parent:Hide()
            page.open()
        end
    end
end

local function AddPlayerRow(scroll, ply)
    local isLocal = ply == LocalPlayer()

    local Row = scroll:Add("DPanel")
    Row:Dock(TOP)
    Row:DockMargin(0, 0, 0, 5)
    Row:SetHeight(50)
    Row.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, isLocal and Color(75, 65, 45, 220) or Color(60, 60, 60, 200))
        if isLocal then
            surface.SetDrawColor(ACCENT)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
    end

    local Avatar = vgui.Create("AvatarImage", Row)
    Avatar:SetPos(5, 5)
    Avatar:SetSize(40, 40)
    Avatar:SetPlayer(ply, 64)

    AddLabel(Row, ply:Nick(), COL.name, 17, "DermaDefaultBold")

    local level = ply:GetNWInt("HLRPG_Level", 1)
    AddLabel(Row, "Lv. " .. level, COL.level, 12, "DermaLarge", ACCENT)

    local xp = ply:GetNWInt("HLRPG_XP", 0)
    local reqXP = HLRPG.GetRequiredXP(level)
    local xpPercent = math.Clamp(xp / reqXP, 0, 1)

    local BarBG = vgui.Create("DPanel", Row)
    BarBG:SetPos(COL.xp, 15)
    BarBG:SetSize(200, 20)
    BarBG.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 150))
        draw.RoundedBox(4, 0, 0, w * xpPercent, h, Color(0, 200, 0, 200))
        draw.SimpleText(string.Comma(xp) .. " / " .. string.Comma(reqXP), "DermaDefault", w / 2, h / 2, Color(255, 255, 255), 1, 1)
    end

    local achText = ply:GetNWInt("HLRPG_AchievementCount", 0) .. " / " .. table.Count(HLRPG.Achievements)
    AddLabel(Row, achText, COL.ach, 17, "DermaDefaultBold", Color(102, 192, 244))

    local lambdaText = ply:GetNWInt("HLRPG_LambdaCount", 0) .. " / " .. table.Count(HLRPG.LambdaMap)
    AddLabel(Row, lambdaText, COL.lambda, 17, "DermaDefaultBold", Color(255, 160, 0))

    AddLabel(Row, ply:GetNWInt("HLRPG_TempPoints", 0), COL.tp, 17, "DermaDefaultBold", Color(0, 255, 255))
    AddLabel(Row, ply:Ping(), COL.ping, 17)
end

local function CreateScoreboard()
    if IsValid(BoardPanel) then BoardPanel:Remove() end

    BoardPanel = vgui.Create("DPanel")
    BoardPanel:SetSize(BOARD_W, BOARD_H)
    BoardPanel:Center()

    BoardPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 20, 240))
        draw.RoundedBoxEx(8, 0, 0, w, 70, Color(40, 40, 40, 255), true, true, false, false)

        draw.SimpleText("HALF-LIFE 2: RPG CAMPAIGN", "DermaLarge", 20, 12, ACCENT)

        local diffData = HLRPG.GetDifficulty()
        draw.SimpleText("Difficulty: " .. diffData.name .. "  (enemies Lv. " .. diffData.minLvl .. "-" .. diffData.maxLvl .. ")",
            "DermaDefaultBold", 22, 46, diffData.color)

        draw.SimpleText(game.GetMap(), "DermaDefaultBold", w - 20, 18, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
        draw.SimpleText(player.GetCount() .. " / " .. game.MaxPlayers() .. " players", "DermaDefault", w - 20, 40, Color(160, 160, 160), TEXT_ALIGN_RIGHT)

        local headerY = 124
        draw.SimpleText("PLAYER", "DermaDefaultBold", 20 + COL.name, headerY, HEADER_TEXT)
        draw.SimpleText("LEVEL", "DermaDefaultBold", 20 + COL.level, headerY, HEADER_TEXT)
        draw.SimpleText("XP (WALLET / GOAL)", "DermaDefaultBold", 20 + COL.xp, headerY, HEADER_TEXT)
        draw.SimpleText("ACHIEVEMENTS", "DermaDefaultBold", 20 + COL.ach, headerY, Color(102, 192, 244))
        draw.SimpleText("λ CACHES", "DermaDefaultBold", 20 + COL.lambda, headerY, Color(255, 160, 0))
        draw.SimpleText("TP", "DermaDefaultBold", 20 + COL.tp, headerY, Color(0, 255, 255))
        draw.SimpleText("PING", "DermaDefaultBold", 20 + COL.ping, headerY, HEADER_TEXT)

        surface.SetDrawColor(100, 100, 100, 100)
        surface.DrawLine(20, 142, w - 20, 142)

        draw.SimpleText("F1: Character   |   Chat: !ach  !lambda  !diff  !petsummon", "DermaDefault", w / 2, h - 16, Color(120, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    CreateNavBar(BoardPanel)

    local Scroll = vgui.Create("DScrollPanel", BoardPanel)
    Scroll:SetPos(20, 150)
    Scroll:SetSize(BOARD_W - 40, BOARD_H - 185)

    local players = player.GetAll()
    table.sort(players, function(a, b)
        return a:GetNWInt("HLRPG_Level", 1) > b:GetNWInt("HLRPG_Level", 1)
    end)

    for _, ply in ipairs(players) do
        AddPlayerRow(Scroll, ply)
    end
end

hook.Add("ScoreboardShow", "HLRPG_Scoreboard_Open", function()
    CreateScoreboard()
    BoardPanel:Show()
    BoardPanel:MakePopup()
    BoardPanel:SetKeyboardInputEnabled(false)
    return true
end)

hook.Add("ScoreboardHide", "HLRPG_Scoreboard_Close", function()
    if IsValid(BoardPanel) then BoardPanel:Hide() end
end)
