-- hlrpg/modules/sv_arenas.lua
-- Runs the miniboss arenas defined in core/sh_arenas.lua: starts them, raises their walls, spawns the boss and
-- escorts, and ends them when the boss dies (reward), the timeout passes, or the map changes or restarts.
-- Each arena runs once per map load. Other code can react with
--   hook.Add("HLRPG_ArenaStarted", ..., function(id, boss) end)
--   hook.Add("HLRPG_ArenaCleared", ..., function(id, boss) end)

local BLOCK_MODES = { players = 0, npcs = 1, all = 2 }
local WALL_RETRY_DELAY, WALL_MAX_RETRIES = 0.5, 20 -- wait up to 10 s for players to step out of a wall

local active = {}   -- [id] = { walls = { ents }, boss = ent, escorts = { ents } }
local finished = {} -- [id] = true once it has run on this map load

local function Announce(text)
    for _, ply in ipairs(player.GetAll()) do ply:ChatPrint("[ARENA] " .. text) end
end

-- A wall entity filling the box between two corners
function HLRPG.CreateArenaWall(cornerA, cornerB, block, visible)
    local mins, maxs = Vector(cornerA), Vector(cornerB)
    OrderVectors(mins, maxs)
    local center = (mins + maxs) / 2

    local wall = ents.Create("hlrpg_arena_wall")
    if not IsValid(wall) then return nil end
    wall:SetPos(center)
    wall:SetBoxMins(mins - center)
    wall:SetBoxMaxs(maxs - center)
    wall:SetBlockMode(BLOCK_MODES[block or "players"] or 0)
    wall:SetShowField(visible ~= false)
    wall:Spawn()
    return wall
end

local function PlayersInside(cornerA, cornerB)
    local mins, maxs = Vector(cornerA), Vector(cornerB)
    OrderVectors(mins, maxs)
    for _, ent in ipairs(ents.FindInBox(mins, maxs)) do
        if ent:IsPlayer() and ent:Alive() then return true end
    end
    return false
end

-- Raises a wall once nobody is standing in it (so nobody gets stuck), or after waiting long enough
local function RaiseWall(state, def, tries)
    if state.ended then return end
    if tries < WALL_MAX_RETRIES and PlayersInside(def[1], def[2]) then
        timer.Simple(WALL_RETRY_DELAY, function() RaiseWall(state, def, tries + 1) end)
        return
    end
    local wall = HLRPG.CreateArenaWall(def[1], def[2], def.block, def.visible)
    if IsValid(wall) then table.insert(state.walls, wall) end
end

local function SpawnNPC(def)
    local npc = ents.Create(def.class)
    if not IsValid(npc) then return nil end

    npc:SetPos(def.pos)
    npc:SetAngles(def.ang or angle_zero)
    if def.model then npc:SetModel(def.model) end
    if def.weapon then npc:SetKeyValue("additionalequipment", def.weapon) end
    for key, value in pairs(def.keyvalues or {}) do npc:SetKeyValue(key, tostring(value)) end
    return npc
end

local function SpawnBoss(id, def)
    local boss = SpawnNPC(def)
    if not IsValid(boss) then return nil end

    -- Set before spawning, so the usual NPC setup (sv_difficulty.lua) applies boss health and the boss bar
    boss:SetNWBool("HLRPG_IsBoss", true)
    if def.name then boss:SetNWString("HLRPG_NPCName", def.name) end
    boss.HLRPG_ArenaID = id
    boss:Spawn()
    boss:Activate()

    if def.skin then boss:SetSkin(def.skin) end
    if def.scale then boss:SetModelScale(def.scale, 0) end
    if def.color then boss:SetColor(def.color) end

    -- After the usual setup (0.1 s) has set its health: the arena's extra multiplier on top
    timer.Simple(0.3, function()
        if not IsValid(boss) or not def.health then return end
        local hp = math.floor(boss:GetMaxHealth() * def.health)
        boss:SetMaxHealth(hp)
        boss:SetHealth(hp)
    end)
    return boss
end

