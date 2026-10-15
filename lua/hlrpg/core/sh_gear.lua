-- hlrpg/core/sh_gear.lua
-- Loot: generated gear items (sv_gear.lua) for three slots. Every item has a rarity and an item level (from the
-- enemy that dropped it).
--   Gloves and chest rigs: random flat stats (more and stronger lines with rarity).
--   Implants: one of a fixed set of types (G.Implants), each with its own passive and/or active ability; rarity
--     scales its values, durations and cooldown. Each implant has a neon colour the wearer glows in while its
--     active runs (sv_implants.lua, cl_implants.lua).
-- Everything gear does is an ability from sh_abilities.lua, so it needs no combat code of its own.
--
-- Items (saved per player):
--   { uid = "g12", slot = "gloves", name = "...", rarity = 3, ilvl = 24, stats = { { stat = "damage", value = 0.05 } } }
--   { uid = "g13", slot = "implant", kind = "optics", name = "Overwatch Optics", rarity = 4, ilvl = 30,
--     roll = 0.42, color = { r = 0, g = 255, b = 200 } }

HLRPG.Gear = {}
local G = HLRPG.Gear

G.Slots = {
    { id = "gloves",   name = "Gloves" },
    { id = "chestrig", name = "Chest Rig" },
    { id = "implant",  name = "Implant" },
}

-- stats: stat lines on gloves / chest rigs; mult: their value scale; kills: salvage XP
G.Rarities = {
    { name = "Common",    color = Color(200, 200, 200), weight = 60,  stats = 1, mult = 0.40, kills = 1 },
    { name = "Uncommon",  color = Color(90, 220, 90),   weight = 25,  stats = 2, mult = 0.55, kills = 2 },
    { name = "Rare",      color = Color(70, 150, 255),  weight = 11,  stats = 3, mult = 0.70, kills = 4 },
    { name = "Epic",      color = Color(190, 90, 255),  weight = 3.5, stats = 4, mult = 0.85, kills = 8 },
    { name = "Legendary", color = Color(255, 160, 30),  weight = 0.5, stats = 4, mult = 1.00, kills = 16 },
}

-- Gloves / chest rig stats: the ability they become and its value at Legendary, top item level, best roll.
-- "Mild": a full Legendary set is worth about one suit plus a few stat points.
G.Stats = {
    health = { ability = "bonus_health",  max = 40,   whole = true },
    armor  = { ability = "bonus_armor",   max = 60,   whole = true },
    damage = { ability = "damage_bonus",  max = 0.08 },
    crit   = { ability = "crit_chance",   max = 0.06 },
    dodge  = { ability = "dodge_chance",  max = 0.04 },
    resist = { ability = "damage_resist", max = 0.06 },
    bullet = { ability = "bullet_resist", max = 0.10 },
    aregen = { ability = "armor_regen",   max = 3,    whole = true },
}

G.SlotStats = {
    gloves   = { "damage", "crit", "dodge", "health" },
    chestrig = { "armor", "resist", "bullet", "aregen", "health" },
}

G.Names = {
    gloves = { "Work Gloves", "Rebel Grip Gloves", "Padded Gloves", "Overwatch Tactical Gloves", "Hazard Gloves", "Shock Gauntlets" },
    chestrig = { "Canvas Vest", "Resistance Chest Rig", "Kevlar Rig", "Overwatch Plate Carrier", "Nova Prospekt Harness", "Citadel Armor Rig" },
}

