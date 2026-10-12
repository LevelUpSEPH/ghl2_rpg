-- hlrpg/core/sh_runs.lua
-- Campaign runs: play a campaign from its first map to its last without disconnecting (sv_campaign_runs.lua).
-- Map order comes from the gamemode (Lambda's campaign map list). Difficulty only counts once lockMap has
-- been completed; from then on the lowest difficulty seen decides which one completion achievement unlocks.

HLRPG.Campaigns = {
    { id = "hl2", name = "Half-Life 2", firstMap = "d1_trainstation_01", lockMap = "d1_canals_01", rewardScale = 1.0 },
    { id = "ep1", name = "Episode One", firstMap = "ep1_citadel_00", lockMap = "ep1_citadel_01", rewardScale = 0.4 },
    { id = "ep2", name = "Episode Two", firstMap = "ep2_outland_01", lockMap = "ep2_outland_02", rewardScale = 0.6 },
}
-- Optional per campaign: rewardItems = { [difficulty] = "<item id>" }

-- XP per difficulty (Very Easy .. Insane), in standard kills at the player's level, times rewardScale
HLRPG.CampaignRunKills = { 40, 80, 165, 300, 500 }

-- XP for finishing a run without dying (any difficulty), times rewardScale
HLRPG.CampaignDeathlessKills = 300

function HLRPG.GetCampaignRunAchievement(campaignID, difficulty)
    return "RUN_" .. campaignID:upper() .. "_" .. difficulty
end

function HLRPG.GetDeathlessRunAchievement(campaignID)
    return "RUN_" .. campaignID:upper() .. "_DEATHLESS"
end

for campaignIndex, campaign in ipairs(HLRPG.Campaigns) do
    for difficulty, scale in ipairs(HLRPG.DifficultyScales) do
        HLRPG.Achievements[HLRPG.GetCampaignRunAchievement(campaign.id, difficulty)] = {
            name = campaign.name .. ": " .. scale.name .. " Run",
            desc = "Finish " .. campaign.name .. " in one sitting on " .. scale.name .. " (lowest difficulty after " .. campaign.lockMap .. ")",
            category = "general",
            sort = string.format("3 %d %d", campaignIndex, difficulty),
            kills = math.Round(HLRPG.CampaignRunKills[difficulty] * campaign.rewardScale),
            rewardItem = campaign.rewardItems and campaign.rewardItems[difficulty],
        }
    end

    HLRPG.Achievements[HLRPG.GetDeathlessRunAchievement(campaign.id)] = {
        name = campaign.name .. ": No Death Run",
        desc = "Finish " .. campaign.name .. " in one sitting without dying once (any difficulty)",
        category = "general",
        sort = string.format("3 %d 9", campaignIndex),
        kills = math.Round(HLRPG.CampaignDeathlessKills * campaign.rewardScale),
    }
end
