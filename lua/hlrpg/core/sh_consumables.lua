-- hlrpg/core/sh_consumables.lua
-- Consumables are bought with Temp Points (TP) and used immediately; they never enter the inventory.
-- Shop entries live in sh_assets.lua (type = "consumable", consumable = <key below>).
--   CanUse(ply) -> true, or false and a reason. Checked before the player is charged.
--   OnUse(ply, item) where item is the shop entry from HLRPG.Assets

-- TP earned per point of base kill XP (before level scaling), so prices mean the same on every
-- difficulty. A Combine Soldier (25 base XP) gives 5 TP. TP resets when the player rejoins.
HLRPG.TempPointsPerXP = 0.2

local MEDKIT_HEAL_FRACTION = 0.5
local ARMOR_AMOUNT = 50

local function GetCarriedAmmoTypes(ply)
    local types = {}
    for _, wep in ipairs(ply:GetWeapons()) do
        local primary, secondary = wep:GetPrimaryAmmoType(), wep:GetSecondaryAmmoType()
        if primary >= 0 then types[primary] = true end
        if secondary >= 0 then types[secondary] = true end
    end
    return types
end

local DEF = {}

DEF["medkit"] = {
    CanUse = function(ply)
        if ply:Health() >= ply:GetMaxHealth() then return false, "You're already at full health." end
        return true
    end,
    OnUse = function(ply)
        local heal = math.ceil(ply:GetMaxHealth() * MEDKIT_HEAL_FRACTION)
        ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + heal))
        ply:EmitSound("items/smallmedkit1.wav")
    end
}

DEF["armor"] = {
    CanUse = function(ply)
        if ply:Armor() >= ply:GetMaxArmor() then return false, "Your armor is already full." end
        return true
    end,
    OnUse = function(ply)
        ply:SetArmor(math.min(ply:GetMaxArmor(), ply:Armor() + ARMOR_AMOUNT))
        ply:EmitSound("items/battery_pickup.wav")
    end
}

DEF["full_ammo"] = {
    CanUse = function(ply)
        for ammoID in pairs(GetCarriedAmmoTypes(ply)) do
            if ply:GetAmmoCount(ammoID) < game.GetAmmoMax(ammoID) then return true end
        end
        return false, "Your ammo is already full."
    end,
    OnUse = function(ply)
        for ammoID in pairs(GetCarriedAmmoTypes(ply)) do
            ply:SetAmmo(game.GetAmmoMax(ammoID), ammoID)
        end
        ply:EmitSound("items/ammo_pickup.wav")
    end
}

-- Permanent: converts the item's TP price 1:1 into XP for the active pet
DEF["pet_xp"] = {
    CanUse = function(ply)
        if ply:GetNWString("HLRPG_ActivePet", "none") == "none" then return false, "You need an active pet." end
        return true
    end,
    OnUse = function(ply, item)
        local amount = item.price

        ply:ChatPrint("[PET] +" .. amount .. " pet XP")
        HLRPG.AddPetXP(ply, ply:GetNWString("HLRPG_ActivePet", "none"), amount)
    end
}

HLRPG.Consumables = DEF