-- Implant types. Values are { at Common, at Legendary }: rarity picks a band between them and the item's roll
-- picks a spot inside it. A plain number is fixed.
--   passive  abilities that always apply while it's worn
--   active   what pressing the implant key does: for duration seconds (each ability can have its own duration)
--            its abilities apply, or weapon is handed out (taken back at the end, or earlier if the weapon
--            ends it, like High Noon after 6 shots), or action runs once (sv_implants.lua HLRPG.ImplantActions,
--            its numbers scaled like the rest); then cooldown seconds before it can be used again
G.Implants = {
    optics = {
        name = "Overwatch Optics",
        passive = { { id = "threat_scanner", value = { 500, 1000 } } },
        active = { name = "High Noon", duration = { 3, 5 }, cooldown = { 80, 45 },
                   weapon = { class = "hlrpg_highnoon", text = "A revolver that fires 6 shots on its own into enemies' heads" } },
    },
    executioner = {
        name = "Executioner Chip",
        passive = { { id = "crit_chance", value = { 0.05, 0.12 } } },
        active = { name = "Execute", duration = 5, cooldown = { 60, 35 },
                   abilities = { { id = "crit_chance", value = 1 } } },
    },
    biofeedback = {
        name = "Biofeedback Gland",
        passive = { { id = "combat_health_regen", value = { 6, 12 } } },
        active = { name = "Surge", duration = { 5, 15 }, cooldown = { 70, 40 },
                   abilities = { { id = "combat_health_regen", value = { 10, 25 } } } },
    },
    capacitor = {
        name = "Armor Capacitor",
        passive = { { id = "bonus_armor", value = { 50, 100 } } },
        active = { name = "Armor Overcharge", duration = { 10, 20 }, cooldown = { 70, 40 },
                   abilities = { { id = "bonus_armor", value = 50 }, { id = "combat_armor_regen", value = 20, duration = 5 } } },
    },
    reflex = {
        name = "Reflex Booster",
        passive = { { id = "movement_speed", value = { 0.05, 0.20 } }, { id = "dodge_chance", value = { 0.05, 0.15 } } },
        active = { name = "Blur", duration = { 2, 10 }, cooldown = { 60, 35 },
                   abilities = { { id = "dodge_chance", value = { 0.6, 1.0 } }, { id = "movement_speed", value = 0.5 } } },
    },
    armory = {
        name = "Armory Uplink",
        active = { name = "Armory SMG", duration = { 5, 15 }, cooldown = { 90, 50 },
                   weapon = { class = "hlrpg_implant_smg", rate = { 15, 35 }, text = "Summons an infinite-ammo SMG firing %d rounds/s" } },
    },
    medic = {
        name = "Medic Beacon",
        passive = { { id = "heal_aura", value = { 1, 6 } } },
        active = { name = "Triage Field", duration = 10, cooldown = { 60, 35 },
                   abilities = { { id = "heal_aura", value = { 10, 15 } } } },
    },
    shield = {
        name = "Shield Beacon",
        passive = { { id = "armor_aura", value = { 1, 6 } } },
        active = { name = "Shield Field", duration = 10, cooldown = { 60, 35 },
                   abilities = { { id = "armor_aura", value = { 10, 15 } } } },
    },
    vortessence = {
        name = "Vortessence Gland",
        passive = { { id = "melee_zap", value = { 10, 30 } } },
        active = { name = "Vortal Blast", duration = 1.2, cooldown = { 40, 20 },
                   action = { id = "vortal_blast", damage = { 60, 150 }, jumps = { 3, 6 },
                              text = "Chain lightning: %d damage, jumping to up to %d enemies" } },
    },
    uplink = {
        name = "Overwatch Uplink",
        passive = { { id = "blast_resist", value = { 0.15, 0.40 } } },
        active = { name = "Canister Strike", duration = 2.5, cooldown = { 70, 40 },
                   action = { id = "canister_strike", damage = { 150, 400 }, radius = { 300, 500 },
                              text = "A headcrab canister strikes where you aim: %d damage in a %d unit radius" } },
    },
    skeleton = {
        name = "Reinforced Skeleton",
        passive = { { id = "bonus_health", value = { 50, 100 } }, { id = "bonus_armor", value = { 50, 100 } } },
    },
    graft = {
        name = "Synth Flesh Graft",
        passive = { { id = "bonus_health", value = { 150, 300 } }, { id = "bonus_armor", value = -100 } },
    },
}

