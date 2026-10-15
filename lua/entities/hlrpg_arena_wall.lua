-- entities/hlrpg_arena_wall.lua
-- A box-shaped wall made at runtime (arenas, sv_arenas.lua). It can be invisible or drawn as a Combine force
-- field, and block only players, players and NPCs, or everything that traces (bullets too). It's shared, so
-- players' own movement prediction knows about it and walking into it is smooth.
-- Physics props are never blocked (it has no physics object); the box is axis-aligned (no rotation).

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Spawnable = false

-- What blocks: 0 players, 1 players and NPCs, 2 everything (also bullets and other traces); -1 nothing
ENT.BLOCK_PLAYERS, ENT.BLOCK_NPCS, ENT.BLOCK_ALL = 0, 1, 2

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "BoxMins")   -- relative to the entity's position
    self:NetworkVar("Vector", 1, "BoxMaxs")
    self:NetworkVar("Int", 0, "BlockMode")
    self:NetworkVar("Bool", 0, "ShowField")
end

-- Called on both realms whenever the box changes (the client gets it a moment after the entity)
function ENT:ApplyBounds()
    local mins, maxs = self:GetBoxMins(), self:GetBoxMaxs()
    if self.HLRPG_AppliedMins == mins and self.HLRPG_AppliedMaxs == maxs then return end
    self.HLRPG_AppliedMins, self.HLRPG_AppliedMaxs = mins, maxs

    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(mins, maxs)
    self:EnableCustomCollisions(true)
    if CLIENT then self:SetRenderBounds(mins, maxs) end
end

function ENT:Initialize()
    self:SetMoveType(MOVETYPE_NONE)
    self:DrawShadow(false)
    self:ApplyBounds()
end

function ENT:Think()
    self:ApplyBounds()
    if CLIENT then self:SetNextClientThink(CurTime() + 0.5) end
    self:NextThink(CurTime() + 0.5)
    return true
end

-- Movement and traces ask the wall whether they hit it. Player movement uses masks with CONTENTS_PLAYERCLIP,
-- NPC movement CONTENTS_MONSTERCLIP, bullets neither, so the mask says who is asking.
function ENT:TestCollision(startPos, delta, isBox, extents, mask)
    local mode = self:GetBlockMode()
    if mode < 0 then return end -- previews (rpg_wallcorner) block nothing
    local blocks = mode == self.BLOCK_ALL
        or bit.band(mask, CONTENTS_PLAYERCLIP) ~= 0
        or (mode == self.BLOCK_NPCS and bit.band(mask, CONTENTS_MONSTERCLIP) ~= 0)
    if not blocks then return end

    local mins, maxs = self:GetBoxMins(), self:GetBoxMaxs()
    if isBox then mins, maxs = mins - extents, maxs + extents end

    local hitPos, normal, fraction = util.IntersectRayWithOBB(startPos, delta, self:GetPos(), angle_zero, mins, maxs)
    if not hitPos then return end
    return { HitPos = hitPos, Normal = normal, Fraction = fraction }
end

if CLIENT then
    local fieldMat

    function ENT:DrawTranslucent()
        if not self:GetShowField() then return end

        if not fieldMat then
            fieldMat = Material("effects/com_shield003a")
            if fieldMat:IsError() then fieldMat = Material("models/wireframe") end
        end

        local pulse = 150 + math.sin(CurTime() * 3 + self:EntIndex()) * 40
        render.SetMaterial(fieldMat)
        render.DrawBox(self:GetPos(), angle_zero, self:GetBoxMins(), self:GetBoxMaxs(), Color(255, 255, 255, pulse))
        render.DrawBox(self:GetPos(), angle_zero, self:GetBoxMaxs(), self:GetBoxMins(), Color(255, 255, 255, pulse)) -- inside faces
    end

    function ENT:Draw() end
end
