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
    ["hat_metrocop"] = {
        name = "Metrocop Hat",
        model = "models/props_combine/combine_hat.mdl",
        group = "Hats",
        price = 1500,
        currency = "XP"
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