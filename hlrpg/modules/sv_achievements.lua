-- hlrpg/modules/sv_achievements.lua
-- Achievements and lambda caches. Map triggers come from sh_trigger_maps.lua;
-- custom listeners live in modules/custom_achievement_listeners/.

util.AddNetworkString("HLRPG_AchievementNotify")
util.AddNetworkString("HLRPG_AchievementAnnounce")
util.AddNetworkString("HLRPG_OpenAchievementMenu")
util.AddNetworkString("HLRPG_LambdaNotify")
util.AddNetworkString("HLRPG_OpenLambdaMenu")
util.AddNetworkString("HLRPG_RequestMenu")

function HLRPG.AwardAchievement(ply, achID)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local ach = HLRPG.Achievements[achID]
    if not ach then return end

    ply.UnlockedAchievements = ply.UnlockedAchievements or {}
    if ply.UnlockedAchievements[achID] then return end
    ply.UnlockedAchievements[achID] = true

    if ach.xp and ach.xp > 0 then
        HLRPG.AddXP(ply, ach.xp)
    end

    if ach.rewardItem then
        HLRPG.GiveItem(ply, ach.rewardItem, "Achievement: " .. ach.name)
    end

    net.Start("HLRPG_AchievementNotify")
        net.WriteString(achID)
        net.WriteString(ach.name)
        net.WriteString(ach.desc or "")
        net.WriteInt(ach.xp or 0, 32)
        net.WriteString(ach.rewardItem or "")
        net.WriteString(ach.icon or "")
    net.Send(ply)

    ply:SaveAchievements()

    net.Start("HLRPG_AchievementAnnounce")
        net.WriteEntity(ply)
        net.WriteString(ach.name)
    net.Broadcast()
end

function HLRPG.AwardAchievementToAll(achID)
    for _, ply in ipairs(player.GetAll()) do
        HLRPG.AwardAchievement(ply, achID)
    end
end

-- Other addons can react with hook.Add("HLRPG_LambdaFound", ..., function(ply, lambdaID) end)
function HLRPG.AwardLambda(ply, lambdaID)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    ply.HLRPG_FoundLambdas = ply.HLRPG_FoundLambdas or {}
    if ply.HLRPG_FoundLambdas[lambdaID] then return end
    ply.HLRPG_FoundLambdas[lambdaID] = true

    hook.Run("HLRPG_LambdaFound", ply, lambdaID)

    if table.Count(ply.HLRPG_FoundLambdas) == table.Count(HLRPG.LambdaMap) then
        HLRPG.AwardAchievement(ply, "HL2_LAMBDA_LOCATOR")
    end

    ply:SaveLambdas()
end

local TRIGGER_INPUTS = { Trigger = true, FireEvent = true, OnFound = true, Start = true }

local function GetTriggeringPlayer(activator)
    if IsValid(activator) and activator:IsPlayer() then return activator end
    return player.GetAll()[1]
end

-- Bridges map logic entities to lambda caches and achievements
hook.Add("AcceptInput", "HLRPG_Achievement_Bridge", function(ent, input, activator, caller, value)
    if not TRIGGER_INPUTS[input] then return end

    local targetName = IsValid(ent) and ent:GetName() or ""
    local name = targetName ~= "" and targetName or (IsValid(caller) and caller:GetName() or "")
    if name == "" then return end

    local lambdaID = HLRPG.LambdaMap[game.GetMap():lower() .. "_" .. name]
    if lambdaID then
        local ply = GetTriggeringPlayer(activator)
        if not IsValid(ply) then return end

        HLRPG.AwardLambda(ply, lambdaID)

        net.Start("HLRPG_LambdaNotify")
            net.WriteString(lambdaID)
        net.Send(ply)
        return
    end

    local achID = HLRPG.AchievementTriggerMap[name]
    if not achID then return end

    local ach = HLRPG.Achievements[achID]
    if not ach then
        print("[HLRPG] Error: trigger points to an undefined achievement - " .. achID)
        return
    end

    if ach.isGlobal then
        HLRPG.AwardAchievementToAll(achID)
    else
        HLRPG.AwardAchievement(GetTriggeringPlayer(activator), achID)
    end
end)

hook.Add("WeaponEquip", "HLRPG_CrowbarAchievement_Pickup", function(weapon, ply)
    if not IsValid(weapon) or not IsValid(ply) then return end

    if weapon:GetClass() == "weapon_crowbar" and game.GetMap() == "d1_trainstation_06" then
        HLRPG.AwardAchievement(ply, "HL2_TRUSTY_HARDWARE")
    end
end)

local function OpenAchievementMenu(ply)
    net.Start("HLRPG_OpenAchievementMenu")
        net.WriteTable(ply.UnlockedAchievements or {})
    net.Send(ply)
end

local function OpenLambdaMenu(ply)
    net.Start("HLRPG_OpenLambdaMenu")
        net.WriteTable(ply.HLRPG_FoundLambdas or {})
    net.Send(ply)
end

HLRPG.AddChatCommand("!achievement", OpenAchievementMenu)
HLRPG.AddChatCommand("!ach", OpenAchievementMenu)
HLRPG.AddChatCommand("!lambda", OpenLambdaMenu)

-- The TAB menu asks for these pages by name (see HLRPG.RequestMenu in sh_util.lua)
local MENU_REQUESTS = {
    achievements = OpenAchievementMenu,
    lambdas = OpenLambdaMenu,
}

net.Receive("HLRPG_RequestMenu", function(len, ply)
    if (ply.HLRPG_NextMenuRequest or 0) > CurTime() then return end
    ply.HLRPG_NextMenuRequest = CurTime() + 0.5

    local open = MENU_REQUESTS[net.ReadString()]
    if open then open(ply) end
end)
