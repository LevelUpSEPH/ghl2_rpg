-- addons/halflife_rpg/lua/hlrpg/modules/cl_hat_visuals.lua
if not CLIENT then return end

local PlayerHats = {}

net.Receive("HLRPG_Sync_Hat", function()
    local ply = net.ReadEntity()
    local hatID = net.ReadString()
    if not IsValid(ply) then return end

    if PlayerHats[ply] and IsValid(PlayerHats[ply].Ent) then PlayerHats[ply].Ent:Remove() end

    if hatID == "none" or hatID == "" then 
        PlayerHats[ply] = nil 
        return 
    end

    local asset = HLRPG_Assets[hatID]
    if not asset or not asset.model then return end

    local hat = ClientsideModel(asset.model)
    if IsValid(hat) then
        hat:SetNoDraw(true)
        PlayerHats[ply] = { Ent = hat, Asset = asset }
    end
end)

local function UpdateHatScale(ent, scale)
    if not IsValid(ent) then return end
    local mat = Matrix()
    mat:Scale(Vector(scale, scale, scale))
    ent:EnableMatrix("RenderMultiply", mat)
end

-- 1. Şapka Modelini Çiz (Kafada dursun)
hook.Add("PostPlayerDraw", "HLRPG_RenderHats", function(ply)
    local data = PlayerHats[ply]
    if not data or not IsValid(data.Ent) then return end
    if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then return end

    local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
    if not bone then return end

    local matrix = ply:GetBoneMatrix(bone)
    if not matrix then return end

    local pos, ang = matrix:GetTranslation(), matrix:GetAngles()
    local offset = data.Asset.offset or Vector(0,0,0)
    local angle = data.Asset.angle or Angle(0,0,0)

    local movePos = pos + ang:Forward() * offset.x + ang:Right() * offset.y + ang:Up() * offset.z
    ang:RotateAroundAxis(ang:Up(), angle.y)
    ang:RotateAroundAxis(ang:Right(), angle.p)
    ang:RotateAroundAxis(ang:Forward(), angle.r)

    UpdateHatScale(data.Ent, data.Asset.scale or 1.0)

    data.Ent:SetRenderOrigin(movePos)
    data.Ent:SetRenderAngles(ang)
    data.Ent:DrawModel()
end)

hook.Add("RenderScreenspaceEffects", "HLRPG_ApplyVisionOverlay", function()
    local hatID = LocalPlayer():GetNWString("HLRPG_ActiveHat", "")
    local asset = HLRPG_Assets[hatID]

    if asset and asset.vision then
        local effect = HLRPG.HatEffects.Definitions[asset.vision]
        if effect and effect.OnRender then
            effect.OnRender()
        end
    end
end)

hook.Add("PreDrawHalos", "HLRPG_ApplyVisionWorld", function()
    local hatID = LocalPlayer():GetNWString("HLRPG_ActiveHat", "")
    local asset = HLRPG_Assets[hatID]

    if asset and asset.vision then
        local effect = HLRPG.HatEffects.Definitions[asset.vision]
        if effect and effect.OnDraw then
            effect.OnDraw()
        end
    end
end)

hook.Add("HUDPaint", "HLRPG_ApplyVisionUI", function()
    local hatID = LocalPlayer():GetNWString("HLRPG_ActiveHat", "")
    local asset = HLRPG_Assets[hatID]

    if asset and asset.vision then
        local effect = HLRPG.HatEffects.Definitions[asset.vision]
        if effect and effect.OnUI then
            effect.OnUI()
        end
    end
end)