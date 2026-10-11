-- hlrpg/modules/sv_database.lua
-- All persistence goes through here (PData). Keys must stay stable or existing saves are lost.

local meta = FindMetaTable("Player")

local function LoadJSON(ply, key)
    local data = ply:GetPData(key)
    return (data and data ~= "") and util.JSONToTable(data) or {}
end

local function SaveJSON(ply, key, tbl)
    ply:SetPData(key, util.TableToJSON(tbl or {}))
end

-- XP / Level

function meta:GetXP()
    if not self.HLRPG_XP then
        self.HLRPG_XP = tonumber(self:GetPData("HLRPG_XP")) or 0
    end
    return self.HLRPG_XP
end

-- XP is both level progress and the shop currency, so spending passes a negative delta
function meta:ChangeXP(delta)
    local newXP = self:GetXP() + delta
    self.HLRPG_XP = newXP
    self:SetPData("HLRPG_XP", newXP)
    self:SetNWInt("HLRPG_XP", newXP)
end

function meta:GetLevel()
    if not self.HLRPG_Level then
        self.HLRPG_Level = tonumber(self:GetPData("HLRPG_Level")) or 1
    end
    return self.HLRPG_Level
end

function meta:SaveLevel(level)
    self.HLRPG_Level = level
    self:SetPData("HLRPG_Level", level)
    self:SetNWInt("HLRPG_Level", level)
    self:SetNWInt("HLRPG_MaxXP", HLRPG.GetRequiredXP(level))
end

-- Inventory

function meta:GetInventory()
    if not self.HLRPG_Inventory then
        self.HLRPG_Inventory = LoadJSON(self, "HLRPG_Inventory")
    end
    return self.HLRPG_Inventory
end

function meta:AddInventoryItem(itemID)
    self:GetInventory()[itemID] = true
    SaveJSON(self, "HLRPG_Inventory", self.HLRPG_Inventory)
    self:SetNWBool("HLRPG_Owned_" .. itemID, true)
end

function meta:OwnsItem(itemID)
    return self:GetInventory()[itemID] == true
end

function meta:SyncInventoryToClient()
    for itemID, owned in pairs(self:GetInventory()) do
        if owned then
            self:SetNWBool("HLRPG_Owned_" .. itemID, true)
        end
    end
end

-- Stats (points spent per stat, see core/sh_stats.lua). Networked so stat abilities apply on both realms.

function meta:LoadStats()
    local saved = LoadJSON(self, "HLRPG_Stats")
    for _, stat in ipairs(HLRPG.Stats) do
        self:SetNWInt("HLRPG_Stat_" .. stat.id, tonumber(saved[stat.id]) or 0)
    end
end

function meta:SaveStats()
    local data = {}
    for _, stat in ipairs(HLRPG.Stats) do data[stat.id] = HLRPG.GetStatPoints(self, stat.id) end
    SaveJSON(self, "HLRPG_Stats", data)
end

-- Achievements / Lambdas

-- Counts are networked for the scoreboard
function meta:LoadAchievements()
    self.UnlockedAchievements = LoadJSON(self, "HLRPG_Achievements")
    self:SetNWInt("HLRPG_AchievementCount", table.Count(self.UnlockedAchievements))
    return self.UnlockedAchievements
end

function meta:SaveAchievements()
    SaveJSON(self, "HLRPG_Achievements", self.UnlockedAchievements)
    self:SetNWInt("HLRPG_AchievementCount", table.Count(self.UnlockedAchievements or {}))
end

function meta:LoadLambdas()
    self.HLRPG_FoundLambdas = LoadJSON(self, "HLRPG_FoundLambdas")
    self:SetNWInt("HLRPG_LambdaCount", table.Count(self.HLRPG_FoundLambdas))
    return self.HLRPG_FoundLambdas
end

function meta:SaveLambdas()
    SaveJSON(self, "HLRPG_FoundLambdas", self.HLRPG_FoundLambdas)
    self:SetNWInt("HLRPG_LambdaCount", table.Count(self.HLRPG_FoundLambdas or {}))
