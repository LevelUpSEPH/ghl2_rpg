-- hlrpg/ui/cl_suit_visuals.lua
-- Suits are client-side models bonemerged onto the player. The real player model is made invisible
-- and a second copy of it ("fake head") shows only the head and neck on top of the suit.
-- This only works for suit models built on the citizen body (rebels, medics, Combine); character
-- playermodels like Breen or Kleiner have different proportions and weighting and won't line up.

local INVISIBLE_MAT = "models/effects/vol_light001"
local HIDDEN_SCALE = Vector(0.001, 0.001, 0.001)

local Visuals = {}

local function GetAllChildrenBones(ent, parentID)
    local children = {}

    for i = 0, ent:GetBoneCount() - 1 do
        if ent:GetBoneParent(i) == parentID then
            table.insert(children, i)
            for _, grandChild in ipairs(GetAllChildrenBones(ent, i)) do
                table.insert(children, grandChild)
            end
        end
    end

    return children
end

local function ResetEntityRender(ent)
    ent:SetMaterial("")
    ent:SetRenderMode(RENDERMODE_NORMAL)
    ent:SetColor(Color(255, 255, 255, 255))
end

local function RemoveVisuals(sid)
    local data = Visuals[sid]
    if not data then return end

    if IsValid(data.Suit) then data.Suit:Remove() end
    if IsValid(data.FakeHead) then data.FakeHead:Remove() end

    local ply = player.GetBySteamID(sid)
    if IsValid(ply) then
        ResetEntityRender(ply)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then ResetEntityRender(wep) end
    end

    Visuals[sid] = nil
end

local function CreateBonemerged(model, ply)
    local ent = ClientsideModel(model)
    if not IsValid(ent) then return nil end

    ent:SetPos(ply:GetPos())
    ent:SetParent(ply)
    ent:AddEffects(EF_BONEMERGE)
    return ent
end

-- The suit model, with its head hidden so the fake head shows the player's face instead
local function CreateSuitModel(ply, data, suitConfig)
    local suit = CreateBonemerged(suitConfig.model, ply)
    if not suit then return end
    suit:SetModelScale(1.01, 0)

    local headBone = suit:LookupBone("ValveBiped.Bip01_Head1")
    if headBone then
        suit:AddCallback("BuildBonePositions", function(ent)
            local m = IsValid(ent) and ent:GetBoneMatrix(headBone)
            if m then
                m:Scale(HIDDEN_SCALE)
                ent:SetBoneMatrix(headBone, m)
            end
        end)
    end

    data.Suit = suit
end

-- A copy of the player's own model with everything but the head and neck collapsed
local function CreateFakeHead(ply, data, suitConfig)
    local head = CreateBonemerged(ply:GetModel(), ply)
    if not head then return end

    local headBone = head:LookupBone("ValveBiped.Bip01_Head1")
    if not headBone then
        head:Remove()
        return
    end

    local visibleBones = { [headBone] = true }
    for _, id in ipairs(GetAllChildrenBones(head, headBone)) do visibleBones[id] = true end

    local neckBone = head:LookupBone("ValveBiped.Bip01_Neck1")
    if neckBone then
        visibleBones[neckBone] = true
        for _, id in ipairs(GetAllChildrenBones(head, neckBone)) do visibleBones[id] = true end
    end

    local headOffset = suitConfig.headOffset or Vector(0, 0, 0)

    head:AddCallback("BuildBonePositions", function(ent, nbones)
        if not IsValid(ent) or not IsValid(ply) then return end

        for i = 0, nbones - 1 do
            local m = ent:GetBoneMatrix(i)
            if not m then continue end

            if not visibleBones[i] then
                m:Scale(HIDDEN_SCALE)
                ent:SetBoneMatrix(i, m)
            elseif i == headBone and headOffset ~= Vector(0, 0, 0) then
                m:Translate(headOffset)
                ent:SetBoneMatrix(i, m)
            end
        end
    end)

    data.FakeHead = head
end

local function UpdatePlayerVisuals(ply, suitID)
    local sid = ply:SteamID()
    RemoveVisuals(sid)

    local suitConfig = HLRPG.Assets[suitID]
    if not suitConfig or suitConfig.group ~= "Suits" or not suitConfig.model then return end

    local data = {}
    Visuals[sid] = data

    CreateSuitModel(ply, data, suitConfig)
    CreateFakeHead(ply, data, suitConfig)
end

net.Receive("HLRPG_Sync_Suit", function()
    local ply = net.ReadEntity()
    local suitID = net.ReadString()
    if IsValid(ply) then UpdatePlayerVisuals(ply, suitID) end
end)

-- Keeps the real player model invisible (other code and respawns reset materials)
hook.Add("Think", "HLRPG_Global_Visual_Enforce", function()
    for sid, data in pairs(Visuals) do
        local ply = player.GetBySteamID(sid)
        if not IsValid(ply) or not ply:Alive() then
            RemoveVisuals(sid)
            continue
        end
        if ply:IsDormant() then continue end

        local inZombie = ply:GetNWBool("HLRPG_InZombieForm", false)
        if IsValid(data.Suit) then data.Suit:SetNoDraw(inZombie) end
        if IsValid(data.FakeHead) then data.FakeHead:SetNoDraw(inZombie) end

        if ply:GetMaterial() ~= INVISIBLE_MAT then ply:SetMaterial(INVISIBLE_MAT) end
        if inZombie then continue end

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            if wep:GetMaterial() == INVISIBLE_MAT then wep:SetMaterial("") end
            if wep:GetColor().a ~= 255 then
                wep:SetColor(Color(255, 255, 255, 255))
                wep:SetRenderMode(RENDERMODE_NORMAL)
            end
        end
    end
end)
