-- hlrpg/ui/cl_gear_menu.lua
-- Loot (core/sh_gear.lua): the GEAR window (equipped slots on the left, backpack on the right) and the popup when
-- an item drops. Opened from the TAB menu. Clicking an item equips or salvages it; clicking a slot unequips it.

local G = HLRPG.Gear
local COL_BG = Color(18, 18, 18, 250)
local COL_HEADER = Color(28, 28, 28)
local COL_ACCENT = Color(255, 180, 0)

local gearFrame
local gearData = { items = {}, equipped = {}, size = G.BackpackSize }

local function SendAction(action, uid)
    net.Start("HLRPG_GearAction")
        net.WriteString(action)
        net.WriteString(uid)
    net.SendToServer()
end

-- Height an item card needs for its lines
local function CardHeight(item)
    return 44 + #G.DescribeItem(item) * 15
end

-- Draws an item: rarity-coloured edge and name, slot and item level, one line per stat or ability
local function PaintItem(item, w, h, hovered, equipped)
    local tier = G.Rarities[item.rarity] or G.Rarities[1]
    draw.RoundedBox(4, 0, 0, w, h, hovered and Color(40, 40, 40) or Color(28, 28, 28))
    surface.SetDrawColor(tier.color)
    surface.DrawRect(0, 0, 3, h)
    if equipped then
        surface.SetDrawColor(tier.color.r, tier.color.g, tier.color.b, 120)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    draw.SimpleText(item.name, "DermaDefaultBold", 12, 7, tier.color)
    draw.SimpleText(tier.name .. "  " .. G.GetSlotName(item.slot) .. "  |  iLvl " .. item.ilvl, "DermaDefault", 12, 23, Color(140, 140, 140))

    -- Implants: a swatch of the neon colour the wearer glows in while the active runs
    if item.color then
        draw.RoundedBox(3, w - 26, 8, 14, 14, Color(item.color.r, item.color.g, item.color.b))
    end

    local styles = {
        stat = { "+ ", Color(210, 210, 210) },
        passive = { "* ", COL_ACCENT },
        active = { "", Color(120, 200, 255) },
        cooldown = { "", Color(130, 130, 130) },
    }
    for i, line in ipairs(G.DescribeItem(item)) do
        local style = styles[line[2]] or styles.stat
        draw.SimpleText(style[1] .. line[1], "DermaDefault", 12, 40 + (i - 1) * 15, style[2])
    end
end

local function SalvageLabel(item)
    local xp = HLRPG.GetKillEquivalentXP(G.Rarities[item.rarity].kills, LocalPlayer():GetNWInt("HLRPG_Level", 1))
    return "Salvage (+" .. string.Comma(xp) .. " XP)"
end

local activeSlot = "gloves"
local TAB_H = 30

local EMPTY_TEXT = {
    gloves = "No gloves in your backpack. Enemies sometimes drop them, tougher ones more often.",
    chestrig = "No chest rigs in your backpack. Enemies sometimes drop them, tougher ones more often.",
    implant = "No implants yet. They only drop from bosses on Insane, and rarely.",
}

local function AddHeader(parent, text)
    local header = parent:Add("DLabel")
    header:Dock(TOP)
    header:SetText(text)
    header:SetFont("DermaDefaultBold")
    header:SetTextColor(Color(150, 150, 150))
    header:DockMargin(2, 6, 0, 4)
end

