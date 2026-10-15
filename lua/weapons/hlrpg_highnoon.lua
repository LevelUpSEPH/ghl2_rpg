-- weapons/hlrpg_highnoon.lua
-- Overwatch Optics' active, "High Noon" (sv_implants.lua): a revolver that shoots by itself. Every SHOT_INTERVAL
-- it fires straight at the head of the visible enemy nearest the crosshair, without moving the player's view,
-- until SHOTS are spent (then the implant ends it) or the active's time runs out. Targets in its sights are
-- marked on screen.

SWEP.PrintName = "High Noon"
SWEP.Author = "HL2:RPG"
SWEP.Spawnable = false
SWEP.Slot = 1
SWEP.SlotPos = 9
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.WorldModel = "models/weapons/w_357.mdl"
SWEP.UseHands = true
SWEP.HoldType = "revolver"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local SHOTS = 6
local SHOT_INTERVAL = 0.13
local FIRST_SHOT_DELAY = 0.35 -- a moment to see the marks before it starts
local DAMAGE = 75             -- per shot, before headshot, level and damage bonuses
local RANGE, FOV = 2500, 70   -- how far and how far off the crosshair it will shoot

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "ShotsFired")
    self:NetworkVar("Float", 0, "NextAutoShot")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
    self:SetShotsFired(0)
    self:SetNextAutoShot(CurTime() + FIRST_SHOT_DELAY)
    return true
end

local function HeadPos(ent)
    local bone = ent:LookupBone("ValveBiped.Bip01_Head1")
    if bone then
        local pos = ent:GetBonePosition(bone)
        if pos then return pos end
    end
    return ent:WorldSpaceCenter() + Vector(0, 0, ent:OBBMaxs().z * 0.3)
end

-- Visible enemies in front of the owner, nearest the crosshair first: { { ent, head } }
local function FindTargets(owner)
    local eye, forward = owner:EyePos(), owner:GetAimVector()
    local minDot = math.cos(math.rad(FOV))
    local found = {}
    for _, ent in ipairs(ents.FindInSphere(eye, RANGE)) do
        if ent:IsNPC() and ent:Health() > 0 and not HLRPG.FriendlyNPCs[ent:GetClass()] and not ent:GetNWBool("HLRPG_ISPET", false) then
            local head = HeadPos(ent)
            local dot = (head - eye):GetNormalized():Dot(forward)
            if dot > minDot then
                local tr = util.TraceLine({ start = eye, endpos = head, filter = owner, mask = MASK_SHOT })
                if tr.Entity == ent or tr.Fraction > 0.98 then found[#found + 1] = { ent = ent, head = head, dot = dot } end
            end
        end
    end
    table.sort(found, function(a, b) return a.dot > b.dot end)
    return found
end

function SWEP:Think()
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or self:GetShotsFired() >= SHOTS or CurTime() < self:GetNextAutoShot() then return end

    local target = FindTargets(owner)[1]
    if not target then return end

    local src = owner:GetShootPos()
    owner:FireBullets({
        Num = 1,
        Src = src,
        Dir = (target.head - src):GetNormalized(),
        Spread = vector_origin,
        Tracer = 1,
        Force = 8,
        Damage = DAMAGE,
        Attacker = owner,
    })
    self:EmitSound("Weapon_357.Single")
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    owner:SetAnimation(PLAYER_ATTACK1)
    owner:ViewPunch(Angle(-1.5, 0, 0))

    self:SetShotsFired(self:GetShotsFired() + 1)
    self:SetNextAutoShot(CurTime() + SHOT_INTERVAL)
    if self:GetShotsFired() >= SHOTS then
        timer.Simple(0.4, function()
            if IsValid(owner) and HLRPG.StopImplantActive then HLRPG.StopImplantActive(owner) end
        end)
    end
end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end
function SWEP:ShouldDropOnDie() return false end

if CLIENT then
    -- Red marks on the enemies it would shoot (the first one brightest), and the shots left
    function SWEP:DrawHUD()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local left = SHOTS - self:GetShotsFired()
        local pulse = 6 + math.abs(math.sin(CurTime() * 10)) * 4

        for i, target in ipairs(FindTargets(owner)) do
            if i > left then break end
            local s = target.head:ToScreen()
            if s.visible then
                local alpha = i == 1 and 255 or 140
                surface.DrawCircle(s.x, s.y, 12 + pulse, 255, 40, 30, alpha)
                surface.DrawCircle(s.x, s.y, 4, 255, 40, 30, alpha)
            end
        end

        draw.SimpleText(string.rep("|", left), "DermaLarge", ScrW() / 2, ScrH() / 2 + 60, Color(255, 60, 40, 230), TEXT_ALIGN_CENTER)
    end
end
