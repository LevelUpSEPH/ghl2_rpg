-- hlrpg/ui/cl_scoreboard.lua
-- TAB menu: player list with progression, plus a navigation bar to every HLRPG page.

local ACCENT = Color(255, 180, 0)
local HEADER_TEXT = Color(150, 150, 150)

-- Navigation: equal-sized tiles, NAV_PER_ROW per row; a shorter last row is centered.
-- Each page closes the scoreboard and opens on its own, so it stays open after TAB is released.
local NAV_PAGES = {
    { label = "SHOP",         icon = "icon16/cart.png",              open = function() HLRPG.OpenPlayerHub() end },
    { label = "CHARACTER",    icon = "icon16/user_suit.png",         open = function() HLRPG.OpenModelMenu() end },
    { label = "ACHIEVEMENTS", icon = "icon16/award_star_gold_1.png", open = function() HLRPG.RequestMenu("achievements") end },
    { label = "LAMBDAS",      icon = "icon16/map.png",               open = function() HLRPG.RequestMenu("lambdas") end },
    { label = "VOTE",         icon = "icon16/thumb_up.png",          open = function() HLRPG.OpenVoteMenu() end },
    { label = "VEHICLE",      icon = "icon16/car.png",               open = function() HLRPG.RequestMenu("vehicle") end },
    { label = "DIFFICULTY",   icon = "icon16/chart_bar.png",         open = function() HLRPG.OpenDifficultyMenu() end },
}

-- Layout
local NAV_PER_ROW, NAV_TILE_H, NAV_GAP = 4, 50, 6
local NAV_ROWS = math.ceil(#NAV_PAGES / NAV_PER_ROW)
local NAV_Y = 82
local NAV_BOTTOM = NAV_Y + NAV_ROWS * NAV_TILE_H + (NAV_ROWS - 1) * NAV_GAP
local HEADER_Y = NAV_BOTTOM + 16
local LINE_Y = HEADER_Y + 18
local LIST_Y = LINE_Y + 8
local BOARD_W = 950
local BOARD_H = LIST_Y + 500

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

local function CreateNavTile(board, page)
    local btn = vgui.Create("DButton", board)
    btn:SetText("")
    local icon = Material(page.icon)

    btn.Paint = function(s, w, h)
        local hovered = s:IsHovered()

        draw.RoundedBox(4, 0, 0, w, h, hovered and Color(255, 150, 0, 35) or Color(45, 45, 45, 255))
        surface.SetDrawColor(hovered and ACCENT or Color(70, 70, 70, 255))
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(icon)
        surface.DrawTexturedRect(w / 2 - 8, 9, 16, 16)

        draw.SimpleText(page.label, "DermaDefaultBold", w / 2, h - 14, hovered and ACCENT or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        board:Hide()
        page.open()
    end

    return btn
end

local function CreateNavBar(board)
    local tileW = (BOARD_W - 40 - NAV_GAP * (NAV_PER_ROW - 1)) / NAV_PER_ROW

    for i, page in ipairs(NAV_PAGES) do
        local row = math.floor((i - 1) / NAV_PER_ROW)
        local col = (i - 1) % NAV_PER_ROW

        -- Center the row: full rows span the width, a shorter last row is offset by its missing tiles
        local tilesInRow = math.min(NAV_PER_ROW, #NAV_PAGES - row * NAV_PER_ROW)
        local rowW = tilesInRow * tileW + (tilesInRow - 1) * NAV_GAP
        local rowX = (BOARD_W - rowW) / 2

        local tile = CreateNavTile(board, page)
        tile:SetPos(rowX + col * (tileW + NAV_GAP), NAV_Y + row * (NAV_TILE_H + NAV_GAP))
        tile:SetSize(tileW, NAV_TILE_H)
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

        draw.SimpleText("PLAYER", "DermaDefaultBold", 20 + COL.name, HEADER_Y, HEADER_TEXT)
        draw.SimpleText("LEVEL", "DermaDefaultBold", 20 + COL.level, HEADER_Y, HEADER_TEXT)
        draw.SimpleText("XP (WALLET / GOAL)", "DermaDefaultBold", 20 + COL.xp, HEADER_Y, HEADER_TEXT)
        draw.SimpleText("ACHIEVEMENTS", "DermaDefaultBold", 20 + COL.ach, HEADER_Y, Color(102, 192, 244))
        draw.SimpleText("λ CACHES", "DermaDefaultBold", 20 + COL.lambda, HEADER_Y, Color(255, 160, 0))
        draw.SimpleText("TP", "DermaDefaultBold", 20 + COL.tp, HEADER_Y, Color(0, 255, 255))
        draw.SimpleText("PING", "DermaDefaultBold", 20 + COL.ping, HEADER_Y, HEADER_TEXT)

        surface.SetDrawColor(100, 100, 100, 100)
        surface.DrawLine(20, LINE_Y, w - 20, LINE_Y)

        draw.SimpleText("F1: Character   |   Number keys: vote on a running poll   |   Chat: !ach  !lambda  !petsummon", "DermaDefault", w / 2, h - 16, Color(120, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    CreateNavBar(BoardPanel)

    local Scroll = vgui.Create("DScrollPanel", BoardPanel)
    Scroll:SetPos(20, LIST_Y)
    Scroll:SetSize(BOARD_W - 40, BOARD_H - LIST_Y - 35)

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
