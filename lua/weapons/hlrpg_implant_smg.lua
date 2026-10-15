-- weapons/hlrpg_implant_smg.lua
-- The Armory Uplink implant's active (sv_implants.lua): an SMG with infinite ammo whose fire rate comes from the
-- implant's rarity (the owner's HLRPG_ImplantFireRate, rounds per second). Handed out and taken back by the
-- implant; it can't be dropped or picked up by others.

SWEP.PrintName = "Armory SMG"
SWEP.Author = "HL2:RPG"
SWEP.Spawnable = false
SWEP.Slot = 2
SWEP.SlotPos = 9
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"
SWEP.UseHands = true
SWEP.HoldType = "smg"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local DAMAGE = 5       -- per bullet, like the regular SMG; damage stats and abilities apply on top
local SPREAD = 0.035

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local rate = math.max(owner:GetNWFloat("HLRPG_ImplantFireRate", 15), 1)
    self:SetNextPrimaryFire(CurTime() + 1 / rate)

    self:EmitSound("Weapon_SMG1.Single")
    self:ShootEffects()
    owner:FireBullets({
        Num = 1,
        Src = owner:GetShootPos(),
        Dir = owner:GetAimVector(),
        Spread = Vector(SPREAD, SPREAD, 0),
        Tracer = 2,
        TracerName = "AR2Tracer",
        Force = 2,
        Damage = DAMAGE,
        Attacker = owner,
    })
    owner:ViewPunch(Angle(math.Rand(-0.4, -0.1), math.Rand(-0.2, 0.2), 0))
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end

function SWEP:ShouldDropOnDie() return false end
