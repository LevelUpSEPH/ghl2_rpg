-- hlrpg/ui/cl_model_menu.lua
-- Character menu for picking a base player model from HLRPG.Config.Models. Opened with F1 or from the TAB menu.

local menuFrame

-- Toggles: calling it while open closes it
function HLRPG.OpenModelMenu()
    if IsValid(menuFrame) then
        menuFrame:Close()
        return
    end

    menuFrame = vgui.Create("DFrame")
    menuFrame:SetSize(600, 500)
    menuFrame:Center()
    menuFrame:SetTitle("Half-Life RPG: Character Management")
    menuFrame:MakePopup()
    menuFrame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 250))
    end

    local sheet = vgui.Create("DPropertySheet", menuFrame)
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
            net.Start("HLRPG_SetPlayerModel")
                net.WriteString(item.model)
            net.SendToServer()

            surface.PlaySound("ui/buttonclick.wav")
        end
    end

    sheet:AddSheet("Characters", panelModel, "icon16/user_suit.png")
end

net.Receive("HLRPG_OpenMenu", HLRPG.OpenModelMenu)
