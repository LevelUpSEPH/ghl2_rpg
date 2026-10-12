-- hlrpg/core/sh_assets.lua
-- Every ownable item. Common fields: name, desc, group, price, currency ("XP" or "TP"), unbuyable,
-- abilities = { { id = <key in HLRPG.Abilities (sh_abilities.lua)>, value = ... }, ... }
--   Suits:     model (a citizen-body playermodel: rebels, medics, Combine), hands, skin, headOffset (Vector)
--   Hats:      model, and placement on the head bone in PAC3's terms (copy the values from the PAC3 editor):
--              offset = Position, angle = Angles, scale = Size, stretch = Scale (Vector).
--              legacyPlacement = older hats tuned with the previous placement math.
--   Pets:      model (shop icon); evolutions live in sh_pets.lua
--   Modifiers: type = "modifier", scope (weapon class the abilities apply to, or nil for always), icon
--   Consumables: type = "consumable", consumable (key into HLRPG.Consumables), currency = "TP"
--   Features:  type = "feature", setting (client convar, on by default). Bought once, then switched
--              on/off by clicking it in the inventory.

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

    -- From the "Gordon Freeman Restored" Workshop pack (3320656757, see HLRPG.Config.WorkshopContent)
    ["suit_hev"] = {
        name = "HEV Suit",
        desc = "Mark IV Hazardous Environment Suit. Property of Black Mesa.",
        model = "models/gfreakman/gordonf.mdl",
        hands = "models/gfreakman/gordonf_hands.mdl",
        group = "Suits",
        price = 8000,
        currency = "XP",
        abilities = {
            { id = "bonus_armor", value = 100 },
            { id = "armor_regen", value = 5 }
        }
    },
    ["suit_refugee"] = {
        name = "Refugee",
        desc = "Hand-me-down clothes from the canals. Better than a citizen uniform.",
        model = "models/player/group02/male_04.mdl",
        group = "Suits",
        price = 1000,
        currency = "XP",
        abilities = { { id = "bonus_health", value = 10 } }
    },
    ["suit_rebel"] = {
        name = "Rebel",
        desc = "Resistance fatigues. Built to take a beating.",
        model = "models/player/group03/male_07.mdl",
        group = "Suits",
        price = 2000,
        currency = "XP",
        abilities = { { id = "bonus_health", value = 25 } }
    },
    ["suit_rebel_medic"] = {
        name = "Rebel Medic",
        desc = "Resistance field medic gear, stocked with supplies.",
        model = "models/player/group03m/male_07.mdl",
        group = "Suits",
        price = 4500,
        currency = "XP",
        abilities = { { id = "health_regen", value = 1 } }
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
        desc = "City security visor.",
        model = "models/nova/w_headgear.mdl",
        group = "Hats",
        type = "hat",
        price = 10000,
        currency = "XP",
        offset = Vector(0, 0, 0),
        angle = Angle(90, 0, 270),
        scale = 1.0,
        legacyPlacement = true,
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
        angle = Angle(0, 0, 0),
        legacyPlacement = true
    },
    ["hat_helibomb"] = {
        name = "Helicopter Bomb Hat",
        desc = "A helicopter bomb, worn on the head. Reward for the Revenge achievement.",
        model = "models/Combine_Helicopter/helicopter_bomb01.mdl",
        group = "Hats",
        type = "hat",
        price = 2500,
        currency = "XP",
        offset = Vector(4.8, 1.35, 0.065),
        angle = Angle(0, 0, 90),
        scale = 0.5,
        legacyPlacement = true,
        unbuyable = true,
        abilities = { { id = "death_explosion", value = 500 } }
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
        legacyPlacement = true,
        unbuyable = true,
        abilities = { { id = "second_wind" } }
    },

    ["hat_labpart"] = {
        name = "Lab Apparatus",
        desc = "Something Kleiner was going to need back.",
        model = "models/props_lab/labpart.mdl",
        group = "Hats",
        type = "hat",
        price = 2000,
        currency = "XP",
        offset = Vector(2.2175, -1.4668, -0.7342),
        angle = Angle(0, -80.6326, -0.5344),
        scale = 1,
        stretch = Vector(1.4, 1, 1),
        abilities = { { id = "combine_ball_chance", value = 1 } }
    },
    ["hat_trafficcone"] = {
        name = "Traffic Cone",
        desc = "Road work ahead.",
        model = "models/props_junk/trafficcone001a.mdl",
        group = "Hats",
        type = "hat",
        price = 1000,
        currency = "XP",
        offset = Vector(13.3, -0.6, -0.119),
        angle = Angle(90, 0, 0),
        scale = 1
    },
    ["hat_rollerspikes"] = {
        name = "Rollermine Spikes",
        desc = "A crown of Combine spikes.",
        model = "models/roller_spikes.mdl",
        group = "Hats",
        type = "hat",
        price = 3500,
        currency = "XP",
        offset = Vector(4.6174, 0, 0),
        angle = Angle(0, 0, 0),
        scale = 0.8,
        abilities = { { id = "shock_attacker", value = 30 } }
    },
    ["hat_breen_rings"] = {
        name = "Teleporter Halo",
        desc = "A shrunken ring from Breen's teleporter.",
        model = "models/props_combine/breentp_rings.mdl",
        group = "Hats",
        type = "hat",
        price = 5000,
        currency = "XP",
        offset = Vector(5.2987, 0, 0),
        angle = Angle(90, 0, 0),
        scale = 0.15,
        abilities = { { id = "fizzle_killer" } }
    },
    ["hat_breen_bust"] = {
        name = "Bust Fragment",
        desc = "A piece of the Administrator, worn with pride.",
        model = "models/props_combine/breenbust_chunk04.mdl",
        group = "Hats",
        type = "hat",
        price = 2500,
        currency = "XP",
        offset = Vector(-4.6553, 0.406, 0.0643),
        angle = Angle(0.0161, -89.6753, -89.8558),
        scale = 1,
        abilities = {
            { id = "fixed_max_health", value = 1 },
            { id = "bonus_armor", value = 200 },
            { id = "armor_shield" },
            { id = "armor_refill" },
            { id = "no_armor_regen" }
        }
    },
    -- New hats: placement is a rough first guess, to be tuned in the PAC3 editor
    ["hat_gnome"] = {
        name = "Gnome Chompski",
        desc = "He made it to space. Now he rides with you. Reward for Little Rocket Man.",
        model = "models/props_junk/gnome.mdl",
        group = "Hats",
        type = "hat",
        price = 5000,
        currency = "XP",
        offset = Vector(4, 0, 0),
        angle = Angle(0, 0, -90),
        scale = 0.6,
        unbuyable = true,
        abilities = { { id = "xp_bonus", value = 0.1 } }
    },
    ["hat_grub"] = {
        name = "Antlion Grub",
        desc = "A glowing grub that survived the purge. Reward for Get Some Grub.",
        model = "models/antlion_grub.mdl",
        group = "Hats",
        type = "hat",
        price = 5000,
        currency = "XP",
        offset = Vector(5, 0, 0),
        angle = Angle(0, 0, -90),
        scale = 0.5,
        unbuyable = true,
        abilities = { { id = "heal_aura", value = 1 } }
    },
    ["hat_bucket"] = {
        name = "Metal Bucket",
        desc = "Head protection, technically.",
        model = "models/props_junk/metalbucket01a.mdl",
        group = "Hats",
        type = "hat",
        price = 1500,
        currency = "XP",
        offset = Vector(6, 0, 0),
        angle = Angle(0, 0, 90),
        scale = 0.8,
        abilities = { { id = "bonus_armor", value = 25 } }
    },
    ["hat_flechette"] = {
        name = "Hunter Flechette",
        desc = "A flechette lodged in your skull. Somehow it helps you aim.",
        model = "models/weapons/hunter_flechette.mdl",
        group = "Hats",
        type = "hat",
        price = 4000,
        currency = "XP",
        offset = Vector(4, 0, 0),
        angle = Angle(0, 0, 0),
        scale = 1,
        abilities = { { id = "flechette_chance", value = 3 } }
    },

    ["upg_bhop"] = {
        name = "Bunny Hop",
        desc = "Hold jump to keep hopping. Click it in your inventory to toggle.",
        icon = "icon16/arrow_up.png",
        price = 2500, currency = "XP",
        group = "Permanent Upgrades",
        type = "feature", setting = "hlrpg_bhop",
        abilities = { { id = "auto_bhop" } }
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
        abilities = { { id = "pellet_multiplier", value = 2 } }
    },
    ["upg_dissolver_ar2"] = {
        name = "Dissolver",
        desc = "Pulse rounds sometimes dissolve what they hit. Reward for Atomizer.",
        icon = "icon16/weather_lightning.png",
        price = 6000, currency = "XP",
        group = "Permanent Upgrades",
        type = "modifier",
        scope = "weapon_ar2",
        unbuyable = true,
        abilities = { { id = "dissolve_chance", value = 0.5 } }
    },
    ["upg_croveline"] = {
        name = "Croveline",
        desc = "Right click with the crowbar to throw one.",
        icon = "icon16/wrench.png",
        price = 3500, currency = "XP",
        group = "Permanent Upgrades",
        type = "modifier",
        scope = "weapon_crowbar",
        abilities = { { id = "crowbar_throw", value = 100 } }
    },
    ["upg_jump_pack"] = {
        name = "Jump-Pack",
        desc = "Jump again in mid-air. Click it in your inventory to toggle.",
        icon = "icon16/control_eject.png",
        price = 4000, currency = "XP",
        group = "Permanent Upgrades",
        type = "feature", setting = "hlrpg_jump_pack",
        abilities = { { id = "double_jump", value = 260 } }
    },
    ["upg_jic_battery"] = {
        name = "JIC Battery",
        desc = "A just-in-case cell for the suit. Click it in your inventory to toggle.",
        icon = "icon16/lightning.png",
        price = 2000, currency = "XP",
        group = "Permanent Upgrades",
        type = "feature", setting = "hlrpg_jic_battery",
        abilities = { { id = "aux_efficiency", value = 0.5 } }
    },
    ["upg_acid_resistance"] = {
        name = "Acid-Resistance",
        desc = "Antivenom in the suit's med system. Click it in your inventory to toggle.",
        icon = "icon16/shield.png",
        price = 2500, currency = "XP",
        group = "Permanent Upgrades",
        type = "feature", setting = "hlrpg_acid_resistance",
        abilities = { { id = "poison_resistance" } }
    },
    ["upg_promised_stock"] = {
        name = "Promised Stock",
        desc = "Bigger pouches and extended magazines. Click it in your inventory to toggle.",
        icon = "icon16/box.png",
        price = 6000, currency = "XP",
        group = "Permanent Upgrades",
        type = "feature", setting = "hlrpg_promised_stock",
        abilities = { { id = "ammo_capacity", value = 0.5 } }
    }
}

-- Display name of an item ID ("" for none, the ID itself if the item no longer exists)
function HLRPG.GetItemName(itemID)
    if not itemID or itemID == "" then return "" end
    return HLRPG.Assets[itemID] and HLRPG.Assets[itemID].name or itemID
end