-- Random pick order (equal chance each)
G.ImplantOrder = { "optics", "executioner", "biofeedback", "capacitor", "reflex", "armory", "medic", "shield",
    "vortessence", "uplink", "skeleton", "graft" }

G.BackpackSize = 30
G.MaxItemLevel = 50

-- Drop chance per player who damaged the kill (most kills drop nothing), and per player for clearing an arena.
-- These drops are gloves or chest rigs; implants only drop on Insane, from bosses, at implantBoss each.
G.DropChance = { normal = 0.01, tough = 0.05, boss = 0.25, arena = 0.35, implantBoss = 0.03 }
G.ImplantDifficulty = 5 -- Insane
G.ToughNPCs = {
    npc_hunter = true, npc_antlionguard = true, npc_strider = true, npc_combinegunship = true,
    npc_helicopter = true, npc_poisonzombie = true, npc_zombine = true,
}

function G.GetSlotName(slotID)
    for _, slot in ipairs(G.Slots) do
        if slot.id == slotID then return slot.name end
    end
    return slotID
end

-- A value from an implant definition for this rarity (1-5) and roll (0-1)
local function Scale(value, rarity, roll)
    if type(value) ~= "table" then return value end
    local t = math.Clamp(((rarity - 1) + (roll or 0.5)) / #G.Rarities, 0, 1)
    local v = Lerp(t, value[1], value[2])
    if math.max(math.abs(value[1]), math.abs(value[2])) > 2 then return math.Round(v) end
    return math.Round(v * 200) / 200 -- half-percent steps
end

local implantCache = {}

-- What an implant does at its rarity and roll:
-- { passive = { { id, value } }, active = { name, duration, cooldown, abilities = { { id, value, duration } }, weapon } }
function G.GetImplantValues(kind, rarity, roll)
    local key = kind .. "|" .. rarity .. "|" .. roll
    if implantCache[key] then return implantCache[key] end

    local def = G.Implants[kind]
    if not def then return nil end
    local result = { passive = {} }
    for _, p in ipairs(def.passive or {}) do
        result.passive[#result.passive + 1] = { id = p.id, value = Scale(p.value, rarity, roll) }
    end

    local a = def.active
    if a then
        local duration = Scale(a.duration, rarity, roll)
        result.active = { name = a.name, duration = duration, cooldown = Scale(a.cooldown, rarity, roll), abilities = {} }
        for _, ab in ipairs(a.abilities or {}) do
            result.active.abilities[#result.active.abilities + 1] =
                { id = ab.id, value = Scale(ab.value, rarity, roll), duration = Scale(ab.duration or duration, rarity, roll) }
        end
        if a.weapon then
            result.active.weapon = { class = a.weapon.class, rate = a.weapon.rate and Scale(a.weapon.rate, rarity, roll), text = a.weapon.text }
        end
        if a.action then
            local action = { id = a.action.id, text = a.action.text }
            for key, value in pairs(a.action) do
                if key ~= "id" and key ~= "text" then action[key] = Scale(value, rarity, roll) end
            end
            result.active.action = action
        end
    end

    implantCache[key] = result
    return result
end

function G.GetItemImplant(item)
    return item.kind and G.GetImplantValues(item.kind, item.rarity, item.roll or 0.5) or nil
end

-- The always-on abilities an item grants, as { id, value }
function G.GetItemAbilities(item)
    local list = {}
    for _, line in ipairs(item.stats or {}) do
        local stat = G.Stats[line.stat]
        if stat then list[#list + 1] = { id = stat.ability, value = line.value } end
    end
    for _, ability in ipairs(item.abilities or {}) do list[#list + 1] = { id = ability.id, value = ability.value } end -- older saves
    local implant = G.GetItemImplant(item)
    for _, ability in ipairs(implant and implant.passive or {}) do list[#list + 1] = ability end
    return list
end

local function DescribeAbility(ability)
    local def = HLRPG.Abilities[ability.id]
    return def and def.Describe and def.Describe(ability.value) or ability.id
end

-- Text lines for the gear menu: { text, kind } where kind is "stat", "passive", "active" or "cooldown"
function G.DescribeItem(item)
    local lines = {}
    for _, line in ipairs(item.stats or {}) do
        local stat = G.Stats[line.stat]
        if stat then lines[#lines + 1] = { DescribeAbility({ id = stat.ability, value = line.value }), "stat" } end
    end
    for _, ability in ipairs(item.abilities or {}) do lines[#lines + 1] = { DescribeAbility(ability), "passive" } end

    local implant = G.GetItemImplant(item)
    if implant then
        for _, ability in ipairs(implant.passive) do lines[#lines + 1] = { DescribeAbility(ability), "passive" } end
        local a = implant.active
        if a then
            lines[#lines + 1] = { "ACTIVE - " .. a.name .. " (" .. a.duration .. "s):", "active" }
            for _, ability in ipairs(a.abilities) do
                local extra = ability.duration ~= a.duration and (" for " .. ability.duration .. "s") or ""
                lines[#lines + 1] = { "   " .. DescribeAbility(ability) .. extra, "active" }
            end
            if a.weapon then
                lines[#lines + 1] = { "   " .. string.format(a.weapon.text, a.weapon.rate or 0), "active" }
            end
            if a.action then
                local act = a.action
                local text = act.id == "vortal_blast" and string.format(act.text, act.damage, act.jumps)
                    or act.id == "canister_strike" and string.format(act.text, act.damage, act.radius)
                    or act.text
                lines[#lines + 1] = { "   " .. text, "active" }
            end
            lines[#lines + 1] = { "Cooldown " .. a.cooldown .. "s", "cooldown" }
        end
    end
    return lines
end

-- Rolls a rarity index from the weights, at or above minRarity
function G.RollRarity(minRarity)
    minRarity = minRarity or 1
    local total = 0
    for i = minRarity, #G.Rarities do total = total + G.Rarities[i].weight end
    local roll = math.Rand(0, total)
    for i = minRarity, #G.Rarities do
        roll = roll - G.Rarities[i].weight
        if roll <= 0 then return i end
    end
    return #G.Rarities
end

local function RoundStat(stat, value)
    if stat.whole then return math.max(1, math.Round(value)) end
    return math.max(0.005, math.Round(value * 200) / 200)
end

-- Makes a new item. slotID, rarity and (for implants) kind are optional (random); ilvl is the dropping enemy's level.
function G.Generate(ilvl, rarity, slotID, kind)
    ilvl = math.Clamp(math.floor(ilvl or 1), 1, G.MaxItemLevel)
    rarity = rarity or G.RollRarity()
    slotID = slotID or (math.random() < 0.5 and "gloves" or "chestrig") -- implants are only made on purpose
    local item = { slot = slotID, rarity = rarity, ilvl = ilvl }

    if slotID == "implant" then
        kind = (kind and G.Implants[kind]) and kind or G.ImplantOrder[math.random(#G.ImplantOrder)]
        local c = HSVToColor(math.random(0, 359), 1, 1)
        item.kind, item.name, item.roll = kind, G.Implants[kind].name, math.Round(math.Rand(0, 1), 2)
        item.color = { r = c.r, g = c.g, b = c.b }
        return item
    end

    local tier = G.Rarities[rarity]
    local levelFactor = 0.6 + 0.4 * (ilvl / G.MaxItemLevel)
    item.name = table.Random(G.Names[slotID])
    item.stats = {}
    local pool = table.Copy(G.SlotStats[slotID])
    for _ = 1, math.min(tier.stats, #pool) do
        local statID = table.remove(pool, math.random(#pool))
        local stat = G.Stats[statID]
        local value = stat.max * tier.mult * levelFactor * math.Rand(0.75, 1.0)
        item.stats[#item.stats + 1] = { stat = statID, value = RoundStat(stat, value) }
    end
    return item
end
