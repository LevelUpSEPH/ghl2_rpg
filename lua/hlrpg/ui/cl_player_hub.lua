-- hlrpg/ui/cl_player_hub.lua
-- Shop and inventory window, opened from the scoreboard's SHOP button.

local CATEGORIES = {
    { title = "Consumables",        group = "Temporary Upgrades", x = 0,   y = 0,   w = 435, h = 180 },
    { title = "Permanent Upgrades", group = "Permanent Upgrades", x = 445, y = 0,   w = 435, h = 180 },
    { title = "Pets",               group = "Pets",               x = 0,   y = 190, w = 435, h = 180 },
    { title = "Hats & Accessories", group = "Hats",               x = 445, y = 190, w = 435, h = 180 },
    { title = "Suits & Characters", group = "Suits",              x = 0,   y = 380, w = 880, h = 210 },
}

local activeTab = "Shop"

-- Feature items (e.g. Bunny Hop) are switched on/off by clicking them in the inventory. The switch is a
-- client convar: saved on the player's machine and sent to the server, which reads it through GetInfoNum.
for _, asset in pairs(HLRPG.Assets) do
    if asset.type == "feature" then
        CreateClientConVar(asset.setting, "1", true, true, "HLRPG: enable " .. asset.name)
    end
end

local function SetFeatureEnabled(itemID, enabled)
    RunConsoleCommand(HLRPG.Assets[itemID].setting, enabled and "1" or "0")
end

local function IsEquipped(groupName, itemID)
    local ply = LocalPlayer()
    if HLRPG.Assets[itemID].type == "feature" then
        return HLRPG.IsFeatureEnabled(ply, itemID)
    elseif groupName == "Suits" then
        return ply:GetNWString("HLRPG_ActiveSuit", "") == itemID
    elseif groupName == "Pets" then
        return ply:GetNWString("HLRPG_ActivePet", "none") == itemID
    elseif groupName == "Hats" then
        return ply:GetNWString("HLRPG_ActiveHat", "none") == itemID
    elseif groupName == "Permanent Upgrades" then
        return ply:GetNWBool("HLRPG_ModActive_" .. itemID, false)
    end
    return false
end

local function ShouldShow(groupName, itemID, info)
    local isOwned = LocalPlayer():GetNWBool("HLRPG_Owned_" .. itemID, false)

    if activeTab == "Shop" then
        return not info.unbuyable and (not isOwned or groupName == "Temporary Upgrades")
    end
    return isOwned
end

local function SendEquip(itemID)
    net.Start("HLRPG_HubAction")
        net.WriteString("equip")
        net.WriteString(itemID)
    net.SendToServer()
end

local function OpenPetMenu(itemID)
    local menu = DermaMenu()
    menu:AddOption("Equip / Dismiss", function() SendEquip(itemID) end):SetIcon("icon16/monkey.png")
    menu:AddOption("Customize Pet (Name/Color)", function() HLRPG.OpenPetCustomizer(itemID) end):SetIcon("icon16/palette.png")
    menu:Open()
end

local function CreateDetailPanel(container)
    local detailPanel = vgui.Create("DPanel", container)
    detailPanel:Dock(BOTTOM)
    detailPanel:SetTall(56)
    detailPanel.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, 1, Color(100, 100, 100, 50))
        if s.ItemName then
            local priceTxt = s.ItemPrice and (" | Price: " .. s.ItemPrice .. " " .. s.ItemCurrency) or ""
            local lvlTxt = s.ItemLvl and (" | LEVEL: " .. s.ItemLvl) or ""
            draw.SimpleText(s.ItemName .. priceTxt .. lvlTxt, "DermaDefaultBold", 10, 3, Color(255, 180, 0))
            draw.SimpleText(s.ItemDesc or "", "DermaDefault", 10, 20, Color(200, 200, 200))
            draw.SimpleText(s.ItemAbilities or "", "DermaDefault", 10, 36, Color(120, 200, 255))
        else
            draw.SimpleText("Hover over an item for details...", "DermaDefault", 10, h / 2 - 7, Color(100, 100, 100))
        end
    end
    return detailPanel
end

