-- hlrpg/ui/cl_lambda_list.lua
-- Lambda cache checklist. Opened from the TAB menu or with !lambda.

local ACCENT = Color(255, 160, 0)

-- LambdaMap keys are "<map>_<entity>"; HL2 map names look like d1_canals_01a or d3_c17_06b
local function GetCacheList()
    local caches = {}
    for key, id in pairs(HLRPG.LambdaMap) do
        caches[#caches + 1] = { id = id, map = key:match("^(d%d_%w+_%d+%a?)_") or "?" }
    end

    table.sort(caches, function(a, b)
        return (tonumber(a.id:match("%d+")) or 0) < (tonumber(b.id:match("%d+")) or 0)
    end)
    return caches
end

local function StyleLine(line, isFound)
    line.Paint = function(self, w, h)
        if isFound then
            surface.SetDrawColor(40, 60, 40, 150)
        else
            surface.SetDrawColor(25, 25, 25, 200)
        end
        surface.DrawRect(0, 0, w, h - 1)

        if self:IsSelected() then
            surface.SetDrawColor(255, 160, 0, 40)
            surface.DrawRect(0, 0, w, h)
        end
    end

    local textColor = isFound and Color(150, 255, 150) or Color(180, 180, 180)
    for _, column in pairs(line.Columns) do
        column:SetContentAlignment(5)
        column:SetTextColor(textColor)
        column:SetFont("DermaDefaultBold")
    end
end

function HLRPG.OpenLambdaMenu(foundLambdas)
    local caches = GetCacheList()
    local foundCount = table.Count(foundLambdas)

    local frame = vgui.Create("DFrame")
    frame:SetSize(420, 540)
    frame:SetTitle("")
    frame:Center()
    frame:MakePopup()

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 15, 250))

        surface.SetDrawColor(ACCENT)
        surface.DrawRect(0, 0, w, 30)
        draw.SimpleText("RESISTANCE CACHES", "DermaDefaultBold", 10, 15, Color(0, 0, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        draw.SimpleText("λ", "DermaLarge", w * 0.5, 50, Color(255, 160, 0, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(foundCount .. " / " .. #caches .. " FOUND", "DermaDefaultBold", w * 0.5, 75, ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(180, 100, 0, 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:DockMargin(10, 65, 10, 10)
    list:SetMultiSelect(false)
    list:SetHeaderHeight(25)

    list:AddColumn("CACHE"):SetFixedWidth(70)
    list:AddColumn("MAP")
    list:AddColumn("STATUS"):SetFixedWidth(90)

    for _, cache in ipairs(caches) do
        local isFound = foundLambdas[cache.id] == true
        StyleLine(list:AddLine(cache.id, cache.map, isFound and "LOCATED" or "MISSING"), isFound)
    end

    list.Paint = function(self, w, h)
        surface.SetDrawColor(10, 10, 10, 255)
        surface.DrawRect(0, 0, w, h)
    end

    for _, column in pairs(list.Columns) do
        column.Header.Paint = function(self, w, h)
            surface.SetDrawColor(35, 35, 35, 255)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(255, 160, 0, 100)
            surface.DrawRect(0, h - 1, w, 1)
        end
        column.Header:SetTextColor(ACCENT)
    end
end

net.Receive("HLRPG_OpenLambdaMenu", function()
    HLRPG.OpenLambdaMenu(net.ReadTable())
end)
