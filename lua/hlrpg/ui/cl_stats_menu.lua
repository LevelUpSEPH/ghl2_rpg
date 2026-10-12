-- hlrpg/ui/cl_stats_menu.lua
-- Stats page of the TAB menu: spend points, see milestones, reset (core/sh_stats.lua, modules/sv_stats.lua).

local ACCENT = Color(255, 180, 0)
local DIM = Color(120, 120, 120)
local CARD_H = 92
local MILESTONE_W, MILESTONE_GAP = 130, 8

local menuFrame

-- One-line description of a list of abilities, values multiplied by `scale`
local function DescribeAbilityList(abilities, scale)
    local lines = {}
    for _, ability in ipairs(abilities) do
        local def = HLRPG.Abilities[ability.id]
        if def and def.Describe then lines[#lines + 1] = def.Describe((ability.value or 0) * scale) end
    end
    return table.concat(lines, "  •  ")
end

-- What the stat's points give right now, or what one point gives if none are spent
local function DescribeStat(stat, points)
    return (points > 0 and "" or "Per point: ") .. DescribeAbilityList(stat.perPoint, math.max(points, 1))
end

-- A box per milestone ("5 · Vampirism"), filled once reached; hover for what it does
local function AddMilestoneBoxes(card, stat, x, y)
    local ply = LocalPlayer()

    for i, threshold in ipairs(HLRPG.GetStatMilestoneThresholds(stat)) do
        local milestone = stat.milestones[threshold]

        local box = vgui.Create("DPanel", card)
        box:SetPos(x + (i - 1) * (MILESTONE_W + MILESTONE_GAP), y)
        box:SetSize(MILESTONE_W, 20)
        box:SetTooltip(milestone.name .. " (" .. threshold .. " points): " .. DescribeAbilityList(milestone.abilities or {}, 1))
        box.Paint = function(s, w, h)
            local reached = HLRPG.GetStatPoints(ply, stat.id) >= threshold
            draw.RoundedBox(3, 0, 0, w, h, reached and stat.color or Color(30, 30, 30))
            surface.SetDrawColor(stat.color)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(threshold .. " · " .. milestone.name, "DermaDefaultBold", w / 2, h / 2, reached and color_white or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

-- "N more to <next milestone>", or that every milestone is unlocked
local function DescribeNextMilestone(stat, points)
    for _, threshold in ipairs(HLRPG.GetStatMilestoneThresholds(stat)) do
        if points < threshold then
            return (threshold - points) .. " more point(s) to " .. stat.milestones[threshold].name
        end
    end
    return "All milestones unlocked"
end

local function AddStatCard(list, stat)
    local ply = LocalPlayer()

    local card = list:Add("DPanel")
    card:Dock(TOP)
    card:DockMargin(10, 10, 10, 0)
    card:SetTall(CARD_H)
    card.Paint = function(s, w, h)
        local points = HLRPG.GetStatPoints(ply, stat.id)

        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 240))
        surface.SetDrawColor(stat.color)
        surface.DrawRect(0, 0, 4, h)

        draw.SimpleText(stat.name, "DermaLarge", 16, 10, stat.color)
        draw.SimpleText(points .. " pts", "HLRPG_HUD_Bold", 16, 46, color_white)

        draw.SimpleText(DescribeStat(stat, points), "DermaDefault", 120, 14, Color(200, 200, 200))

        draw.SimpleText(DescribeNextMilestone(stat, points), "DermaDefault", 120, 68, DIM)
    end

    AddMilestoneBoxes(card, stat, 120, 38)

    local plus = vgui.Create("DButton", card)
    plus:SetSize(48, 48)
    plus:SetText("")
    plus.Think = function(s)
        s:SetPos(s:GetParent():GetWide() - 60, (CARD_H - 48) / 2)
        s:SetEnabled(HLRPG.GetFreeStatPoints(ply) > 0)
    end
    plus.Paint = function(s, w, h)
        local enabled = s:IsEnabled()
        draw.RoundedBox(4, 0, 0, w, h, enabled and (s:IsHovered() and stat.color or Color(60, 60, 60)) or Color(35, 35, 35))
        draw.SimpleText("+", "DermaLarge", w / 2, h / 2, enabled and color_white or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    plus.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        net.Start("HLRPG_StatSpend")
            net.WriteString(stat.id)
        net.SendToServer()
    end
end

local function AddResetButton(frame)
    local ply = LocalPlayer()

    local reset = vgui.Create("DButton", frame)
    reset:Dock(BOTTOM)
    reset:DockMargin(10, 10, 10, 10)
    reset:SetTall(36)
    reset:SetText("")
    reset.Think = function(s) s:SetEnabled(HLRPG.GetSpentStatPoints(ply) > 0) end
    reset.Paint = function(s, w, h)
        local enabled = s:IsEnabled()
        draw.RoundedBox(4, 0, 0, w, h, enabled and s:IsHovered() and Color(180, 60, 60) or Color(50, 50, 50))
        draw.SimpleText("RESET ALL POINTS (" .. string.Comma(HLRPG.StatResetCost) .. " XP)", "HLRPG_HUD_Bold", w / 2, h / 2, enabled and color_white or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    reset.DoClick = function()
        Derma_Query("Refund all stat points for " .. string.Comma(HLRPG.StatResetCost) .. " XP?", "Reset stats",
            "Reset", function()
                net.Start("HLRPG_StatReset")
                net.SendToServer()
            end,
            "Cancel")
    end
end

function HLRPG.OpenStatsMenu()
    if IsValid(menuFrame) then menuFrame:Remove() end

    local ply = LocalPlayer()
    local frame = vgui.Create("DFrame")
    menuFrame = frame
    frame:SetSize(640, 40 + 52 + #HLRPG.Stats * (CARD_H + 10) + 66)
    frame:SetTitle("STATS")
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 25, 245))
        draw.RoundedBox(0, 0, 0, w, 25, Color(255, 150, 0, 150))

        local free = HLRPG.GetFreeStatPoints(ply)
        draw.SimpleText(free .. " point" .. (free == 1 and "" or "s") .. " to spend", "DermaLarge", 16, 34, free > 0 and ACCENT or DIM)
        draw.SimpleText("1 point per level  •  hover a milestone to see what it does", "DermaDefault", w - 16, 46, DIM, TEXT_ALIGN_RIGHT)
    end

    AddResetButton(frame)

    local list = vgui.Create("DPanel", frame)
    list:Dock(FILL)
    list:DockMargin(0, 44, 0, 0)
    list.Paint = nil
    list.Add = function(s, class) return vgui.Create(class, s) end

    for _, stat in ipairs(HLRPG.Stats) do
        AddStatCard(list, stat)
    end
end
