-- addons/halflife_rpg/lua/hlrpg/ui/cl_scoreboard.lua
if not CLIENT then return end

local BoardPanel = nil

local function CreateScoreboard()
    if IsValid(BoardPanel) then BoardPanel:Remove() end

    BoardPanel = vgui.Create("DPanel")
    BoardPanel:SetSize(950, 650)
    BoardPanel:Center()
    
    BoardPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 20, 240))
        draw.RoundedBoxEx(8, 0, 0, w, 80, Color(40, 40, 40, 255), true, true, false, false)
        
        draw.SimpleText("HALF-LIFE 2: RPG CAMPAIGN", "DermaLarge", 20, 20, Color(255, 180, 0), TEXT_ALIGN_LEFT)
        
        -- Dünya Zorluk Durumu
        local diffLevel = GetGlobalInt("HLRPG_CurrentDifficulty", 1)
        local diffName = (HLRPG_DifficultyScales and HLRPG_DifficultyScales[diffLevel]) and HLRPG_DifficultyScales[diffLevel].name or "NORMAL"
        draw.SimpleText("Zorluk: " .. diffName, "DermaDefault", 22, 50, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        
        -- Sütun Başlıkları
        draw.SimpleText("OYUNCU", "DermaDefaultBold", 80, 90, Color(150, 150, 150))
        draw.SimpleText("SEVİYE", "DermaDefaultBold", 350, 90, Color(150, 150, 150))
        draw.SimpleText("XP (WALLET / GOAL)", "DermaDefaultBold", 450, 90, Color(150, 150, 150))
        draw.SimpleText("TEMP POINTS", "DermaDefaultBold", 680, 90, Color(0, 255, 255))
        draw.SimpleText("PING", "DermaDefaultBold", 880, 90, Color(150, 150, 150))
        
        surface.SetDrawColor(100, 100, 100, 100)
        surface.DrawLine(20, 110, w-20, 110)
    end

    local Scroll = vgui.Create("DScrollPanel", BoardPanel)
    Scroll:SetPos(20, 120)
    Scroll:SetSize(910, 510)

    for _, ply in ipairs(player.GetAll()) do
        local Row = Scroll:Add("DPanel")
        Row:Dock(TOP)
        Row:DockMargin(0, 0, 0, 5)
        Row:SetHeight(50)
        Row.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 200))
        end

        -- Avatar & İsim
        local Avatar = vgui.Create("AvatarImage", Row)
        Avatar:SetPos(5, 5)
        Avatar:SetSize(40, 40)
        Avatar:SetPlayer(ply, 64)

        local NameLabel = vgui.Create("DLabel", Row)
        NameLabel:SetPos(60, 15)
        NameLabel:SetFont("DermaDefaultBold")
        NameLabel:SetText(ply:Nick())
        NameLabel:SizeToContents()

        -- Seviye
        local level = ply:GetNWInt("HLRPG_Level", 1) 
        local LevelLabel = vgui.Create("DLabel", Row)
        LevelLabel:SetPos(350, 12)
        LevelLabel:SetText("Lv. " .. level)
        LevelLabel:SetFont("DermaLarge")
        LevelLabel:SetColor(Color(255, 180, 0))
        LevelLabel:SizeToContents()

        -- **XP Bar & Dictionary Fix**
        local xp = ply:GetNWInt("HLRPG_XP", 0)
        local reqXP = 100 -- Fallback
        if HLRPG_GetRequiredXP then
            reqXP = HLRPG_GetRequiredXP(level)
        end

        local XPPercent = math.Clamp(xp / reqXP, 0, 1)

        local BarBG = vgui.Create("DPanel", Row)
        BarBG:SetPos(450, 15)
        BarBG:SetSize(200, 20)
        BarBG.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 150))
            draw.RoundedBox(4, 0, 0, w * XPPercent, h, Color(0, 200, 0, 200))
            draw.SimpleText(xp .. " / " .. reqXP, "DermaDefault", w/2, h/2, Color(255,255,255), 1, 1)
        end

        -- **TEMP POINTS GÖSTERGESİ**
        local tp = ply:GetNWInt("HLRPG_TempPoints", 0)
        local TPLabel = vgui.Create("DLabel", Row)
        TPLabel:SetPos(680, 15)
        TPLabel:SetText(tp .. " TP")
        TPLabel:SetFont("DermaDefaultBold")
        TPLabel:SetColor(Color(0, 255, 255))
        TPLabel:SizeToContents()

        -- **QUICK SHOP BUTONU**
        if ply == LocalPlayer() then
            local ShopBtn = vgui.Create("DButton", Row)
            ShopBtn:SetPos(760, 10)
            ShopBtn:SetSize(80, 30)
            ShopBtn:SetText("SHOP")
            ShopBtn:SetFont("DermaDefaultBold")
            ShopBtn:SetTextColor(Color(255, 255, 255))
            ShopBtn.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(0, 150, 255) or Color(0, 100, 200))
            end
            ShopBtn.DoClick = function()
                if OpenPlayerHub then 
                    OpenPlayerHub()
                    BoardPanel:Hide() 
                end     
            end
        end

        -- Ping
        local PingLabel = vgui.Create("DLabel", Row)
        PingLabel:SetPos(880, 15)
        PingLabel:SetText(ply:Ping())
        PingLabel:SizeToContents()
    end
end

hook.Add("ScoreboardShow", "HLRPG_Scoreboard_Open", function()
    CreateScoreboard()
    if IsValid(BoardPanel) then
        BoardPanel:Show()
        BoardPanel:MakePopup()
        BoardPanel:SetKeyboardInputEnabled(false)
    end
    return true 
end)

hook.Add("ScoreboardHide", "HLRPG_Scoreboard_Close", function()
    if IsValid(BoardPanel) then BoardPanel:Hide() end
end)