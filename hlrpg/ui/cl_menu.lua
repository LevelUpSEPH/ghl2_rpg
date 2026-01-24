-- addons/halflife_rpg/lua/hlrpg/ui/cl_menu.lua

if not CLIENT then return end

local MenuFrame = nil

-- Serverdan "Menüyü Aç" emri gelince çalışır
net.Receive("HLRPG_OpenMenu", function()
    if IsValid(MenuFrame) then 
        MenuFrame:Close() 
        return 
    end
    
    -- 1. ANA PENCERE
    MenuFrame = vgui.Create("DFrame")
    MenuFrame:SetSize(600, 500)
    MenuFrame:Center()
    MenuFrame:SetTitle("Half-Life RPG: Karakter Yönetimi")
    MenuFrame:MakePopup() -- Mouse'u aktif et
    MenuFrame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 250))
    end

    -- 2. SEKMELER (Tabs)
    local sheet = vgui.Create("DPropertySheet", MenuFrame)
    sheet:Dock(FILL)

    -- === SEKME 1: MODELLER ===
    local panelModel = vgui.Create("DPanel", sheet)
    panelModel.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50)) end
    
    local scrollModel = vgui.Create("DScrollPanel", panelModel)
    scrollModel:Dock(FILL)

    -- Izgara görünümü (Grid)
    local grid = vgui.Create("DIconLayout", scrollModel)
    grid:Dock(FILL)
    grid:SetSpaceY(10)
    grid:SetSpaceX(10)
    grid:SetBorder(10)

    -- Config dosyasındaki modelleri listele
    for _, item in ipairs(HLRPG.Config.Models) do
        -- Her model için bir ikon kutusu
        local icon = grid:Add("SpawnIcon")
        icon:SetModel(item.model)
        icon:SetTooltip(item.name)
        
        -- Tıklayınca ne olsun?
        icon.DoClick = function()
            -- Server'a istek yolla
            net.Start("HLRPG_EquipItem")
            net.WriteString("model")
            net.WriteString(item.model)
            net.SendToServer()
            
            surface.PlaySound("ui/buttonclick.wav")
        end
    end
    
    sheet:AddSheet("Kıyafetler", panelModel, "icon16/user_suit.png")


    -- === SEKME 2: ŞAPKALAR ===
    local panelHat = vgui.Create("DPanel", sheet)
    local listHat = vgui.Create("DListView", panelHat)
    listHat:Dock(FILL)
    listHat:AddColumn("Şapka Adı")
    listHat:AddColumn("ID")

    for _, hat in ipairs(HLRPG.Config.Hats) do
        local line = listHat:AddLine(hat.name, hat.id)
        
        line.OnSelect = function()
            net.Start("HLRPG_EquipItem")
            net.WriteString("hat")
            net.WriteString(hat.id)
            net.SendToServer()
        end
    end

    sheet:AddSheet("Ekipman & Şapka", panelHat, "icon16/shield.png")
    
    -- === SEKME 3: PETLER (Hazırlık) ===
    local panelPet = vgui.Create("DPanel", sheet)
    local label = vgui.Create("DLabel", panelPet)
    label:SetText("Yakında...")
    label:Center()
    
    sheet:AddSheet("Pet Yönetimi", panelPet, "icon16/bug.png")

    -- === SEKME: SUITLER (ZIRHLAR) ===
    local panelSuit = vgui.Create("DPanel", sheet)
    local listSuit = vgui.Create("DListView", panelSuit)
    listSuit:Dock(FILL)
    listSuit:AddColumn("Zırh Adı")
    listSuit:AddColumn("Model")
    
    for _, item in ipairs(HLRPG.Config.Suits) do
        local line = listSuit:AddLine(item.name, item.model or "Yok")
        
        line.OnSelect = function()
            net.Start("HLRPG_EquipItem")
            net.WriteString("suit")
            net.WriteString(item.id) -- ID'yi yolla (örn: suit_combine)
            net.SendToServer()
        end
    end
    
    sheet:AddSheet("Zırhlar", panelSuit, "icon16/shield.png")

end)