end

-- Pets

function meta:LoadPetData()
    self.HLRPG_PetStats = LoadJSON(self, "HLRPG_PetProgress")

    for petID, data in pairs(self.HLRPG_PetStats) do
        self:SetNWInt("PetLevel_" .. petID, data.level or 1)
        self:SetNWInt("PetXP_" .. petID, data.xp or 0)

        local name, colorVec = self:GetPetCustomization(petID)
        if name then self:SetNWString("HLRPG_CustomName_" .. petID, name) end
        if colorVec then self:SetNWVector("HLRPG_CustomColorVec_" .. petID, colorVec) end
    end
end

function meta:SavePetProgress(petID, level, xp)
    self.HLRPG_PetStats = self.HLRPG_PetStats or {}
    self.HLRPG_PetStats[petID] = { level = level, xp = xp }
    SaveJSON(self, "HLRPG_PetProgress", self.HLRPG_PetStats)
end

-- Returns the saved name (or nil) and color as a 0-1 Vector (or nil)
function meta:GetPetCustomization(petID)
    local name = self:GetPData("PetName_" .. petID)

    local colorVec
    local raw = self:GetPData("PetColor_" .. petID)
    local c = raw and util.JSONToTable(raw)
    if c and #c >= 3 then
        colorVec = Vector(c[1] / 255, c[2] / 255, c[3] / 255)
    end

    return name, colorVec
end

function meta:SavePetCustomization(petID, name, color)
    self:SetPData("PetName_" .. petID, name)
    self:SetPData("PetColor_" .. petID, util.TableToJSON({ color.r, color.g, color.b }))

    self:SetNWString("HLRPG_CustomName_" .. petID, name)
    self:SetNWVector("HLRPG_CustomColorVec_" .. petID, Vector(color.r / 255, color.g / 255, color.b / 255))
end

-- Equipment

function meta:SaveHat()
    self:SetPData("HLRPG_ActiveHat", self:GetNWString("HLRPG_ActiveHat", "none"))
end

function meta:LoadHat()
    local hatID = self:GetPData("HLRPG_ActiveHat", "none")
    if HLRPG.Assets[hatID] then HLRPG.ApplyHat(self, hatID) end
    return hatID
end

function meta:SaveSuit()
    self:SetPData("HLRPG_ActiveSuit", self:GetNWString("HLRPG_ActiveSuit", "none"))
end

-- Base player model picked in the F1 menu. Only models still in HLRPG.Config.Models are restored.
function meta:SavePlayerModel()
    self:SetPData("HLRPG_PlayerModel", self.HLRPG_Model or "")
end

function meta:LoadPlayerModel()
    local model = self:GetPData("HLRPG_PlayerModel", "")
    for _, entry in ipairs(HLRPG.Config.Models) do
        if entry.model == model then
            self.HLRPG_Model = model
            self:SetModel(model)
            self:SetupHands()
            return
        end
    end
end

function meta:LoadSuit()
    local suitID = self:GetPData("HLRPG_ActiveSuit", "none")
    if HLRPG.Assets[suitID] then HLRPG.ApplySuit(self, suitID) end
    return suitID
end

function meta:InitialRPGSetup()
    self:GetXP()
    self:GetLevel()
    self:LoadAchievements()
    self:LoadLambdas()
    self:LoadPetData()
    self:LoadStats()
    self:SyncInventoryToClient()
    self:LoadPlayerModel()
    self:LoadHat()
    self:LoadSuit()

    self:SetNWInt("HLRPG_XP", self.HLRPG_XP)
    self:SetNWInt("HLRPG_Level", self.HLRPG_Level)
    self:SetNWInt("HLRPG_MaxXP", HLRPG.GetRequiredXP(self.HLRPG_Level))

    -- The first spawn happens before this data loads, so apply level/suit stats now
    HLRPG.RefreshStats(self, true)

    print("[HLRPG] " .. self:Nick() .. " data loaded.")
    hook.Run("HLRPG_PlayerDataLoaded", self)
end
