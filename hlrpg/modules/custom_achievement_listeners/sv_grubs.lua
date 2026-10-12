-- hlrpg/modules/custom_achievement_listeners/sv_grubs.lua
-- Get Some Grub: every antlion grub squished in Episode Two counts for everyone present. Progress is per
-- campaign run: it resets when the player disconnects or Episode Two starts over from its first map.

local COLLECTION = "ep2_grubs"
local LISTENER = "hlrpg_grub_listener"

-- Squished by the train in a scripted scene, not by players (Valve's goal of 333 leaves these out too)
local SCRIPTED_PREFIX = "train_squish_grub"

local function GetEpisodeTwo()
    for _, campaign in ipairs(HLRPG.Campaigns) do
        if campaign.id == "ep2" then return campaign end
    end
end

-- Grubs aren't NPCs, so OnNPCKilled never sees them. Each grub's OnDeath output is pointed at a listener
-- entity instead, carrying the grub's map ID so a grub counts once even if the map is replayed.
local function CreateListener()
    if IsValid(ents.FindByName(LISTENER)[1]) then return end
    local listener = ents.Create("info_target")
    listener:SetName(LISTENER)
    listener:Spawn()
end

hook.Add("InitPostEntity", "HLRPG_GrubListener", CreateListener)
hook.Add("PostCleanupMap", "HLRPG_GrubListener", CreateListener)

hook.Add("OnEntityCreated", "HLRPG_GrubOutputs", function(ent)
    if ent:GetClass() ~= "npc_antlion_grub" then return end

    timer.Simple(0, function()
        if not IsValid(ent) or ent:MapCreationID() == -1 then return end
        if string.StartWith(ent:GetName(), SCRIPTED_PREFIX) then return end

        ent:Fire("AddOutput", "OnDeath " .. LISTENER .. ":GrubSquished:" .. ent:MapCreationID() .. ":0:1")
    end)
end)

hook.Add("AcceptInput", "HLRPG_GrubSquished", function(ent, input, activator, caller, value)
    if input ~= "GrubSquished" or ent:GetName() ~= LISTENER then return end

    local grub = game.GetMap() .. "#" .. tostring(value)
    for _, ply in ipairs(player.GetAll()) do
        HLRPG.AddCollectionItem(ply, COLLECTION, grub, true)
    end
    return true
end)

local function ResetGrubs(ply)
    if not ply.HLRPG_Counters or ply.HLRPG_Counters[COLLECTION] == nil then return end
    ply.HLRPG_Counters[COLLECTION] = nil
    ply:SaveCounters()
end

hook.Add("HLRPG_PlayerDataLoaded", "HLRPG_GrubRunStart", function(ply)
    local episodeTwo = GetEpisodeTwo()
    if episodeTwo and game.GetMap() == episodeTwo.firstMap then ResetGrubs(ply) end
end)

hook.Add("PlayerDisconnected", "HLRPG_GrubRunBreak", ResetGrubs)
