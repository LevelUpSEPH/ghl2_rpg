-- addons/halflife_rpg/lua/hlrpg/ui/cl_scoreboard.lua

if not CLIENT then return end -- Sadece oyuncu tarafında çalışır

local BoardPanel = nil

-- Scoreboard'un içini boyayan ve listeyi oluşturan fonksiyon
local function CreateScoreboard()
    -- Eğer zaten açıksa tekrar yaratma
    if IsValid(BoardPanel) then BoardPanel:Remove() end

    -- 1. ANA ÇERÇEVE (Arka Plan)
    BoardPanel = vgui.Create("DPanel")
    BoardPanel:SetSize(900, 600)
    BoardPanel:Center()
    
    -- Paint fonksiyonunu override ederek (ezerek) görünümü özelleştiriyoruz
    BoardPanel.Paint = function(self, w, h)
        -- Yarı saydam siyah arka plan
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 20, 240))
        
        -- Üst Başlık Şeridi
        draw.RoundedBoxEx(8, 0, 0, w, 80, Color(40, 40, 40, 255), true, true, false, false)
        
        -- Başlık Yazısı
        draw.SimpleText("HALF-LIFE 2: RPG CAMPAIGN", "DermaLarge", 20, 20, Color(255, 180, 0), TEXT_ALIGN_LEFT)
        draw.SimpleText("Sunucu Durumu: Aktif", "DermaDefault", 22, 50, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        
        -- Sütun Başlıkları (Header)
        draw.SimpleText("OYUNCU", "DermaDefaultBold", 80, 90, Color(150, 150, 150))
        draw.SimpleText("SEVİYE", "DermaDefaultBold", 400, 90, Color(150, 150, 150))
        draw.SimpleText("XP DURUMU", "DermaDefaultBold", 500, 90, Color(150, 150, 150))
        draw.SimpleText("PING", "DermaDefaultBold", 800, 90, Color(150, 150, 150))
        
        -- Ayırıcı Çizgi
        surface.SetDrawColor(100, 100, 100, 100)
        surface.DrawLine(20, 110, w-20, 110)
    end

    -- 2. KAYDIRILABİLİR LİSTE (Scroll Panel)
    local Scroll = vgui.Create("DScrollPanel", BoardPanel)
    Scroll:SetPos(20, 120)
    Scroll:SetSize(860, 460)

    -- 3. OYUNCULARI LİSTELE
    -- Serverdaki herkesi döngüye alıp satır oluşturuyoruz
    for _, ply in ipairs(player.GetAll()) do
        
        -- Satır Paneli
        local Row = Scroll:Add("DPanel")
        Row:Dock(TOP)
        Row:DockMargin(0, 0, 0, 5) -- Satırlar arası boşluk
        Row:SetHeight(50)
        
        Row.Paint = function(self, w, h)
            -- Satır rengi (Hafif gri)
            draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 200))
        end

        -- Avatar (Profil Resmi)
        local Avatar = vgui.Create("AvatarImage", Row)
        Avatar:SetPos(5, 5)
        Avatar:SetSize(40, 40)
        Avatar:SetPlayer(ply, 64)

        -- Oyuncu İsmi
        local NameLabel = vgui.Create("DLabel", Row)
        NameLabel:SetPos(60, 15)
        NameLabel:SetFont("DermaDefaultBold")
        NameLabel:SetText(ply:Nick())
        NameLabel:SetColor(Color(255, 255, 255))
        NameLabel:SizeToContents()

        -- **LEVEL GÖSTERGESİ** (Server'dan gelen veriyi burada okuyoruz)
        local LevelLabel = vgui.Create("DLabel", Row)
        LevelLabel:SetPos(400, 12)
        -- GetNWInt: Networked Integer (Ağ Değişkeni)
        local level = ply:GetNWInt("HLRPG_Level", 1) 
        LevelLabel:SetText("Lv. " .. level)
        LevelLabel:SetFont("DermaLarge")
        LevelLabel:SetColor(Color(255, 180, 0)) -- Altın rengi
        LevelLabel:SizeToContents()

        -- **XP BAR** (Görsel Bar)
        local XPAmount = ply:GetNWInt("HLRPG_XP", 0)
        local XPReq = level * 100 -- Level formülümüz (Lv * 100)
        local XPPercent = math.Clamp(XPAmount / XPReq, 0, 1) -- 0 ile 1 arası oran

        -- XP Barının Arka Planı
        local BarBG = vgui.Create("DPanel", Row)
        BarBG:SetPos(500, 15)
        BarBG:SetSize(200, 20)
        BarBG.Paint = function(self, w, h)
            -- Siyah zemin
            draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 150))
            -- Doluluk oranı (Yeşil)
            draw.RoundedBox(4, 0, 0, w * XPPercent, h, Color(0, 200, 0, 200))
        end
        
        -- XP Yazısı (Barın üstüne)
        local XPLabel = vgui.Create("DLabel", BarBG)
        XPLabel:SetText(XPAmount .. " / " .. XPReq)
        XPLabel:SetColor(Color(255, 255, 255))
        XPLabel:Center()

        -- Ping
        local PingLabel = vgui.Create("DLabel", Row)
        PingLabel:SetPos(800, 15)
        PingLabel:SetText(ply:Ping() .. " ms")
        PingLabel:SizeToContents()
    end
end

-- 4. SCOREBOARD AÇMA / KAPAMA (HOOKS)

-- TAB tuşuna basınca (Aç)
hook.Add("ScoreboardShow", "HLRPG_Scoreboard_Open", function()
    -- Scoreboardu her seferinde yeniden yaratıyoruz ki veriler (yeni girenler) güncellensin
    CreateScoreboard()
    
    if IsValid(BoardPanel) then
        BoardPanel:Show()
        BoardPanel:MakePopup() -- Mouse kullanımını aç
        BoardPanel:SetKeyboardInputEnabled(false) -- Yürümeye devam edebilmek için
    end
    
    return true -- Lambda'nın scoreboardunu engelle
end)

-- TAB tuşunu bırakınca (Kapa)
hook.Add("ScoreboardHide", "HLRPG_Scoreboard_Close", function()
    if IsValid(BoardPanel) then
        BoardPanel:Hide()
    end
end)