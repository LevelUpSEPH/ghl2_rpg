-- cl_pet_customizer.lua
function HLRPG_OpenPetCustomizer(petID)
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 400)
    frame:SetTitle("Pet Özelleştirme")
    frame:Center()
    frame:MakePopup()

    local label = vgui.Create("DLabel", frame)
    label:SetText("Pet İsmi:")
    label:Dock(TOP)
    label:DockMargin(10, 10, 10, 0)

    local nameEntry = vgui.Create("DTextEntry", frame)
    nameEntry:Dock(TOP)
    nameEntry:DockMargin(10, 5, 10, 10)
    nameEntry:SetText(LocalPlayer():GetPData("HLRPG_PetName_" .. petID, "Pet"))

    local colorLabel = vgui.Create("DLabel", frame)
    colorLabel:SetText("Pet Rengi:")
    colorLabel:Dock(TOP)
    colorLabel:DockMargin(10, 10, 10, 0)

    local colorMixer = vgui.Create("DColorMixer", frame)
    colorMixer:Dock(FILL)
    colorMixer:SetPalette(true)
    colorMixer:SetAlphaBar(false)
    colorMixer:SetWangs(true)

    local saveBtn = vgui.Create("DButton", frame)
    saveBtn:SetText("KAYDET VE UYGULA")
    saveBtn:Dock(BOTTOM)
    saveBtn:DockMargin(10, 10, 10, 10)
    saveBtn:SetHeight(40)
    saveBtn.DoClick = function()
        local newName = nameEntry:GetValue()
        local newColor = colorMixer:GetColor()
        
        net.Start("HLRPG_UpdatePetCustomization")
            net.WriteString(petID)
            net.WriteString(newName)
            net.WriteColor(newColor)
        net.SendToServer()
        
        frame:Close()
    end
end