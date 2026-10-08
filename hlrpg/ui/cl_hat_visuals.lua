-- hlrpg/ui/cl_hat_visuals.lua
-- Draws hats on players' heads. Hat abilities (e.g. vision) run through cl_abilities.lua.

local PlayerHats = {}

net.Receive("HLRPG_Sync_Hat", function()
    local ply = net.ReadEntity()
    local hatID = net.ReadString()
    if not IsValid(ply) then return end

    if PlayerHats[ply] and IsValid(PlayerHats[ply].Ent) then PlayerHats[ply].Ent:Remove() end
    PlayerHats[ply] = nil

    local asset = HLRPG.Assets[hatID]
    if not asset or not asset.model then return end

    local hat = ClientsideModel(asset.model)
    if IsValid(hat) then
        hat:SetNoDraw(true)
        PlayerHats[ply] = { Ent = hat, Asset = asset }
    end
end)

local function SetModelScale(ent, scale)
    local mat = Matrix()
    mat:Scale(Vector(scale, scale, scale))
    ent:EnableMatrix("RenderMultiply", mat)
end

hook.Add("PostPlayerDraw", "HLRPG_RenderHats", function(ply)
    local data = PlayerHats[ply]
    if not data or not IsValid(data.Ent) then return end
    if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then return end

    local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
    local matrix = bone and ply:GetBoneMatrix(bone)
    if not matrix then return end

    local pos, ang = matrix:GetTranslation(), matrix:GetAngles()
    local offset = data.Asset.offset or Vector(0, 0, 0)
    local angle = data.Asset.angle or Angle(0, 0, 0)

    local movePos = pos + ang:Forward() * offset.x + ang:Right() * offset.y + ang:Up() * offset.z
    ang:RotateAroundAxis(ang:Up(), angle.y)
    ang:RotateAroundAxis(ang:Right(), angle.p)
    ang:RotateAroundAxis(ang:Forward(), angle.r)

    SetModelScale(data.Ent, data.Asset.scale or 1.0)

    data.Ent:SetRenderOrigin(movePos)
    data.Ent:SetRenderAngles(ang)
    data.Ent:DrawModel()
end)