local function CreateItemIcon(grid, detailPanel, groupName, itemID, info, refresh)
    local isEquipped = IsEquipped(groupName, itemID)

    local icon = grid:Add("SpawnIcon")
    if info.model then
        icon:SetModel(info.model)
    elseif info.icon then
        icon:SetIcon(info.icon)
    end
    icon:SetSize(64, 64)
    icon:SetTooltip(nil)

    icon.OnCursorEntered = function()
        detailPanel.ItemName = info.name
        detailPanel.ItemDesc = info.desc
        detailPanel.ItemAbilities = HLRPG.DescribeAbilities(info)
        detailPanel.ItemPrice = nil
        detailPanel.ItemLvl = nil

        if activeTab == "Shop" then
            detailPanel.ItemPrice = info.price
            detailPanel.ItemCurrency = info.currency
        elseif groupName == "Pets" then
            detailPanel.ItemName = LocalPlayer():GetNWString("HLRPG_CustomName_" .. itemID, info.name)
            detailPanel.ItemLvl = LocalPlayer():GetNWInt("PetLevel_" .. itemID, 1)
        end
    end
    icon.OnCursorExited = function()
        detailPanel.ItemName = nil
    end

    icon.PaintOver = function(s, w, h)
        if activeTab == "Inventory" and isEquipped then
            surface.SetDrawColor(0, 255, 0, 30)
            surface.DrawRect(2, 2, w - 4, h - 4)
            surface.SetDrawColor(0, 255, 0, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            draw.SimpleText("✔", "DermaDefaultBold", w - 12, 2, Color(0, 255, 0))
        end

        if activeTab == "Shop" then
            local ply = LocalPlayer()
            local balance = (info.currency == "TP") and ply:GetNWInt("HLRPG_TempPoints") or ply:GetNWInt("HLRPG_XP")
            if balance < (info.price or 0) then
                surface.SetDrawColor(255, 0, 0, 40)
                surface.DrawRect(0, 0, w, h)
            end
        end
    end

    icon.DoClick = function()
        if activeTab == "Inventory" and groupName == "Pets" then
            OpenPetMenu(itemID)
            return
        end

        surface.PlaySound("ui/buttonclick.wav")
        if activeTab == "Shop" then
            net.Start("HLRPG_Shop_Purchase")
                net.WriteString(itemID)
            net.SendToServer()
        elseif info.type == "feature" then
            -- Features are a client setting, not equipment
            SetFeatureEnabled(itemID, not isEquipped)
            chat.AddText(Color(255, 180, 0), "[INV] ", color_white, info.name .. (isEquipped and " disabled." or " enabled."))
        else
            SendEquip(itemID)
        end

        timer.Simple(0.2, refresh)
    end
end

local function CreateCategoryBox(parent, category, refresh)
    local container = vgui.Create("DPanel", parent)
    container:SetSize(category.w, category.h)
    container:SetPos(category.x, category.y)
    container.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 45, 200))
        draw.SimpleText(category.title:upper(), "DermaDefaultBold", 10, 7, Color(150, 150, 150))
        surface.SetDrawColor(100, 100, 100, 30)
        surface.DrawLine(0, 25, w, 25)
    end

    local detailPanel = CreateDetailPanel(container)

    local scroll = vgui.Create("DScrollPanel", container)
    scroll:Dock(FILL)
    scroll:DockMargin(5, 30, 5, 2)

    local grid = vgui.Create("DIconLayout", scroll)
    grid:Dock(FILL)
    grid:SetSpaceX(8)
    grid:SetSpaceY(8)

    for itemID, info in pairs(HLRPG.Assets) do
        if info.group == category.group and ShouldShow(category.group, itemID, info) then
            CreateItemIcon(grid, detailPanel, category.group, itemID, info, refresh)
        end
    end
end

function HLRPG.OpenPlayerHub()
    local frame = vgui.Create("DFrame")
    frame:SetSize(900, 750)
    frame:SetTitle("")
    frame:Center()
    frame:MakePopup()

    frame.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(25, 25, 25, 255))
        draw.RoundedBox(0, 0, 0, w, 50, Color(40, 40, 40, 255))

        local xp = LocalPlayer():GetNWInt("HLRPG_XP", 0)
        local tp = LocalPlayer():GetNWInt("HLRPG_TempPoints", 0)
        draw.SimpleText("PLAYER HUB - " .. activeTab:upper(), "DermaLarge", 20, 10, Color(255, 180, 0))
        draw.SimpleText("XP: " .. xp .. " | TP: " .. tp, "DermaDefaultBold", w - 20, 18, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
    end

    local mainBody = vgui.Create("DPanel", frame)
    mainBody:Dock(FILL)
    mainBody:DockMargin(10, 50, 10, 10)
    mainBody.Paint = nil

    local function Refresh()
        if not IsValid(frame) then return end

        mainBody:Clear()
        for _, category in ipairs(CATEGORIES) do
            CreateCategoryBox(mainBody, category, Refresh)
        end
    end

    local tabContainer = vgui.Create("DPanel", frame)
    tabContainer:SetSize(400, 40)
    tabContainer:SetPos(frame:GetWide() / 2 - 200, 10)
    tabContainer.Paint = nil

    for i, name in ipairs({ "Shop", "Inventory" }) do
        local b = vgui.Create("DButton", tabContainer)
        b:SetSize(190, 30)
        b:SetPos((i - 1) * 200, 0)
        b:SetText(name:upper())
        b:SetFont("DermaDefaultBold")
        b:SetTextColor(Color(255, 255, 255))
        b.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, activeTab == name and Color(255, 150, 0) or Color(60, 60, 60))
        end
        b.DoClick = function()
            activeTab = name
            surface.PlaySound("ui/buttonclick.wav")
            Refresh()
        end
    end

    Refresh()
end
