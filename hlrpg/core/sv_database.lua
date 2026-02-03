-- hlrpg/core/sv_database.lua

local meta = FindMetaTable("Player")

if not meta then
    ErrorNoHalt("[HLRPG] KRITIK HATA: Player Metatable bulunamadi!\n")
    return
end

function meta:SaveLambda(id)
    local found = self:GetFoundLambdas()
    found[id] = true
    
    self:SetPData("HLRPG_FoundLambdas", util.TableToJSON(found))
    self.HLRPG_Lambdas = found
end

function meta:GetFoundLambdas()
    if self.HLRPG_Lambdas then return self.HLRPG_Lambdas end
    
    local data = self:GetPData("HLRPG_FoundLambdas")
    if data then
        self.HLRPG_Lambdas = util.JSONToTable(data) or {}
    else
        self.HLRPG_Lambdas = {}
    end
    
    return self.HLRPG_Lambdas
end

function meta:SaveXP(amount)
    local currentXP = self:GetXP()
    local newXP = currentXP + amount
    self:SetPData("HLRPG_XP", newXP)
    self.HLRPG_XP = newXP
    
    self:SetNWInt("HLRPG_XP", newXP)
end

function meta:GetXP()
    if self.HLRPG_XP then return self.HLRPG_XP end
    print("Loading XP for " .. self:Nick())
    self.HLRPG_XP = tonumber(self:GetPData("HLRPG_XP")) or 0
    print("Loaded XP: " .. self.HLRPG_XP)
    return self.HLRPG_XP
end

function meta:SaveLevel(level)
    self:SetPData("HLRPG_Level", level)
    self.HLRPG_Level = level
    
    self:SetNWInt("HLRPG_Level", level)
    
    if HLRPG_GetRequiredXP then
        self:SetNWInt("HLRPG_MaxXP", HLRPG_GetRequiredXP(level))
    end
end

function meta:GetLevel()
    if self.HLRPG_Level then return self.HLRPG_Level end
    self.HLRPG_Level = tonumber(self:GetPData("HLRPG_Level")) or 1
    return self.HLRPG_Level
end

function meta:GetInventory()
    if self.HLRPG_Inventory then return self.HLRPG_Inventory end
    
    local data = self:GetPData("HLRPG_Inventory")
    if data then
        self.HLRPG_Inventory = util.JSONToTable(data) or {}
    else
        self.HLRPG_Inventory = {}
    end
    
    return self.HLRPG_Inventory
end

function meta:SaveInventory()
    local data = util.TableToJSON(self.HLRPG_Inventory or {})
    self:SetPData("HLRPG_Inventory", data)
end

function meta:SyncInventoryToClient()
    local inv = self:GetInventory()
    
    for itemID, owned in pairs(inv) do
        if owned then
            self:SetNWBool("HLRPG_Owned_" .. itemID, true)
        end
    end
end

function meta:SaveAchievements()
    local data = util.TableToJSON(self.UnlockedAchievements or {})
    self:SetPData("HLRPG_Achievements", data)
end

function meta:LoadAchievements()
    local data = self:GetPData("HLRPG_Achievements")
    if data then
        self.UnlockedAchievements = util.JSONToTable(data) or {}
    else
        self.UnlockedAchievements = {}
    end
end

function meta:LoadPetData()
    local rawData = self:GetPData("HLRPG_PetProgress", "{}")
    self.HLRPG_PetStats = util.JSONToTable(rawData) or {}
    
    for petID, data in pairs(self.HLRPG_PetStats) do
        self:SetNWInt("PetLevel_" .. petID, data.level or 1)
        self:SetNWInt("PetXP_" .. petID, data.xp or 0)
        
        local name = self:GetPData("PetName_" .. petID)
        if name then self:SetNWString("HLRPG_CustomName_" .. petID, name) end
        
        local colData = self:GetPData("PetColor_" .. petID)
        if colData then
            local c = util.JSONToTable(colData)
            self:SetNWVector("HLRPG_CustomColorVec_" .. petID, Vector(c[1]/255, c[2]/255, c[3]/255))
        end
    end
end

function meta:SavePetProgress(petID, level, xp)
    self.HLRPG_PetStats = self.HLRPG_PetStats or {}
    self.HLRPG_PetStats[petID] = {
        level = level,
        xp = xp
    }
    
    self:SetPData("HLRPG_PetProgress", util.TableToJSON(self.HLRPG_PetStats))
end

function meta:SavePetCustomization(petID, name, color)
    self:SetPData("PetName_" .. petID, name)
    self:SetPData("PetColor_" .. petID, util.TableToJSON({color.r, color.g, color.b}))
end

function meta:SaveHat()
    local hatID = self.GetNWString(self, "HLRPG_ActiveHat", "none")
    self:SetPData("HLRPG_ActiveHat", hatID)
end

function meta:LoadHat()
    local hatID = self:GetPData("HLRPG_ActiveHat", "none")
    
    HLRPG_ApplyHat(self, hatID)

    return hatID
end

function meta:SaveSuit()
    local suitID = self.GetNWString(self, "HLRPG_ActiveSuit", "none")
    self:SetPData("HLRPG_ActiveSuit", suitID)
end

function meta:LoadSuit()
    local suitID = self:GetPData("HLRPG_ActiveSuit", "none")
    
    HLRPG_ApplyEquipment(self, "suit", suitID)

    return suitID
end

function meta:InitialRPGSetup()
    self:GetXP()        -- Cache'e al
    self:GetLevel()     -- Cache'e al
    self:GetFoundLambdas()
    self:LoadAchievements()
    self:LoadPetData()
    self:GetInventory()
    self:SyncInventoryToClient()
    self:LoadHat()
    self:LoadSuit()
    
    self:SetNWInt("HLRPG_XP", self.HLRPG_XP)
    self:SetNWInt("HLRPG_Level", self.HLRPG_Level)
    if HLRPG_GetRequiredXP then
        self:SetNWInt("HLRPG_MaxXP", HLRPG_GetRequiredXP(self.HLRPG_Level))
    end
    
    print("[HLRPG] " .. self:Nick() .. " için tüm veriler başarıyla yüklendi.")
end