-- Items of one slot that aren't equipped, best first
local function BackpackFor(slotID)
    local equippedUID = gearData.equipped[slotID]
    local list = {}
    for uid, item in pairs(gearData.items) do
        if item.slot == slotID and uid ~= equippedUID then list[#list + 1] = item end
    end
    table.sort(list, function(a, b)
        if a.rarity ~= b.rarity then return a.rarity > b.rarity end
        return a.ilvl > b.ilvl
    end)
    return list
end

local function FillSection(frame)
    if IsValid(frame.Body) then frame.Body:Remove() end
    local body = vgui.Create("DScrollPanel", frame)
    frame.Body = body
    body:Dock(FILL)
    body:DockMargin(10, 40 + TAB_H + 6, 10, 10)

    -- The equipped item, alone on top
    AddHeader(body, "EQUIPPED")
    local uid = gearData.equipped[activeSlot]
    local equipped = uid and gearData.items[uid]
    local card = body:Add("DButton")
    card:Dock(TOP)
    card:SetText("")
    card:SetTall(equipped and CardHeight(equipped) or 44)
    card:DockMargin(0, 0, 4, 10)
    card.Paint = function(s, w, h)
        if equipped then return PaintItem(equipped, w, h, s:IsHovered(), true) end
        draw.RoundedBox(4, 0, 0, w, h, Color(24, 24, 24))
        draw.SimpleText("Nothing equipped", "DermaDefault", w / 2, h / 2, Color(90, 90, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    card.DoClick = function()
        if not equipped then return end
        local menu = DermaMenu()
        menu:AddOption("Unequip", function() SendAction("unequip", equipped.uid) end):SetIcon("icon16/arrow_down.png")
        menu:AddOption(SalvageLabel(equipped), function() SendAction("salvage", equipped.uid) end):SetIcon("icon16/bin.png")
        menu:Open()
    end

    -- This slot's items in the backpack
    local backpack = BackpackFor(activeSlot)
    AddHeader(body, "BACKPACK (" .. #backpack .. ")")
    if #backpack == 0 then
        local empty = body:Add("DLabel")
        empty:Dock(TOP)
        empty:SetTall(50)
        empty:SetContentAlignment(5)
        empty:SetTextColor(Color(110, 110, 110))
        empty:SetText(EMPTY_TEXT[activeSlot] or "")
    end

    for _, item in ipairs(backpack) do
        local row = body:Add("DButton")
        row:Dock(TOP)
        row:SetText("")
        row:SetTall(CardHeight(item))
        row:DockMargin(0, 0, 4, 6)
        row.Paint = function(s, w, h) PaintItem(item, w, h, s:IsHovered(), false) end
        row.DoClick = function()
            local menu = DermaMenu()
            menu:AddOption(equipped and "Equip (replaces " .. equipped.name .. ")" or "Equip", function() SendAction("equip", item.uid) end):SetIcon("icon16/arrow_up.png")
            menu:AddOption(SalvageLabel(item), function() SendAction("salvage", item.uid) end):SetIcon("icon16/bin.png")
            menu:Open()
        end
    end
end

-- One tab per slot, with how many of that slot's items you have
local function CreateTabs(frame)
    if frame.Tabs then
        for _, tab in ipairs(frame.Tabs) do tab:Remove() end
    end
    frame.Tabs = {}

    local tabW = (frame:GetWide() - 20 - 6 * (#G.Slots - 1)) / #G.Slots
    for i, slot in ipairs(G.Slots) do
        local count = 0
        for _, item in pairs(gearData.items) do
            if item.slot == slot.id then count = count + 1 end
        end

        local tab = vgui.Create("DButton", frame)
        tab:SetPos(10 + (i - 1) * (tabW + 6), 40)
        tab:SetSize(tabW, TAB_H)
        tab:SetText("")
        tab.Paint = function(btn, w, h)
            local active = activeSlot == slot.id
            draw.RoundedBox(4, 0, 0, w, h, active and Color(40, 40, 40) or (btn:IsHovered() and Color(32, 32, 32) or Color(24, 24, 24)))
            if active then
                surface.SetDrawColor(COL_ACCENT)
                surface.DrawRect(0, h - 2, w, 2)
            end
            draw.SimpleText(string.upper(slot.name) .. "  " .. count, "DermaDefaultBold", w / 2, h / 2,
                active and color_white or Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        tab.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            activeSlot = slot.id
            FillSection(frame)
        end
        frame.Tabs[#frame.Tabs + 1] = tab
    end
end

local function FillGear(frame)
    frame.BackpackCount = table.Count(gearData.items)
    CreateTabs(frame)
    FillSection(frame)
end

function HLRPG.OpenGearMenu()
    if IsValid(gearFrame) then
        FillGear(gearFrame)
        return
    end

    local frame = vgui.Create("DFrame")
    gearFrame = frame
    frame:SetSize(560, 640)
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COL_BG)
        surface.SetDrawColor(COL_HEADER)
        surface.DrawRect(0, 0, w, 32)
        surface.SetDrawColor(COL_ACCENT)
        surface.DrawRect(0, 31, w, 1)
        draw.SimpleText("GEAR", "DermaDefaultBold", 12, 8, Color(200, 200, 200))
        draw.SimpleText("BACKPACK " .. (self.BackpackCount or 0) .. " / " .. gearData.size, "DermaDefaultBold", w - 55, 8, COL_ACCENT, TEXT_ALIGN_RIGHT)
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

    FillGear(frame)
end

-- Asks the server for the gear and opens the window when it arrives (the TAB menu's GEAR tile)
local openRequested = false
function HLRPG.RequestGearMenu()
    openRequested = true
    HLRPG.RequestMenu("gear")
end

-- The server sends the gear when the menu is requested and after every change (drops too): refresh an open
-- window, but only open one when it was asked for
net.Receive("HLRPG_GearData", function()
    gearData = net.ReadTable()
    gearData.size = gearData.size or G.BackpackSize
    if IsValid(gearFrame) then
        FillGear(gearFrame)
    elseif openRequested then
        HLRPG.OpenGearMenu()
    end
    openRequested = false
end)

-- Drop popup: slides in under the top of the screen for a few seconds
local drops = {}
local POPUP_TIME = 5

net.Receive("HLRPG_GearDrop", function()
    local item = net.ReadTable()
    local source = net.ReadString()
    table.insert(drops, { item = item, source = source, born = CurTime() })
    if #drops > 4 then table.remove(drops, 1) end
    surface.PlaySound(item.rarity >= 4 and "items/suitchargeok1.wav" or "items/ammo_pickup.wav")
end)

hook.Add("HUDPaint", "HLRPG_GearDropPopup", function()
    local now = CurTime()
    local y = 140
    for i = #drops, 1, -1 do
        local drop = drops[i]
        local age = now - drop.born
        if age > POPUP_TIME then
            table.remove(drops, i)
        else
            local alpha = 255 * math.Clamp(math.min(age * 4, (POPUP_TIME - age) * 2), 0, 1)
            local tier = G.Rarities[drop.item.rarity] or G.Rarities[1]
            local text = "LOOT  " .. tier.name .. " " .. drop.item.name .. "  (iLvl " .. drop.item.ilvl .. ")"
            surface.SetFont("DermaDefaultBold")
            local tw = surface.GetTextSize(text)
            local x = ScrW() / 2 - tw / 2 - 14
            draw.RoundedBox(4, x, y, tw + 28, 26, Color(0, 0, 0, 180 * alpha / 255))
            surface.SetDrawColor(tier.color.r, tier.color.g, tier.color.b, alpha)
            surface.DrawRect(x, y, 3, 26)
            draw.SimpleText(text, "DermaDefaultBold", ScrW() / 2, y + 13, ColorAlpha(tier.color, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            y = y + 30
        end
    end
end)
