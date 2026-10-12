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

-- scale is PAC3's "Size" (uniform), stretch its "Scale" (per axis)
local function SetModelScale(ent, scale, stretch)
    local mat = Matrix()
    mat:Scale((stretch or Vector(1, 1, 1)) * scale)
    ent:EnableMatrix("RenderMultiply", mat)
end

-- Where the hat goes relative to the head bone. offset/angle use PAC3's convention (LocalToWorld), so
-- values can be copied straight from the PAC3 editor. legacyPlacement hats were tuned with older math.
local function GetHatTransform(asset, bonePos, boneAng)
    local offset = asset.offset or Vector(0, 0, 0)
    local angle = asset.angle or Angle(0, 0, 0)

    if not asset.legacyPlacement then
        return LocalToWorld(offset, angle, bonePos, boneAng)
    end

    local pos = bonePos + boneAng:Forward() * offset.x + boneAng:Right() * offset.y + boneAng:Up() * offset.z
    local ang = Angle(boneAng)
    ang:RotateAroundAxis(ang:Up(), angle.y)
    ang:RotateAroundAxis(ang:Right(), angle.p)
    ang:RotateAroundAxis(ang:Forward(), angle.r)
    return pos, ang
end

hook.Add("PostPlayerDraw", "HLRPG_RenderHats", function(ply)
    local data = PlayerHats[ply]
    if not data or not IsValid(data.Ent) then return end
    if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then return end

    -- A suitHelmet hat on a suit with a helmet shows the suit's own helmet instead (cl_suit_visuals.lua)
    local suit = HLRPG.Assets[ply:GetNWString("HLRPG_ActiveSuit", "none")]
    if data.Asset.suitHelmet and suit and suit.helmet then return end

    local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
    local matrix = bone and ply:GetBoneMatrix(bone)
    if not matrix then return end

    local pos, ang = GetHatTransform(data.Asset, matrix:GetTranslation(), matrix:GetAngles())

    SetModelScale(data.Ent, data.Asset.scale or 1.0, data.Asset.stretch)

    data.Ent:SetRenderOrigin(pos)
    data.Ent:SetRenderAngles(ang)
    data.Ent:DrawModel()
end)
