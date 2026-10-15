-- hlrpg/modules/sv_gear.lua
-- Loot (core/sh_gear.lua): personal drops straight to the backpack, equipping, unequipping and salvaging for XP.
-- A player's gear lives in ply.HLRPG_Gear = { items = { [uid] = item }, equipped = { [slot] = uid }, nextID },
-- saved with ply:SaveGear() (sv_database.lua). Equipped items' abilities are added in sh_abilities.lua.

util.AddNetworkString("HLRPG_GearData")
util.AddNetworkString("HLRPG_GearAction")
util.AddNetworkString("HLRPG_GearDrop")

local G = HLRPG.Gear

local function GearOf(ply)
    ply.HLRPG_Gear = ply.HLRPG_Gear or { items = {}, equipped = {}, nextID = 1 }
    return ply.HLRPG_Gear
end

-- The abilities of equipped gloves / chest rig, cached until the equipment changes (GetActiveAbilities runs a
-- lot). Implants aren't included: they're networked (SyncImplant) so both realms apply them.
function HLRPG.GetGearAbilities(ply)
    if ply.HLRPG_GearAbilityCache then return ply.HLRPG_GearAbilityCache end
    local list, gear = {}, GearOf(ply)
    for _, uid in pairs(gear.equipped) do
        local item = gear.items[uid]
        if item and not item.kind then
            for _, ability in ipairs(G.GetItemAbilities(item)) do list[#list + 1] = ability end
        end
    end
    ply.HLRPG_GearAbilityCache = list
    return list
end

-- Networks the equipped implant (type, rarity, roll, colour), which sh_abilities.lua turns into abilities on
-- both realms. Changing implants also stops a running active.
function HLRPG.SyncImplant(ply)
    local gear = GearOf(ply)
    local uid = gear.equipped.implant
    local item = uid and gear.items[uid]
    local kind = item and item.kind or ""
    if ply:GetNWString("HLRPG_ImplantKind", "") ~= kind or ply.HLRPG_ImplantUID ~= uid then
        if HLRPG.StopImplantActive then HLRPG.StopImplantActive(ply) end
        ply.HLRPG_ImplantUID = uid
    end

    ply:SetNWString("HLRPG_ImplantKind", kind)
    ply:SetNWInt("HLRPG_ImplantRarity", item and item.rarity or 1)
    ply:SetNWFloat("HLRPG_ImplantRoll", item and item.roll or 0.5)
    local c = item and item.color or { r = 255, g = 255, b = 255 }
    ply:SetNWVector("HLRPG_ImplantColor", Vector(c.r / 255, c.g / 255, c.b / 255))
end

hook.Add("HLRPG_PlayerDataLoaded", "HLRPG_SyncImplant", function(ply)
    HLRPG.SyncImplant(ply)
    HLRPG.RefreshStats(ply)
end)

local function SendGear(ply)
    local gear = GearOf(ply)
    net.Start("HLRPG_GearData")
        net.WriteTable({ items = gear.items, equipped = gear.equipped, size = G.BackpackSize })
    net.Send(ply)
end

local function GearChanged(ply, statsChanged)
    ply:SaveGear()
    if statsChanged then
        ply.HLRPG_GearAbilityCache = nil
        HLRPG.SyncImplant(ply)
        HLRPG.RefreshStats(ply)
    end
    SendGear(ply)
end

local function CountItems(gear)
    return table.Count(gear.items)
end

local function SalvageXP(ply, item)
    return HLRPG.GetKillEquivalentXP(G.Rarities[item.rarity].kills, ply:GetLevel())
end

-- Gives ply a new item; a full backpack salvages it straight away. Returns the item.
function HLRPG.GiveGear(ply, item, source)
    if not IsValid(ply) or not ply.HLRPG_Gear then return end
    local gear = GearOf(ply)
    local tier = G.Rarities[item.rarity]

    if CountItems(gear) >= G.BackpackSize then
        local xp = SalvageXP(ply, item)
        HLRPG.AddXP(ply, xp)
        ply:ChatPrint(string.format("[LOOT] Backpack full: %s %s salvaged for %s XP", tier.name, item.name, string.Comma(xp)))
        return item
    end

    item.uid = "g" .. gear.nextID
    gear.nextID = gear.nextID + 1
    gear.items[item.uid] = item

    net.Start("HLRPG_GearDrop")
        net.WriteTable(item)
        net.WriteString(source or "")
    net.Send(ply)
    GearChanged(ply, false)
    return item
end

-- Drops: every player who damaged the kill rolls separately
local function IsTough(npc)
    if G.ToughNPCs[npc:GetClass()] then return true end
    return npc:GetClass() == "npc_combine_s" and string.find(string.lower(npc:GetModel() or ""), "super_soldier", 1, true) ~= nil
end

hook.Add("OnNPCKilled", "HLRPG_GearDrops", function(npc)
    if not IsValid(npc) or not npc.HLRPG_DamageTable then return end

    local boss = npc:GetNWBool("HLRPG_IsBoss", false)
    local chance = boss and G.DropChance.boss or (IsTough(npc) and G.DropChance.tough or G.DropChance.normal)
    local ilvl = npc:GetNWInt("HLRPG_NPCLevel", 1)

    local _, difficulty = HLRPG.GetDifficulty()
    local implants = boss and difficulty >= G.ImplantDifficulty

    for ply, dmg in pairs(npc.HLRPG_DamageTable) do
        if IsValid(ply) and ply:IsPlayer() and dmg > 0 then
            if math.random() < chance then
                HLRPG.GiveGear(ply, G.Generate(ilvl, G.RollRarity(boss and 3 or 1)), HLRPG.GetNPCName(npc))
            end
            -- Implants: Insane bosses only, rarely
            if implants and math.random() < G.DropChance.implantBoss then
                HLRPG.GiveGear(ply, G.Generate(ilvl, G.RollRarity(3), "implant"), HLRPG.GetNPCName(npc))
            end
        end
    end
end)

-- Clearing an arena: a chance of an Epic or better for each player present
hook.Add("HLRPG_ArenaCleared", "HLRPG_GearArenaReward", function(id, boss)
    local ilvl = IsValid(boss) and boss:GetNWInt("HLRPG_NPCLevel", 1) or nil
    for _, ply in ipairs(player.GetAll()) do
        if math.random() < G.DropChance.arena then
            HLRPG.GiveGear(ply, G.Generate(ilvl or ply:GetLevel(), G.RollRarity(4)), "Arena")
        end
    end
end)

-- Equip / unequip / salvage, from the gear menu
local ACTIONS = {}

function ACTIONS.equip(ply, gear, item)
    gear.equipped[item.slot] = item.uid
    ply:ChatPrint("[GEAR] Equipped " .. item.name)
    GearChanged(ply, true)
end

function ACTIONS.unequip(ply, gear, item)
    if gear.equipped[item.slot] ~= item.uid then return end
    gear.equipped[item.slot] = nil
    GearChanged(ply, true)
end

function ACTIONS.salvage(ply, gear, item)
    local wasEquipped = gear.equipped[item.slot] == item.uid
    if wasEquipped then gear.equipped[item.slot] = nil end
    gear.items[item.uid] = nil

    local xp = SalvageXP(ply, item)
    HLRPG.AddXP(ply, xp)
    ply:ChatPrint(string.format("[GEAR] Salvaged %s for %s XP", item.name, string.Comma(xp)))
    GearChanged(ply, wasEquipped)
end

net.Receive("HLRPG_GearAction", function(len, ply)
    if (ply.HLRPG_NextGearAction or 0) > CurTime() then return end
    ply.HLRPG_NextGearAction = CurTime() + 0.15

    local action, uid = net.ReadString(), net.ReadString()
    local gear = GearOf(ply)
    local item = gear.items[uid]
    if item and ACTIONS[action] then ACTIONS[action](ply, gear, item) end
end)

HLRPG.AddMenuRequest("gear", SendGear)
