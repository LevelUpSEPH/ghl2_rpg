-- hlrpg/ui/cl_pet_customizer.lua
-- Name/color editor for an owned pet, opened from the Player Hub inventory.

function HLRPG.OpenPetCustomizer(petID)
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 400)
    frame:SetTitle("Pet Customization")
    frame:Center()
    frame:MakePopup()

    local label = vgui.Create("DLabel", frame)
    label:SetText("Pet Name:")
    label:Dock(TOP)
    label:DockMargin(10, 10, 10, 0)

    local nameEntry = vgui.Create("DTextEntry", frame)
    nameEntry:Dock(TOP)
    nameEntry:DockMargin(10, 5, 10, 10)
    nameEntry:SetText(LocalPlayer():GetNWString("HLRPG_CustomName_" .. petID, "Pet"))

    local colorLabel = vgui.Create("DLabel", frame)
    colorLabel:SetText("Pet Color:")
    colorLabel:Dock(TOP)
    colorLabel:DockMargin(10, 10, 10, 0)

    local colorMixer = vgui.Create("DColorMixer", frame)
    colorMixer:Dock(FILL)
    colorMixer:SetPalette(true)
    colorMixer:SetAlphaBar(false)
    colorMixer:SetWangs(true)

    local saveBtn = vgui.Create("DButton", frame)
    saveBtn:SetText("SAVE & APPLY")
    saveBtn:Dock(BOTTOM)
    saveBtn:DockMargin(10, 10, 10, 10)
    saveBtn:SetHeight(40)
    saveBtn.DoClick = function()
        net.Start("HLRPG_UpdatePetCustomization")
            net.WriteString(petID)
            net.WriteString(nameEntry:GetValue())
            net.WriteColor(colorMixer:GetColor())
        net.SendToServer()

        frame:Close()
    end
end
