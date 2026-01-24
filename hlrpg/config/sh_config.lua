-- lua/hlrpg/config/sh_config.lua

HLRPG.Config = {}

HLRPG.Config.StartLevel = 1
HLRPG.Config.StartMoney = 0
HLRPG.Config.XPMultiplier = 1.0

HLRPG.Config.Models = {
    { name = "Rebel Male", model = "models/player/group03/male_07.mdl" },
    { name = "Rebel Female", model = "models/player/group03/female_08.mdl" }
}

HLRPG.Config.Hats = {
    { id = "none", name = "Şapka Yok" },
    { id = "hat_rollermine", name = "Rollermine Kaskı (Thorns)" },
    { id = "hat_combine", name = "Combine Vizörü (Wallhack)" }
}

HLRPG.Config.Suits = {
    { id = "none", name = "Sivil Kıyafet (Zırh Yok)", model = nil },
    { id = "suit_metrocop", name = "Metro Police Zırhı", model = "models/player/police.mdl" },
    { id = "suit_combine", name = "Combine Soldier Zırhı", model = "models/player/combine_soldier.mdl" },
    { id = "suit_elite", name = "Combine Elite (Beyaz)", model = "models/player/combine_super_soldier.mdl" },
    { id = "suit_prisonguard", name = "Nova Prospekt Gardiyanı", model = "models/player/combine_prison_soldier.mdl" }
}