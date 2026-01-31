-- addons/halflife_rpg/lua/hlrpg/core/sh_central_assets.lua
HLRPG_Assets = HLRPG_Assets or {}

HLRPG_Assets = {
    ["suit_combine"] = { 
        name = "Combine Soldier", 
        model = "models/player/combine_soldier.mdl",
        hands = "models/weapons/c_arms_combine.mdl", -- ELLER BURAYA
        group = "Suits", 
        price = 5000, 
        currency = "XP" 
    },
    ["suit_combineelite"] = { 
        name = "Combine Elite", 
        model = "models/player/combine_super_soldier.mdl",
        hands = "models/weapons/c_arms_combine.mdl",
        group = "Suits", 
        price = 7500, 
        currency = "XP" 
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
    ["hat_metrocop"] = { 
        name = "Metrocop Helmet", 
        desc = "Şehir güvenliği vizörü. Wireframe görüşü sağlar.", 
        model = "models/nova/w_headgear.mdl",
        group = "Hats", 
        type = "hat",
        price = 10000, 
        currency = "XP",
        offset = Vector(0, 0, 0),
        angle = Angle(90, 0, 270),
        scale = 1.0,
        vision = "wireframe" 
    },
    ["hat_melon"] = { 
        name = "Melon Hat", 
        desc = "Klasik bir karpuz şapka.", 
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
        desc = "Kafa üstü helikopter bombası.", 
        model = "models/Combine_Helicopter/helicopter_bomb01.mdl", 
        group = "Hats", 
        type = "hat",
        price = 2500, 
        currency = "XP",
        offset = Vector(4.8, 1.35, 0.065),
        angle = Angle(0, 0, 90),
        scale = 0.5
    },
    ["hat_headcrab"] = { 
        name = "Headcrab Hat", 
        desc = "Get a second chance at life", 
        model = "models/nova/w_headcrab.mdl", 
        group = "Hats", 
        type = "hat",
        price = 3000, 
        currency = "XP",
        offset = Vector(0, 0, 0),
        angle = Angle(90, 0, -90),
        scale = 0.9,
        OnDeathPrevention = function(ply)
            HLRPG_StartZombiePilot(ply)
        end
    },
    ["upg_fire_smg"] = { 
        name = "Incendiary SMG", 
        desc = "SMG mermileri hedefini yakar.", 
        icon = "icon16/fire.png", 
        price = 3000, currency = "XP", 
        group = "Permanent Upgrades", 
        type = "modifier", 
        modID = "mod_fire_ammo", modVal = 30,
        scope = "weapon_smg1"
    },
    ["upg_splitter_shotgun"] = { 
        name = "Splitter Shotgun", 
        desc = "Pompalı saçma sayısını artırır.", 
        icon = "icon16/bomb.png", 
        price = 4500, currency = "XP", 
        group = "Permanent Upgrades", 
        type = "modifier", 
        modID = "mod_double_pellet", modVal = 6,
        scope = "weapon_shotgun"
    }
}