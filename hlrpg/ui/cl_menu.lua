-- addons/halflife_rpg/lua/hlrpg/ui/cl_menu.lua

if not CLIENT then return end

local MenuFrame = nil

net.Receive("HLRPG_OpenMenu", function()
    if IsValid(MenuFrame) then 
        MenuFrame:Close() 
        return 
    end
    
    MenuFrame = vgui.Create("DFrame")
    MenuFrame:SetSize(600, 500)
    MenuFrame:Center()
    MenuFrame:SetTitle("Half-Life RPG: Karakter Yönetimi")
    MenuFrame:MakePopup()
    MenuFrame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 250))
    end

    local sheet = vgui.Create("DPropertySheet", MenuFrame)
    sheet:Dock(FILL)

    local panelModel = vgui.Create("DPanel", sheet)
    panelModel.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50)) end
    
    local scrollModel = vgui.Create("DScrollPanel", panelModel)
    scrollModel:Dock(FILL)

    local grid = vgui.Create("DIconLayout", scrollModel)
    grid:Dock(FILL)
    grid:SetSpaceY(10)
    grid:SetSpaceX(10)
    grid:SetBorder(10)

    for _, item in ipairs(HLRPG.Config.Models) do
        local icon = grid:Add("SpawnIcon")
        icon:SetModel(item.model)
        icon:SetTooltip(item.name)
        
        icon.DoClick = function()
            net.Start("HLRPG_EquipItem")
            net.WriteString("model")
            net.WriteString(item.model)
            net.SendToServer()
            
            surface.PlaySound("ui/buttonclick.wav")
        end
    end
    
    sheet:AddSheet("Karakterler", panelModel, "icon16/user_suit.png")
end)