-- hlrpg/modules/sv_debug_commands.lua
-- Admin-only console commands for testing items and abilities.

local function AddAdminCommand(name, callback)
    concommand.Add(name, function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsAdmin() then return end
        callback(ply, args)
    end)
end

-- rpg_giveitem <itemID>: adds an item to your inventory for free
AddAdminCommand("rpg_giveitem", function(ply, args)
    local itemID = args[1]
    if not HLRPG.Assets[itemID or ""] then
        ply:ChatPrint("Unknown item: " .. tostring(itemID))
        return
    end
    HLRPG.GiveItem(ply, itemID, "Admin")
end)

-- rpg_abilities: lists every ability active right now (weapon-scoped ones depend on the weapon you hold)
AddAdminCommand("rpg_abilities", function(ply)
    ply:ChatPrint("--- ACTIVE ABILITIES ---")
    for _, itemID in ipairs(HLRPG.GetEquippedItems(ply)) do
        local item = HLRPG.Assets[itemID]
        local scope = item.scope and (" [" .. item.scope .. "]") or ""
        ply:ChatPrint(item.name .. scope .. ": " .. HLRPG.DescribeAbilities(item))
    end
end)

-- rpg_givexp <amount>: adds XP to yourself (levels up as usual)
AddAdminCommand("rpg_givexp", function(ply, args)
    local amount = math.floor(tonumber(args[1] or "") or 0)
    if amount <= 0 then
        ply:ChatPrint("Usage: rpg_givexp <amount>")
        return
    end
    HLRPG.AddXP(ply, amount)
    ply:ChatPrint("Gave yourself " .. string.Comma(amount) .. " XP.")
end)

-- rpg_removeach <achID|all>: locks an achievement again so it can be re-tested.
-- XP and reward items it gave are kept. An unknown ID lists the IDs containing that text.
AddAdminCommand("rpg_removeach", function(ply, args)
    local achID = string.upper(args[1] or "")
    ply.UnlockedAchievements = ply.UnlockedAchievements or {}

    if achID == "ALL" then
        ply.UnlockedAchievements = {}
    elseif HLRPG.Achievements[achID] then
        ply.UnlockedAchievements[achID] = nil
    else
        ply:ChatPrint("Unknown achievement: " .. achID)
        for id in SortedPairs(HLRPG.Achievements) do
            if achID ~= "" and string.find(id, achID, 1, true) then ply:ChatPrint("  " .. id) end
        end
        return
    end

    ply:SaveAchievements()
    ply:ChatPrint("Removed achievement: " .. achID)
end)

-- rpg_run: shows your current campaign run (sv_campaign_runs.lua)
AddAdminCommand("rpg_run", function(ply)
    local run = ply.HLRPG_Run
    if not run then
        ply:ChatPrint("[RUN] No active run. Runs start on a campaign's first map.")
        return
    end

    local difficulty = run.minDifficulty and HLRPG.DifficultyScales[run.minDifficulty].name or "not locked in yet"
    ply:ChatPrint(string.format("[RUN] %s, map #%d (%s), counting difficulty: %s", run.campaign, run.index, game.GetMap(), difficulty))
end)
