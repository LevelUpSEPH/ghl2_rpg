-- addons/halflife_rpg/lua/hlrpg/ui/cl_player_hub.lua
if not CLIENT then return end

local activeTab = "Shop"

function OpenPlayerHub()
    local frame = vgui.Create("DFrame")
    frame:SetSize(900, 750)
    frame:SetTitle("")
    frame:Center()
    frame:MakePopup()
    
    frame.Paint = function(s, w, h)
        -- Ana Arka Plan
        draw.RoundedBox(0, 0, 0, w, h, Color(25, 25, 25, 255)) 
        draw.RoundedBox(0, 0, 0, w, 50, Color(40, 40, 40, 255))
        
        local xp = LocalPlayer():GetNWInt("HLRPG_XP", 0)
        local tp = LocalPlayer():GetNWInt("HLRPG_TempPoints", 0)
        draw.SimpleText("PLAYER HUB - " .. activeTab:upper(), "DermaLarge", 20, 10, Color(255, 180, 0))
        draw.SimpleText("XP: " .. xp .. " | TP: " .. tp, "DermaDefaultBold", w - 20, 18, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
    end

    -- Tab Buton Konteynırı
    local tabContainer = vgui.Create("DPanel", frame)
    tabContainer:SetSize(400, 40)
    tabContainer:SetPos(frame:GetWide()/2 - 200, 10)
    tabContainer.Paint = nil

    local function CreateTabBtn(name, x)
        local b = vgui.Create("DButton", tabContainer)
        b:SetSize(190, 30)
        b:SetPos(x, 0)
        b:SetText(name:upper())
        b:SetFont("DermaDefaultBold")
        b:SetTextColor(Color(255, 255, 255))
        b.Paint = function(s, w, h)
            local isSelected = activeTab == name
            draw.RoundedBox(4, 0, 0, w, h, isSelected and Color(255, 150, 0) or Color(60, 60, 60))
        end
        b.DoClick = function() 
            activeTab = name 
            surface.PlaySound("ui/buttonclick.wav")
            frame:Refresh() 
        end
    end
    CreateTabBtn("Shop", 0)
    CreateTabBtn("Inventory", 200)

    local mainBody = vgui.Create("DPanel", frame)
    mainBody:Dock(FILL)
    mainBody:DockMargin(10, 50, 10, 10)
    mainBody.Paint = nil

    function CreateCategoryBox(parent, title, x, y, w, h, groupName, typeKey)
        local container = vgui.Create("DPanel", parent)
        container:SetSize(w, h)
        container:SetPos(x, y)
        container.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 45, 200)) 
            draw.SimpleText(title:upper(), "DermaDefaultBold", 10, 7, Color(150, 150, 150))
            surface.SetDrawColor(100, 100, 100, 30)
            surface.DrawLine(0, 25, w, 25)
        end

        -- === DETAY PANELI (Hover Bilgisi) ===
        local detailPanel = vgui.Create("DPanel", container)
        detailPanel:Dock(BOTTOM)
        detailPanel:SetTall(40)
        detailPanel.Paint = function(s, w, h)
            draw.RoundedBox(0, 0, 0, w, 1, Color(100, 100, 100, 50))
            if s.ItemName then
                local priceTxt = s.ItemPrice and (" | Fiyat: " .. s.ItemPrice .. " " .. s.ItemCurrency) or ""
                local lvlTxt = s.ItemLvl and (" | SEVİYE: " .. s.ItemLvl) or ""
                draw.SimpleText(s.ItemName .. priceTxt .. lvlTxt, "DermaDefaultBold", 10, 3, Color(255, 180, 0))
                draw.SimpleText(s.ItemDesc or "", "DermaDefault", 10, 20, Color(200, 200, 200))
            else
                draw.SimpleText("Bilgi için üzerine gel...", "DermaDefault", 10, h/2 - 7, Color(100, 100, 100))
            end
        end

        local scroll = vgui.Create("DScrollPanel", container)
        scroll:Dock(FILL)
        scroll:DockMargin(5, 30, 5, 2)

        local grid = vgui.Create("DIconLayout", scroll)
        grid:Dock(FILL)
        grid:SetSpaceX(8)
        grid:SetSpaceY(8)

        for id, info in pairs(HLRPG_Assets or {}) do
            if info.group != groupName then continue end
            
            local isOwned = LocalPlayer():GetNWBool("HLRPG_Owned_" .. id, false)
            
            -- Filtreleme
            if activeTab == "Shop" and isOwned and groupName != "Temporary Upgrades" then continue end
            if activeTab == "Inventory" and not isOwned then continue end

            -- Kuşanılma Durumu (Suit veya Pet için)
            local isEquipped = false
            if groupName == "Suits" then
                isEquipped = LocalPlayer():GetNWString("HLRPG_ActiveSuit", "") == id
            elseif groupName == "Pets" then
                isEquipped = LocalPlayer():GetNWString("HLRPG_ActivePet", "none") == id
            elseif groupName == "Hats" then
                isEquipped = LocalPlayer():GetNWString("HLRPG_ActiveHat", "none") == id
            elseif groupName == "Permanent Upgrades" then
                isEquipped = LocalPlayer():GetNWBool("HLRPG_ModActive_" .. id, false)
            end

            local icon = grid:Add("SpawnIcon")
            if info.model then 
                icon:SetModel(info.model)
            elseif info.icon then
                icon:SetIcon(info.icon)
            end
            icon:SetSize(64, 64)
            icon:SetTooltip(nil)

            -- === HOVER ETKİLEŞİMİ ===
            icon.OnCursorEntered = function()
                detailPanel.ItemName = info.name
                detailPanel.ItemDesc = info.desc
                if activeTab == "Shop" then
                    detailPanel.ItemPrice = info.price
                    detailPanel.ItemCurrency = info.currency
                    detailPanel.ItemLvl = nil
                else
                    detailPanel.ItemPrice = nil
                    if groupName == "Pets" then
                        local level = LocalPlayer():GetNWInt("PetLevel_" .. id, 1)
                        local name = LocalPlayer():GetNWString("HLRPG_CustomName_" .. id, info.name)
                        detailPanel.ItemName = name
                        detailPanel.ItemLvl = level
                    else
                        detailPanel.ItemLvl = nil
                    end
                end
            end
            icon.OnCursorExited = function()
                detailPanel.ItemName = nil
            end

            icon.PaintOver = function(s, w, h)
                -- Sadece Inventory sekmesindeysek ve item kuşanılmışsa göster
                if activeTab == "Inventory" and isEquipped then
                    -- Dış çerçeve (Parlak Yeşil)
                    surface.SetDrawColor(0, 255, 0, 255)
                    surface.DrawOutlinedRect(0, 0, w, h, 2) -- 2 piksellik kalınlık
                    
                    -- İçten hafif bir parlama efekti (Opsiyonel)
                    surface.SetDrawColor(0, 255, 0, 30)
                    surface.DrawRect(2, 2, w-4, h-4)

                    -- Sağ üst köşeye bir onay işareti (Checkmark)
                    draw.SimpleText("●", "DermaDefaultBold", w - 10, 8, Color(0, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                -- Market (Shop) sekmesindeysek ve para yetmiyorsa kırmızı karartma
                if activeTab == "Shop" then
                    local myMoney = (info.currency == "TP") and LocalPlayer():GetNWInt("HLRPG_TempPoints") or LocalPlayer():GetNWInt("HLRPG_XP")
                    if myMoney < (info.price or 0) then
                        surface.SetDrawColor(255, 0, 0, 40)
                        surface.DrawRect(0, 0, w, h)
                    end
                end
            end

            -- === SEÇİLİ EFEKTİ (Overlay) ===
            local overlay = vgui.Create("DPanel", icon)
            overlay:Dock(FILL)
            overlay:SetMouseInputEnabled(false)
            overlay.Paint = function(s, w, h)
                if activeTab == "Inventory" and isEquipped then
                    surface.SetDrawColor(0, 255, 0, 200)
                    surface.DrawOutlinedRect(0, 0, w, h, 2)
                    surface.DrawOutlinedRect(1, 1, w-2, h-2, 1)
                    draw.SimpleText("✔", "DermaDefaultBold", w - 12, 2, Color(0, 255, 0))
                end
            end
            
            icon.DoClick = function()
                -- Eğer Envanterde bir pete tıklandıysa menü aç
                if activeTab == "Inventory" and groupName == "Pets" then
                    local menu = DermaMenu()
                    
                    menu:AddOption("Kuşan / Geri Gönder", function()
                        net.Start("HLRPG_HubAction")
                            net.WriteString("equip")
                            net.WriteString(id)
                        net.SendToServer()
                    end):SetIcon("icon16/monkey.png")

                    menu:AddOption("Peti Özelleştir (İsim/Renk)", function()
                        HLRPG_OpenPetCustomizer(id) -- Yeni oluşturduğumuz fonksiyon
                    end):SetIcon("icon16/palette.png")

                    menu:Open()
                    return
                end

                surface.PlaySound("ui/buttonclick.wav")
                if activeTab == "Shop" then
                    net.Start("HLRPG_Shop_Purchase")
                        net.WriteString(id)
                    net.SendToServer()
                else
                    net.Start("HLRPG_HubAction")
                        net.WriteString("equip")
                        net.WriteString(id)
                    net.SendToServer()
                end
                
                timer.Simple(0.2, function() if IsValid(frame) then frame:Refresh() end end)
            end
        end
    end

    function frame:Refresh()
        mainBody:Clear()
        -- Kategoriler
        CreateCategoryBox(mainBody, "Sarf Malzemeleri", 0, 0, 435, 180, "Temporary Upgrades", "consumable")
        CreateCategoryBox(mainBody, "Kalıcı Geliştirmeler", 445, 0, 435, 180, "Permanent Upgrades", "upgrade")
        CreateCategoryBox(mainBody, "Petler", 0, 190, 435, 180, "Pets", "pet")
        CreateCategoryBox(mainBody, "Şapkalar & Aksesuarlar", 445, 190, 435, 180, "Hats", "hat")
        CreateCategoryBox(mainBody, "Zırhlar & Karakterler", 0, 380, 880, 210, "Suits", "suit")
    end

    frame:Refresh()
end