-- lua/hlrpg/config/sh_config.lua

HLRPG.Config = {}

HLRPG.Config.StartLevel = 1
HLRPG.Config.StartMoney = 0
HLRPG.Config.XPMultiplier = 1.0

HLRPG.Config.Models = {
    { name = "Rebel Male", model = "models/player/group01/male_02.mdl" },
    { name = "Rebel Male", model = "models/player/group01/male_04.mdl" },
    { name = "Rebel Male", model = "models/player/group01/male_07.mdl" },
    { name = "Rebel Male", model = "models/player/group01/male_09.mdl" },
    { name = "Rebel Female", model = "models/player/group01/female_01.mdl" },
}

HLRPG.Config.Hats = {
    { id = "none", name = "Şapka Yok" },
    { id = "hat_rollermine", name = "Rollermine Kaskı (Thorns)" },
    { id = "hat_combine", name = "Combine Vizörü (Wallhack)" }
}

HLRPG.Config.Suits = {
    { 
        id = "none", 
        name = "Sivil Kıyafet", 
        model = nil,
        hands = "models/weapons/c_arms_citizen.mdl"
    },
    { 
        id = "suit_metrocop", 
        name = "Metro Police", 
        model = "models/player/police.mdl",
        hands = "models/weapons/c_arms_combine.mdl",
        head_offset = Vector(0, 0, 0) -- Tam oturuyor, ayara gerek yok
    },
    { 
        id = "suit_combine", 
        name = "Combine Soldier", 
        model = "models/player/combine_soldier.mdl",
        hands = "models/weapons/c_arms_combine.mdl",
        head_offset = Vector(0, 0, 0)
    },
    {
        id = "suit_combineprison", 
        name = "Combine Prison Guard", 
        model = "models/player/combine_soldier_prisonguard.mdl",
        hands = "models/weapons/c_arms_combine.mdl",
        head_offset = Vector(0, 0, 0)
    },
    {
        id = "suit_combineelite", 
        name = "Combine Elite", 
        model = "models/player/combine_super_soldier.mdl",
        hands = "models/weapons/c_arms_combine.mdl",
        head_offset = Vector(0, 0, 0)
    }
}