-- hlrpg/ui/cl_achievement_menu.lua
-- Opened from the TAB menu or with !ach / !achievement.

local COL_BG = Color(18, 18, 18, 255)
local COL_HEADER = Color(28, 28, 28, 255)
local COL_ACCENT = Color(0, 160, 255)
local COL_XP = Color(120, 200, 80)
local COL_LOCKED = Color(70, 70, 70)

local menuFrame

local function AddAchievementRow(scroll, ach, isUnlocked)
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

        draw.SimpleText(ach.name, "DermaDefaultBold", 90, 15, isUnlocked and color_white or Color(80, 80, 80))
        draw.SimpleText(isUnlocked and ach.desc or "Not unlocked yet...", "DermaDefault", 90, 35, isUnlocked and Color(160, 160, 160) or Color(50, 50, 50))

        draw.SimpleText("+" .. (ach.xp or 0) .. " XP", "DermaDefaultBold", w - 15, 15, isUnlocked and COL_XP or COL_LOCKED, TEXT_ALIGN_RIGHT)

        if ach.rewardItem then
            local rewardText = isUnlocked and ("REWARD: " .. ach.rewardItem) or "REWARD: ???"
            draw.SimpleText(rewardText:upper(), "DermaDefault", w - 15, 35, isUnlocked and Color(255, 200, 50) or COL_LOCKED, TEXT_ALIGN_RIGHT)
        end

        draw.SimpleText(isUnlocked and "COMPLETED" or "LOCKED", "DermaDefaultBold", w - 15, h - 25, isUnlocked and COL_ACCENT or Color(60, 60, 60), TEXT_ALIGN_RIGHT)
    end
end

function HLRPG.OpenAchievementMenu(unlockedList)
    if IsValid(menuFrame) then menuFrame:Remove() end

    local frame = vgui.Create("DFrame")
    menuFrame = frame
    frame:SetSize(580, 700)
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
    scroll:DockMargin(10, 40, 10, 10)

    -- Unlocked first, then alphabetical
    local ids = table.GetKeys(HLRPG.Achievements)
    table.sort(ids, function(a, b)
        local aUnlocked, bUnlocked = unlockedList[a] == true, unlockedList[b] == true
        if aUnlocked ~= bUnlocked then return aUnlocked end
        return HLRPG.Achievements[a].name < HLRPG.Achievements[b].name
    end)

    for _, id in ipairs(ids) do
        AddAchievementRow(scroll, HLRPG.Achievements[id], unlockedList[id] == true)
    end
end

net.Receive("HLRPG_OpenAchievementMenu", function()
    HLRPG.OpenAchievementMenu(net.ReadTable())
end)
