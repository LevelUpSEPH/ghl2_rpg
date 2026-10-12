-- hlrpg/modules/sv_admin_commands.lua
-- Admin console commands. They work for in-game admins and from the server console / rcon, so the
-- server can be run remotely. Type rpg_help for the list.
--
-- [player] is a name (or part of one), a SteamID or SteamID64. In-game admins can leave it out to target
-- themselves; from the server console it's required.

local commands = {}

-- Sends a line to whoever ran the command: chat for players, the console otherwise
local function Reply(caller, text)
    if IsValid(caller) then caller:ChatPrint(text) else print(text) end
end

-- The online player a text refers to, or nil plus an error message
local function FindPlayer(text)
    text = string.lower(text or "")
    if text == "" then return nil, "No player given." end

    local matches = {}
    for _, ply in ipairs(player.GetAll()) do
        if string.lower(ply:SteamID()) == text or ply:SteamID64() == text then return ply end
        if string.find(string.lower(ply:Nick()), text, 1, true) then matches[#matches + 1] = ply end
    end

    if #matches == 1 then return matches[1] end
    if #matches == 0 then return nil, "No player matches '" .. text .. "'." end
    return nil, "'" .. text .. "' matches " .. #matches .. " players, be more specific."
end

-- Commands taking a target: args[1] is the target if it names a player; otherwise an in-game caller is
-- the target and keeps all of args. Returns target and the remaining args, or nil.
local function TakeTarget(caller, args, argCount)
    if #args > argCount then
        local target, err = FindPlayer(args[1])
        if not target then Reply(caller, err) return nil end
        return target, { select(2, unpack(args)) }
    end

    if IsValid(caller) then return caller, args end
    Reply(caller, "Give a player first when running this from the server console.")
end

-- usage is shown by rpg_help and when the arguments are wrong.
-- argCount = how many arguments come after the optional [player] (nil = the command takes no player).
local function AddAdminCommand(name, usage, argCount, callback)
    commands[#commands + 1] = { name = name, usage = usage }

    concommand.Add(name, function(caller, cmd, args)
        if IsValid(caller) and not caller:IsAdmin() then return end

        if argCount == nil then return callback(caller, args) end

        local target, rest = TakeTarget(caller, args, argCount)
        if target then callback(caller, target, rest) end
    end)
end

AddAdminCommand("rpg_help", "rpg_help - this list", nil, function(caller)
    Reply(caller, "--- HL2:RPG admin commands ([player] optional in-game) ---")
    for _, command in ipairs(commands) do Reply(caller, command.usage) end
    Reply(caller, "Debug toggles: hlrpg_debug_damage, hlrpg_debug_kills")
end)

AddAdminCommand("rpg_players", "rpg_players - online players with level, XP and SteamID", nil, function(caller)
    for _, ply in ipairs(player.GetAll()) do
        Reply(caller, string.format("%s | Lv %d | %s XP | %s TP | %s",
            ply:Nick(), ply:GetNWInt("HLRPG_Level", 1), string.Comma(ply:GetNWInt("HLRPG_XP", 0)),
            string.Comma(ply:GetNWInt("HLRPG_TempPoints", 0)), ply:SteamID()))
    end
end)

AddAdminCommand("rpg_setdiff", "rpg_setdiff <1-" .. #HLRPG.DifficultyScales .. "> - set the world difficulty", nil, function(caller, args)
    local level = tonumber(args[1] or "")
    if not level then
        Reply(caller, "Usage: rpg_setdiff <1-" .. #HLRPG.DifficultyScales .. ">")
        return
    end
    HLRPG.SetDifficulty(level)
    Reply(caller, "Difficulty set to " .. HLRPG.DifficultyScales[math.Clamp(level, 1, #HLRPG.DifficultyScales)].name .. ".")
end)

AddAdminCommand("rpg_givexp", "rpg_givexp [player] <amount> - give XP (levels up as usual)", 1, function(caller, target, args)
    local amount = math.floor(tonumber(args[1] or "") or 0)
    if amount <= 0 then
        Reply(caller, "Usage: rpg_givexp [player] <amount>")
        return
    end
    HLRPG.AddXP(target, amount)
    Reply(caller, "Gave " .. target:Nick() .. " " .. string.Comma(amount) .. " XP.")
end)

AddAdminCommand("rpg_givetp", "rpg_givetp [player] <amount> - give Temp Points", 1, function(caller, target, args)
    local amount = math.floor(tonumber(args[1] or "") or 0)
    if amount <= 0 then
        Reply(caller, "Usage: rpg_givetp [player] <amount>")
        return
    end
    HLRPG.AddTempPoints(target, amount)
    Reply(caller, "Gave " .. target:Nick() .. " " .. string.Comma(amount) .. " TP.")
end)

AddAdminCommand("rpg_items", "rpg_items [text] - list item IDs (optionally only those containing text)", nil, function(caller, args)
    local filter = string.lower(args[1] or "")
    for id, item in SortedPairs(HLRPG.Assets) do
        if filter == "" or string.find(id, filter, 1, true) then Reply(caller, id .. " - " .. item.name) end
    end
end)

AddAdminCommand("rpg_giveitem", "rpg_giveitem [player] <itemID> - give an item for free", 1, function(caller, target, args)
    local itemID = args[1] or ""
    if not HLRPG.Assets[itemID] then
        Reply(caller, "Unknown item: " .. itemID .. " (see rpg_items)")
        return
    end
    if HLRPG.GiveItem(target, itemID, "Admin") then
        Reply(caller, "Gave " .. target:Nick() .. " " .. HLRPG.Assets[itemID].name .. ".")
    else
        Reply(caller, target:Nick() .. " already owns " .. HLRPG.Assets[itemID].name .. ".")
    end
end)

-- An achievement ID from text, or nil after listing the IDs that contain it
local function FindAchievement(caller, text)
    local achID = string.upper(text or "")
    if HLRPG.Achievements[achID] then return achID end

    Reply(caller, "Unknown achievement: " .. achID)
    for id in SortedPairs(HLRPG.Achievements) do
        if achID ~= "" and string.find(id, achID, 1, true) then Reply(caller, "  " .. id) end
    end
end

AddAdminCommand("rpg_giveach", "rpg_giveach [player] <achID> - unlock an achievement (with its rewards)", 1, function(caller, target, args)
    local achID = FindAchievement(caller, args[1])
    if not achID then return end
    HLRPG.AwardAchievement(target, achID)
    Reply(caller, "Gave " .. target:Nick() .. " " .. HLRPG.Achievements[achID].name .. ".")
end)

-- XP and reward items the achievement gave are kept
AddAdminCommand("rpg_removeach", "rpg_removeach [player] <achID|all> - lock an achievement again", 1, function(caller, target, args)
    target.UnlockedAchievements = target.UnlockedAchievements or {}

    local achID
    if string.upper(args[1] or "") == "ALL" then
        achID = "ALL"
        target.UnlockedAchievements = {}
    else
        achID = FindAchievement(caller, args[1])
        if not achID then return end
        target.UnlockedAchievements[achID] = nil
    end

    target:SaveAchievements()
    Reply(caller, "Removed " .. achID .. " from " .. target:Nick() .. ".")
end)

-- Weapon-scoped abilities depend on the weapon the player holds right now
AddAdminCommand("rpg_abilities", "rpg_abilities [player] - list active items and their abilities", 0, function(caller, target)
    Reply(caller, "--- " .. target:Nick() .. ": active abilities ---")
    for _, itemID in ipairs(HLRPG.GetEquippedItems(target)) do
        local item = HLRPG.Assets[itemID]
        local scope = item.scope and (" [" .. item.scope .. "]") or ""
        Reply(caller, item.name .. scope .. ": " .. HLRPG.DescribeAbilities(item))
    end
end)

AddAdminCommand("rpg_run", "rpg_run [player] - show a player's campaign run", 0, function(caller, target)
    local run = target.HLRPG_Run
    if not run then
        Reply(caller, "[RUN] " .. target:Nick() .. " has no active run. Runs start on a campaign's first map.")
        return
    end

    local difficulty = run.minDifficulty and HLRPG.DifficultyScales[run.minDifficulty].name or "not locked in yet"
    Reply(caller, string.format("[RUN] %s: %s, map #%d (%s), counting difficulty: %s, %s",
        target:Nick(), run.campaign, run.index, game.GetMap(), difficulty, run.died and "has died" or "no deaths"))
end)

-- Boards are run_<campaign> (run_hl2, run_ep1, run_ep2) or map_<map> (map_d1_canals_01)
AddAdminCommand("rpg_cleartimes", "rpg_cleartimes <board|all> [steamid] - delete leaderboard times", nil, function(caller, args)
    local board = string.lower(args[1] or "")
    if board == "" then
        Reply(caller, "Usage: rpg_cleartimes <run_hl2|map_<map>|all> [steamid]")
        return
    end

    local removed = HLRPG.ClearTimes(board, args[2] and string.upper(args[2]))
    Reply(caller, "Removed " .. removed .. " time(s).")
end)

-- Wipes all of a player's progress. Works for offline players by SteamID. Has to be run twice within
-- 15 seconds to go through. An online player is kicked first so nothing in memory gets saved back.
local pendingResets = {}

AddAdminCommand("rpg_resetdata", "rpg_resetdata <player|steamid> - wipe ALL of a player's progress (run twice)", nil, function(caller, args)
    local text = args[1] or ""
    local target = FindPlayer(text)
    local steamID = IsValid(target) and target:SteamID() or string.upper(text)
    if not string.match(steamID, "^STEAM_%d:%d:%d+$") then
        Reply(caller, "Usage: rpg_resetdata <online player name | STEAM_0:x:y>")
        return
    end

    local who = IsValid(target) and (target:Nick() .. " (" .. steamID .. ")") or steamID
    local callerKey = IsValid(caller) and caller:SteamID() or "console"
    if pendingResets[callerKey] ~= steamID or (pendingResets[callerKey .. "_time"] or 0) < CurTime() then
        pendingResets[callerKey] = steamID
        pendingResets[callerKey .. "_time"] = CurTime() + 15
        Reply(caller, "This deletes ALL progress of " .. who .. " (leaderboard times are kept). Run the same command again within 15 seconds to confirm.")
        return
    end
    pendingResets[callerKey] = nil

    if IsValid(target) then
        -- Dropped so the disconnect hooks have nothing to save back
        target.HLRPG_Counters = nil
        target.HLRPG_Run = nil
        target:Kick("Your HL2:RPG progress was reset by an admin. You can rejoin now.")
    end

    local removed = HLRPG.WipePlayerData(steamID)
    Reply(caller, "Reset " .. who .. ": " .. removed .. " saved entries deleted.")
    print("[HLRPG] Player data reset for " .. who .. " by " .. (IsValid(caller) and caller:Nick() or "console"))
end)
