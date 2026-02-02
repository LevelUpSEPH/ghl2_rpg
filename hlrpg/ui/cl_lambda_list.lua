-- cl_lambda_list.lua

net.Receive("HLRPG_OpenLambdaMenu", function()
    local foundLambdas = net.ReadTable()
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(350, 500)
    frame:SetTitle("")
    frame:Center()
    frame:MakePopup()
    
    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 15, 250))
        
        surface.SetDrawColor(255, 160, 0, 255)
        surface.DrawRect(0, 0, w, 30)
        draw.SimpleText("RESISTANCE CACHES", "DermaDefaultBold", 10, 15, Color(0, 0, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        draw.SimpleText("λ", "DermaLarge", w * 0.5, 45, Color(255, 160, 0, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(180, 100, 0, 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:DockMargin(10, 35, 10, 10)
    list:SetMultiSelect(false)
    list:SetHeaderHeight(25)
    
    list:AddColumn("IDENTIFIER")
    list:AddColumn("STATUS")
    
    local sortedData = {}
    if HLRPG and HLRPG.LambdaMap then
        local uniqueCheck = {}
        for _, id in pairs(HLRPG.LambdaMap) do
            if not uniqueCheck[id] then
                table.insert(sortedData, id)
                uniqueCheck[id] = true
            end
        end
    end

    table.sort(sortedData, function(a, b)
        local aNum = tonumber(a:match("%d+")) or 0
        local bNum = tonumber(b:match("%d+")) or 0
        return aNum < bNum
    end)

    for _, id in ipairs(sortedData) do
        local isFound = foundLambdas[id] == true
        local statusText = isFound and "LOCATED" or "MISSING"
        local line = list:AddLine(id, statusText)
        
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

    list.Paint = function(self, w, h)
        surface.SetDrawColor(10, 10, 10, 255)
        surface.DrawRect(0, 0, w, h)
    end

    for _, v in pairs(list.Columns) do
        v.Header.Paint = function(self, w, h)
            surface.SetDrawColor(35, 35, 35, 255)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(255, 160, 0, 100)
            surface.DrawRect(0, h - 1, w, 1)
        end
        v.Header:SetTextColor(Color(255, 160, 0))
    end
end)