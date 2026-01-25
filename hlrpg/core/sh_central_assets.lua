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
    ["suit_heavy"] = { 
        name = "HEV Suit", 
        model = "models/player/hev.mdl",
        hands = "models/weapons/c_arms_hev.mdl", -- ELLER BURAYA
        group = "Suits", 
        price = 10000, 
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
    ["perm_double_barrel"] = { 
        name = "Double Barrel", 
        desc = "Shotgun iki kat pellet sıkar.",
        price = 8000, currency = "XP", group = "Permanent Upgrades",
        modifier = "mod_double_pellet", modVal = 2
    },
}