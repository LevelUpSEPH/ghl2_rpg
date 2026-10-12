-- hlrpg/ui/cl_achievement_menu.lua
-- Opened from the TAB menu or with !ach / !achievement. One tab per HLRPG.AchievementCategories entry.

local COL_BG = Color(18, 18, 18, 255)
local COL_HEADER = Color(28, 28, 28, 255)
local COL_ACCENT = Color(0, 160, 255)
local COL_XP = Color(120, 200, 80)
local COL_LOCKED = Color(70, 70, 70)
local TAB_H = 30

local menuFrame
local activeCategory = "hl2"

local function GetCategory(ach)
    return ach.category or "hl2"
end

-- Achievement IDs in a category, in display order
local function GetCategoryAchievements(categoryID)
    local ids = {}
    for id, ach in pairs(HLRPG.Achievements) do
        if GetCategory(ach) == categoryID then ids[#ids + 1] = id end
    end

    table.sort(ids, function(a, b)
        local achA, achB = HLRPG.Achievements[a], HLRPG.Achievements[b]
        return (achA.sort or achA.name) < (achB.sort or achB.name)
    end)
    return ids
end

local function CountUnlocked(ids, unlockedList)
    local count = 0
    for _, id in ipairs(ids) do
        if unlockedList[id] then count = count + 1 end
    end
    return count
end

local function AddAchievementRow(scroll, ach, isUnlocked, counters)
    local iconMat = Material(ach.icon or "vgui/achievements/default", "noclamp smooth")

    local item = scroll:Add("DPanel")
    item:Dock(TOP)
    item:SetTall(90)
    item:DockMargin(0, 0, 0, 8)

    item.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, isUnlocked and Color(35, 35, 35) or Color(22, 22, 22))

        if self:IsHovered() then
            surface.SetDrawColor(isUnlocked and COL_ACCENT or Color(60, 60, 60))
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        if not iconMat:IsError() then
            surface.SetMaterial(iconMat)
            surface.SetDrawColor(isUnlocked and color_white or Color(50, 50, 50, 150))
            surface.DrawTexturedRect(15, 15, 60, 60)
        end

        -- Progress achievements are always described, since the goal is the point
        local showDesc = isUnlocked or ach.counter
        draw.SimpleText(ach.name, "DermaDefaultBold", 90, 15, isUnlocked and color_white or Color(120, 120, 120))
        draw.SimpleText(showDesc and ach.desc or "Not unlocked yet...", "DermaDefault", 90, 35, isUnlocked and Color(160, 160, 160) or Color(90, 90, 90))

        if ach.counter then
            -- Collections are sets of found items; their value is how many were found
            local raw = counters[ach.counter]
            local value = math.min(istable(raw) and table.Count(raw) or (raw or 0), ach.goal)
            if isUnlocked then value = ach.goal end

            local barW = 220
            draw.RoundedBox(3, 90, 58, barW, 12, Color(10, 10, 10))
            draw.RoundedBox(3, 90, 58, barW * value / ach.goal, 12, isUnlocked and COL_ACCENT or Color(80, 110, 140))
            draw.SimpleText(string.Comma(value) .. " / " .. string.Comma(ach.goal), "DermaDefault", 90 + barW + 8, 64, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        -- What it's worth at the player's current level
        local xp = HLRPG.GetKillEquivalentXP(ach.kills or 0, LocalPlayer():GetNWInt("HLRPG_Level", 1))
        draw.SimpleText("+" .. string.Comma(xp) .. " XP", "DermaDefaultBold", w - 15, 15, isUnlocked and COL_XP or COL_LOCKED, TEXT_ALIGN_RIGHT)

        if ach.rewardItem then
            local rewardText = isUnlocked and ("REWARD: " .. HLRPG.GetItemName(ach.rewardItem)) or "REWARD: ???"
            draw.SimpleText(rewardText:upper(), "DermaDefault", w - 15, 35, isUnlocked and Color(255, 200, 50) or COL_LOCKED, TEXT_ALIGN_RIGHT)
        end

        draw.SimpleText(isUnlocked and "COMPLETED" or "LOCKED", "DermaDefaultBold", w - 15, h - 25, isUnlocked and COL_ACCENT or Color(60, 60, 60), TEXT_ALIGN_RIGHT)
    end
end

local function FillCategory(scroll, categoryID, unlockedList, counters)
    scroll:Clear()

    local ids = GetCategoryAchievements(categoryID)
    if #ids == 0 then
        local empty = scroll:Add("DLabel")
        empty:Dock(TOP)
        empty:SetTall(60)
        empty:SetContentAlignment(5)
        empty:SetTextColor(Color(120, 120, 120))
        empty:SetText("No achievements here yet.")
        return
    end

    for _, id in ipairs(ids) do
        AddAchievementRow(scroll, HLRPG.Achievements[id], unlockedList[id] == true, counters)
    end
end

local function CreateTabs(frame, scroll, unlockedList, counters)
    local categories = HLRPG.AchievementCategories
    local tabW = (frame:GetWide() - 20 - 6 * (#categories - 1)) / #categories

    for i, category in ipairs(categories) do
        local ids = GetCategoryAchievements(category.id)
        local label = string.format("%s  %d/%d", category.name, CountUnlocked(ids, unlockedList), #ids)

        local tab = vgui.Create("DButton", frame)
        tab:SetPos(10 + (i - 1) * (tabW + 6), 40)
        tab:SetSize(tabW, TAB_H)
        tab:SetText("")
        tab.Paint = function(s, w, h)
            local active = activeCategory == category.id
            draw.RoundedBox(4, 0, 0, w, h, active and Color(40, 40, 40) or (s:IsHovered() and Color(32, 32, 32) or Color(24, 24, 24)))
            if active then
                surface.SetDrawColor(COL_ACCENT)
                surface.DrawRect(0, h - 2, w, 2)
            end
            draw.SimpleText(label, "DermaDefaultBold", w / 2, h / 2, active and color_white or Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        tab.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            activeCategory = category.id
            FillCategory(scroll, category.id, unlockedList, counters)
        end
    end
end

function HLRPG.OpenAchievementMenu(unlockedList, counters)
    if IsValid(menuFrame) then menuFrame:Remove() end
    counters = counters or {}

    local frame = vgui.Create("DFrame")
    menuFrame = frame
    frame:SetSize(640, 720)
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)

    local unlockedCount = table.Count(unlockedList)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COL_BG)
        surface.SetDrawColor(COL_HEADER)
        surface.DrawRect(0, 0, w, 32)
        surface.SetDrawColor(COL_ACCENT)
        surface.DrawRect(0, 31, w, 1)
        draw.SimpleText("HL2:RPG ACHIEVEMENTS", "DermaDefaultBold", 12, 8, Color(200, 200, 200))
        draw.SimpleText(unlockedCount .. " / " .. table.Count(HLRPG.Achievements) .. " UNLOCKED", "DermaDefaultBold", w - 60, 8, COL_ACCENT, TEXT_ALIGN_RIGHT)
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

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 40 + TAB_H + 6, 10, 10)

    CreateTabs(frame, scroll, unlockedList, counters)
    FillCategory(scroll, activeCategory, unlockedList, counters)
end

net.Receive("HLRPG_OpenAchievementMenu", function()
    local unlockedList = net.ReadTable()
    local counters = net.ReadTable()
    HLRPG.OpenAchievementMenu(unlockedList, counters)
end)
