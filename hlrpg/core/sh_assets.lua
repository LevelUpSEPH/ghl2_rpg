-- hlrpg/core/sh_assets.lua
-- Every ownable item. Common fields: name, desc, group, price, currency ("XP" or "TP"), unbuyable,
-- abilities = { { id = <key in HLRPG.Abilities (sh_abilities.lua)>, value = ... }, ... }
--   Suits:     model, hands, skin, headOffset (Vector),
--              fullBody (draw the whole suit including its head instead of the player's head)
--   Hats:      model, offset, angle, scale
--   Pets:      model (shop icon); evolutions live in sh_pets.lua
--   Modifiers: type = "modifier", scope (weapon class the abilities apply to, or nil for always), icon
--   Consumables: type = "consumable", consumable (key into HLRPG.Consumables), currency = "TP"

HLRPG.Assets = {
    ["con_medkit"] = {
        name = "Medkit",
        desc = "Restores half of your max health.",
        model = "models/items/healthkit.mdl",
        group = "Temporary Upgrades",
        type = "consumable", consumable = "medkit",
        price = 30, currency = "TP"
    },
    ["con_armor"] = {
        name = "Armor Battery",
        desc = "Restores 50 armor.",
        model = "models/items/battery.mdl",
        group = "Temporary Upgrades",
        type = "consumable", consumable = "armor",
        price = 30, currency = "TP"
    },
    ["con_full_ammo"] = {
        name = "Full Ammo",
        desc = "Refills every weapon you carry to max ammo.",
        model = "models/items/ammocrate_smg1.mdl",
        group = "Temporary Upgrades",
        type = "consumable", consumable = "full_ammo",
        price = 75, currency = "TP"
    },
    ["con_pet_xp"] = {
        name = "Pet Treat",
        desc = "Permanent: gives your active pet 10 XP (1 XP per TP spent).",
        model = "models/props_junk/garbage_metalcan001a.mdl",
        group = "Temporary Upgrades",
        type = "consumable", consumable = "pet_xp",
        price = 10, currency = "TP"
    },

    ["suit_metrocop"] = {
        name = "Metro Police",
        desc = "Standard Civil Protection gear.",
        model = "models/player/police.mdl",
        hands = "models/weapons/c_arms_combine.mdl",
        group = "Suits",
        unbuyable = true,
        abilities = { { id = "bonus_armor", value = 25 } }
    },
    ["suit_combine"] = {
        name = "Combine Soldier",
        desc = "Overwatch infantry armor.",
        model = "models/player/combine_soldier.mdl",
        hands = "models/weapons/c_arms_combine.mdl",
        group = "Suits",
        price = 5000,
        currency = "XP",
        abilities = { { id = "bonus_armor", value = 50 } }
    },
    ["suit_combineprison"] = {
        name = "Combine Prison Guard",
        desc = "Nova Prospekt issue, sealed against toxins.",
        model = "models/player/combine_soldier_prisonguard.mdl",
        hands = "models/weapons/c_arms_combine.mdl",
        group = "Suits",
        unbuyable = true,
        abilities = {
            { id = "bonus_armor", value = 25 },
            { id = "poison_immunity" }
        }
    },
    ["suit_combineelite"] = {
        name = "Combine Elite",
        desc = "Overwatch elite armor with self-repairing plating.",
        model = "models/player/combine_super_soldier.mdl",
        hands = "models/weapons/c_arms_combine.mdl",
        group = "Suits",
        price = 7500,
        currency = "XP",
        abilities = {
            { id = "bonus_armor", value = 50 },
            { id = "armor_regen", value = 1 }
        }
    },

    ["suit_zombie"] = {
        name = "Zombie",
        desc = "Smells right. The dead think you're one of them.",
        model = "models/player/zombie_classic.mdl",
        fullBody = true,
        group = "Suits",
        price = 4000,
        currency = "XP",
        abilities = {
            { id = "undead_disguise" },
            { id = "poison_immunity" }
        }
    },
    ["suit_zombie_fast"] = {
        name = "Fast Zombie",
        desc = "Feeds on whatever it hits.",
        model = "models/player/zombie_fast.mdl",
        fullBody = true,
        group = "Suits",
        price = 6000,
        currency = "XP",
        abilities = {
            { id = "undead_disguise" },
            { id = "lifesteal", value = 0.1 }
        }
    },
    ["suit_zombine"] = {
        name = "Zombine",
        desc = "A zombified Overwatch soldier. Still wearing the armor.",
        model = "models/player/zombie_soldier.mdl",
        fullBody = true,
        group = "Suits",
        price = 8000,
        currency = "XP",
        abilities = {
            { id = "undead_disguise" },
            { id = "bonus_health", value = 50 },
            { id = "health_regen", value = 1 }
        }
    },

    ["pet_headcrab"] = {
        name = "Headcrab Pet",
        model = "models/headcrab.mdl",
        group = "Pets",
        price = 2000,
        currency = "XP"
    },
    ["pet_antlion"] = {
        name = "Antlion Pet",
        model = "models/antlion.mdl",
        group = "Pets",
        price = 4000,
        currency = "XP"
    },
    ["pet_rollermine"] = {
        name = "Rollermine Pet",
        model = "models/roller.mdl",
        group = "Pets",
        price = 3500,
        currency = "XP"
    },
    ["pet_vortigaunt"] = {
        name = "Vortigaunt Pet",
        model = "models/vortigaunt.mdl",
        group = "Pets",
        unbuyable = true
    },

    ["hat_metrocop"] = {
        name = "Metrocop Helmet",
        desc = "City security visor.",
        model = "models/nova/w_headgear.mdl",
        group = "Hats",
        type = "hat",
        price = 10000,
        currency = "XP",
        offset = Vector(0, 0, 0),
        angle = Angle(90, 0, 270),
        scale = 1.0,
        abilities = { { id = "combine_vision" } }
    },
    ["hat_melon"] = {
        name = "Melon Hat",
        desc = "A classic watermelon hat.",
        model = "models/props_junk/watermelon01.mdl",
        group = "Hats",
        type = "hat",
        price = 1500,
        currency = "XP",
        offset = Vector(5, 0, 0),
        angle = Angle(0, 0, 0)
    },
    ["hat_helibomb"] = {
        name = "Helicopter Bomb Hat",
        desc = "A helicopter bomb, worn on the head.",
        model = "models/Combine_Helicopter/helicopter_bomb01.mdl",
        group = "Hats",
        type = "hat",
        price = 2500,
        currency = "XP",
        offset = Vector(4.8, 1.35, 0.065),
        angle = Angle(0, 0, 90),
        scale = 0.5,
        unbuyable = true
    },
    ["hat_headcrab"] = {
        name = "Headcrab Hat",
        desc = "Get a second chance at life.",
        model = "models/nova/w_headcrab.mdl",
        group = "Hats",
        type = "hat",
        price = 3000,
        currency = "XP",
        offset = Vector(0, 0, 0),
        angle = Angle(90, 0, -90),
        scale = 0.9,
        abilities = { { id = "second_wind" } }
    },

    ["upg_fire_smg"] = {
        name = "Incendiary SMG",
        desc = "SMG rounds burn.",
        icon = "icon16/fire.png",
        price = 3000, currency = "XP",
        group = "Permanent Upgrades",
        type = "modifier",
        scope = "weapon_smg1",
        abilities = { { id = "incendiary_rounds", value = 30 } }
    },
    ["upg_splitter_shotgun"] = {
        name = "Splitter Shotgun",
        desc = "Shotgun shells split into more pellets.",
        icon = "icon16/bomb.png",
        price = 4500, currency = "XP",
        group = "Permanent Upgrades",
        type = "modifier",
        scope = "weapon_shotgun",
        abilities = { { id = "pellet_multiplier", value = 6 } }
    }
}
