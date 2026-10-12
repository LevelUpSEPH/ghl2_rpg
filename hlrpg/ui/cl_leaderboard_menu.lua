-- hlrpg/ui/cl_leaderboard_menu.lua
-- Run time leaderboards, one tab per campaign. Opened from the TAB menu. (Map times are shown in chat.)

local COL_BG = Color(18, 18, 18, 255)
local COL_HEADER = Color(28, 28, 28, 255)
local COL_ACCENT = Color(255, 180, 0)
local MEDALS = { Color(255, 205, 60), Color(200, 200, 210), Color(205, 127, 50) }
local TAB_H = 30

local menuFrame
local activeCampaign = "hl2"

local function FillBoard(list, rows)
    list:Clear()

    if #rows == 0 then
        list:AddLine("", "No finished runs yet.", "", "", "")
        return
    end

    for rank, row in ipairs(rows) do
        local line = list:AddLine(rank, row.name, HLRPG.FormatTime(row.seconds), HLRPG.GetDifficultyName(row.difficulty), os.date("%d.%m.%Y", row.date))
        local color = MEDALS[rank] or (row.steamid == LocalPlayer():SteamID() and COL_ACCENT) or Color(200, 200, 200)
        for _, column in pairs(line.Columns) do column:SetTextColor(color) end
    end
end

local function CreateTabs(frame, list, boards)
    local campaigns = HLRPG.Campaigns
    local tabW = (frame:GetWide() - 20 - 6 * (#campaigns - 1)) / #campaigns

    for i, campaign in ipairs(campaigns) do
        local tab = vgui.Create("DButton", frame)
        tab:SetPos(10 + (i - 1) * (tabW + 6), 40)
        tab:SetSize(tabW, TAB_H)
        tab:SetText("")
        tab.Paint = function(s, w, h)
            local active = activeCampaign == campaign.id
            draw.RoundedBox(4, 0, 0, w, h, active and Color(40, 40, 40) or (s:IsHovered() and Color(32, 32, 32) or Color(24, 24, 24)))
            if active then
                surface.SetDrawColor(COL_ACCENT)
                surface.DrawRect(0, h - 2, w, 2)
            end
            draw.SimpleText(campaign.name, "DermaDefaultBold", w / 2, h / 2, active and color_white or Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        tab.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            activeCampaign = campaign.id
            FillBoard(list, boards[campaign.id] or {})
        end
    end
end

function HLRPG.OpenLeaderboardMenu(boards)
    if IsValid(menuFrame) then menuFrame:Remove() end

    local frame = vgui.Create("DFrame")
    menuFrame = frame
    frame:SetSize(560, 440)
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COL_BG)
        surface.SetDrawColor(COL_HEADER)
        surface.DrawRect(0, 0, w, 32)
        surface.SetDrawColor(COL_ACCENT)
        surface.DrawRect(0, 31, w, 1)
        draw.SimpleText("RUN LEADERBOARDS", "DermaDefaultBold", 12, 8, Color(200, 200, 200))
        draw.SimpleText("Best time per player, first map to credits", "DermaDefault", w - 55, 9, Color(120, 120, 120), TEXT_ALIGN_RIGHT)
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(45, 31)
    close:SetPos(frame:GetWide() - 45, 0)
    close:SetText("X")
    close:SetTextColor(color_white)
    close.Paint = function(self, w, h)
        if self:IsHovered() then draw.RoundedBox(0, 0, 0, w, h, Color(220, 50, 50)) end
    end
    close.DoClick = function() frame:Close() end

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:DockMargin(10, 40 + TAB_H + 6, 10, 10)
    list:SetMultiSelect(false)
    list:SetHeaderHeight(25)
    list:AddColumn("#"):SetFixedWidth(30)
    list:AddColumn("PLAYER")
    list:AddColumn("TIME"):SetFixedWidth(80)
    list:AddColumn("DIFFICULTY"):SetFixedWidth(90)
    list:AddColumn("DATE"):SetFixedWidth(80)
    list.Paint = function(self, w, h)
        surface.SetDrawColor(10, 10, 10, 255)
        surface.DrawRect(0, 0, w, h)
    end
    for _, column in pairs(list.Columns) do
        column.Header:SetTextColor(COL_ACCENT)
        column.Header.Paint = function(self, w, h)
            surface.SetDrawColor(35, 35, 35, 255)
            surface.DrawRect(0, 0, w, h)
        end
    end

    CreateTabs(frame, list, boards)
    FillBoard(list, boards[activeCampaign] or {})
end

net.Receive("HLRPG_OpenLeaderboards", function()
    HLRPG.OpenLeaderboardMenu(net.ReadTable())
end)
