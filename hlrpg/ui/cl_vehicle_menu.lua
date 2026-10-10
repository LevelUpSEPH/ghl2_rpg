-- hlrpg/ui/cl_vehicle_menu.lua
-- Vehicle page of the TAB menu (server side: sv_vehicles.lua).

local menuFrame

local VEHICLE_NAMES = {
    ["prop_vehicle_airboat"] = "Airboat",
    ["prop_vehicle_jeep"] = "Scout Car",
    ["prop_vehicle_jeep_old"] = "Scout Car",
    ["prop_vehicle_jalopy"] = "Jalopy",
}

local function AddStatusLine(parent, label, value, valueColor)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:DockMargin(10, 8, 10, 0)
    row:SetTall(22)
    row.Paint = function(s, w, h)
        draw.SimpleText(label, "DermaDefaultBold", 0, h / 2, Color(180, 180, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(value, "DermaDefaultBold", w, h / 2, valueColor or color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

local function OpenVehicleMenu(supported, mapHasVehicles, spawningAllowed, ownedVehicle)
    if IsValid(menuFrame) then menuFrame:Remove() end

    local frame = vgui.Create("DFrame")
    menuFrame = frame
    frame:SetSize(340, 250)
    frame:SetTitle("VEHICLE")
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 240))
        draw.RoundedBox(0, 0, 0, w, 25, Color(255, 150, 0, 150))
    end

    local GREEN, RED = Color(120, 220, 120), Color(230, 90, 90)

    if not supported then
        AddStatusLine(frame, "Vehicles", "Need the Lambda gamemode", RED)
        return
    end

    local hasVehicle = IsValid(ownedVehicle)
    AddStatusLine(frame, "Vehicles on this map", mapHasVehicles and "Yes" or "No", mapHasVehicles and GREEN or RED)
    AddStatusLine(frame, "Spawning at checkpoints", spawningAllowed and "On" or "Paused here", spawningAllowed and GREEN or RED)
    AddStatusLine(frame, "Your vehicle", hasVehicle and (VEHICLE_NAMES[ownedVehicle:GetClass()] or ownedVehicle:GetClass()) or "None", hasVehicle and GREEN or nil)

    local info = vgui.Create("DLabel", frame)
    info:Dock(TOP)
    info:DockMargin(10, 10, 10, 0)
    info:SetTall(32)
    info:SetWrap(true)
    info:SetTextColor(Color(160, 160, 160))
    info:SetText(mapHasVehicles
        and "Vehicles appear at the checkpoint automatically. Respawn yours if it's stuck or left behind."
        or "This map has no vehicles.")

    local btn = vgui.Create("DButton", frame)
    btn:Dock(BOTTOM)
    btn:DockMargin(10, 10, 10, 10)
    btn:SetTall(40)
    btn:SetText("")
    btn:SetEnabled(hasVehicle)
    btn.Paint = function(s, w, h)
        local col = not hasVehicle and Color(45, 45, 45, 220) or (s:IsHovered() and Color(255, 150, 0, 220) or Color(60, 60, 60, 220))
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("RESPAWN MY VEHICLE", "HLRPG_HUD_Bold", w / 2, h / 2, hasVehicle and color_white or Color(120, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        net.Start("HLRPG_VehicleRespawn")
        net.SendToServer()
        frame:Close()
    end
end

net.Receive("HLRPG_OpenVehicleMenu", function()
    OpenVehicleMenu(net.ReadBool(), net.ReadBool(), net.ReadBool(), net.ReadEntity())
end)
