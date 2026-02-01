-- addons/halflife_rpg/lua/hlrpg/ui/cl_achievement_menu.lua

local function OpenAchievementMenu(unlockedList)
    if IsValid(HLRPG_Menu) then HLRPG_Menu:Remove() end

    local frame = vgui.Create("DFrame")
    HLRPG_Menu = frame
    frame:SetSize(580, 700)
    frame:Center()
    frame:MakePopup()
    
    frame:SetTitle("") 
    frame:ShowCloseButton(false) 
    frame:SetDraggable(true)

    -- Renkler
    local colBG = Color(18, 18, 18, 255)
    local colHeader = Color(28, 28, 28, 255)
    local colAccent = Color(0, 160, 255)
    local colXP = Color(120, 200, 80) -- Yeşilimsi XP rengi

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colBG)
        surface.SetDrawColor(colHeader)
        surface.DrawRect(0, 0, w, 32)
        surface.SetDrawColor(colAccent)
        surface.DrawRect(0, 31, w, 1)
        draw.SimpleText("HL2:RPG ACHIEVEMENTS", "DermaDefaultBold", 12, 8, Color(200, 200, 200))
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

    if not HLRPG or not HLRPG.Achievements then return end

    for id, ach in pairs(HLRPG.Achievements) do
        local isUnlocked = unlockedList and unlockedList[id] == true
        local iconPath = ach.icon or "vgui/achievements/default"
        local iconMat = Material(iconPath, "noclamp smooth")

        local item = scroll:Add("DPanel")
        item:Dock(TOP)
        item:SetTall(90) -- Boyutu biraz artırdık (Ödüller için)
        item:DockMargin(0, 0, 0, 8)
        
        item.Paint = function(self, w, h)
            local isHovered = self:IsHovered()
            local bg = isUnlocked and Color(35, 35, 35) or Color(22, 22, 22)
            draw.RoundedBox(4, 0, 0, w, h, bg)

            if isHovered then
                surface.SetDrawColor(isUnlocked and colAccent or Color(60, 60, 60))
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            -- İkon
            if iconMat and not iconMat:IsError() then
                surface.SetMaterial(iconMat)
                surface.SetDrawColor(isUnlocked and color_white or Color(50, 50, 50, 150))
                surface.DrawTexturedRect(15, 15, 60, 60)
            end

            -- Başlık
            draw.SimpleText(ach.name, "DermaDefaultBold", 90, 15, isUnlocked and color_white or Color(80, 80, 80))
            
            -- Açıklama (Kilitliyse gizle/karart)
            local descStr = isUnlocked and ach.desc or "Not unlocked yet..."
            draw.SimpleText(descStr, "DermaDefault", 90, 35, isUnlocked and Color(160, 160, 160) or Color(50, 50, 50))

            -- XP ÖDÜLÜ (Sağ Taraf)
            local xpText = "+" .. (ach.xp or 0) .. " XP"
            draw.SimpleText(xpText, "DermaDefaultBold", w - 15, 15, isUnlocked and colXP or Color(70, 70, 70), TEXT_ALIGN_RIGHT)

            -- EŞYA ÖDÜLÜ (Varsa)
            if ach.rewardItem then
                local rewardText = isUnlocked and "REWARD: " .. ach.rewardItem or "REWARD: ???"
                draw.SimpleText(rewardText:upper(), "DermaDefault", w - 15, 35, isUnlocked and Color(255, 200, 50) or Color(70, 70, 70), TEXT_ALIGN_RIGHT)
            end

            -- Durum Etiketi (Kazanıldı/Kilitli)
            local statusStr = isUnlocked and "COMPLETED" or "LOCKED"
            local statusCol = isUnlocked and colAccent or Color(60, 60, 60)
            draw.SimpleText(statusStr, "DermaDefaultBold", w - 15, h - 25, statusCol, TEXT_ALIGN_RIGHT)
        end
    end
end

net.Receive("HLRPG_OpenAchievementMenu", function()
    local unlockedTable = net.ReadTable()
    OpenAchievementMenu(unlockedTable)
end)