-- Ends an arena: walls down; cleared = the boss was killed, which rewards everyone present
function HLRPG.EndArena(id, cleared)
    local state = active[id]
    if not state then return end
    state.ended = true
    active[id] = nil
    finished[id] = true
    timer.Remove("HLRPG_ArenaTimeout_" .. id)

    for _, wall in ipairs(state.walls) do
        if IsValid(wall) then wall:Remove() end
    end

    local arena = HLRPG.Arenas[id]
    if not cleared then
        Announce("The barrier is down.")
        return
    end

    local name = IsValid(state.boss) and HLRPG.GetNPCName(state.boss) or "The boss"
    Announce(name .. " has been defeated!")
    local reward = arena and arena.reward or {}
    for _, ply in ipairs(player.GetAll()) do
        local xp = HLRPG.GetKillEquivalentXP(reward.kills or 0, ply:GetLevel())
        if xp > 0 then
            HLRPG.AddXP(ply, xp)
            ply:ChatPrint("[ARENA] +" .. string.Comma(xp) .. " XP")
        end
        if reward.item and HLRPG.Assets[reward.item] then HLRPG.GiveItem(ply, reward.item, "Arena: " .. name) end
    end
    hook.Run("HLRPG_ArenaCleared", id, state.boss)
end

-- Starts an arena. force skips the "right map" and "already ran" checks (admin testing).
-- Returns true, or false and the reason.
function HLRPG.StartArena(id, force)
    local arena = HLRPG.Arenas[id]
    if not arena then return false, "no arena called " .. tostring(id) end
    if active[id] then return false, "already running" end
    if not force and finished[id] then return false, "already ran on this map" end
    if not force and arena.map ~= game.GetMap():lower() then return false, "belongs to " .. tostring(arena.map) end

    local state = { walls = {}, escorts = {} }
    active[id] = state

    for _, def in ipairs(arena.walls or {}) do RaiseWall(state, def, 0) end
    state.boss = arena.boss and SpawnBoss(id, arena.boss)
    for _, def in ipairs(arena.escorts or {}) do
        local npc = SpawnNPC(def)
        if IsValid(npc) then
            npc:Spawn()
            npc:Activate()
            table.insert(state.escorts, npc)
        end
    end

    timer.Create("HLRPG_ArenaTimeout_" .. id, arena.timeout or HLRPG.ArenaDefaultTimeout, 1, function()
        HLRPG.EndArena(id, false)
    end)

    if IsValid(state.boss) then Announce(HLRPG.GetNPCName(state.boss) .. " blocks the way!") end
    hook.Run("HLRPG_ArenaStarted", id, state.boss)
    return true
end

-- The boss dying clears its arena; the boss vanishing any other way (cleanup) just ends it
hook.Add("OnNPCKilled", "HLRPG_ArenaBossKilled", function(npc)
    if IsValid(npc) and npc.HLRPG_ArenaID then HLRPG.EndArena(npc.HLRPG_ArenaID, true) end
end)

hook.Add("EntityRemoved", "HLRPG_ArenaBossRemoved", function(ent)
    local id = ent.HLRPG_ArenaID
    if id and active[id] and active[id].boss == ent then
        timer.Simple(0, function() HLRPG.EndArena(id, false) end) -- after OnNPCKilled, which clears it
    end
end)

-- Starting by map input
hook.Add("AcceptInput", "HLRPG_ArenaInputStart", function(ent, input)
    local map, name = game.GetMap():lower(), IsValid(ent) and ent:GetName() or ""
    for id, arena in pairs(HLRPG.Arenas) do
        local trigger = arena.start and arena.start.input
        if trigger and arena.map == map and trigger.name == name and string.lower(trigger.input) == string.lower(input) then
            HLRPG.StartArena(id)
        end
    end
end)

-- Starting by a player entering an area (checked twice a second)
timer.Create("HLRPG_ArenaAreaStart", 0.5, 0, function()
    local map = game.GetMap():lower()
    for id, arena in pairs(HLRPG.Arenas) do
        local area = arena.start and arena.start.area
        if area and arena.map == map and not active[id] and not finished[id] and PlayersInside(area[1], area[2]) then
            HLRPG.StartArena(id)
        end
    end
end)

-- Lambda restarting the round removes the walls and NPCs: forget the arenas so they can run again
hook.Add("PostCleanupMap", "HLRPG_ArenaReset", function()
    for id, state in pairs(active) do
        state.ended = true
        timer.Remove("HLRPG_ArenaTimeout_" .. id)
    end
    active, finished = {}, {}
end)

hook.Add("LambdaPreChangelevel", "HLRPG_ArenaChangelevel", function()
    for id in pairs(active) do HLRPG.EndArena(id, false) end
end)

function HLRPG.GetActiveArenas() return active end
