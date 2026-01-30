-- sh_pets.lua
HLRPG = HLRPG or {}

HLRPG.PetData = {
    ["pet_headcrab"] = {
        Evolutions = {
            [1] = { 
                class = "npc_headcrab", name = "Yavru Headcrab", 
                baseHealth = 50, healthPerLevel = 10,
                dmgMultiplier = 10.0, evolutionThreshold = 2,
                xpRequired = 1, xpIncreasePerLevel = 1
            },
            [2] = { 
                class = "npc_zombie_torso", name = "Sürünen Gövde", 
                baseHealth = 150, healthPerLevel = 20,
                dmgMultiplier = 1.5, evolutionThreshold = 3,
                xpRequired = 1, xpIncreasePerLevel = 10
            },
            [3] = { 
                class = "npc_zombine", name = "Zombine", 
                baseHealth = 800, healthPerLevel = 60,
                dmgMultiplier = 3.5,
                xpRequired = 60, xpIncreasePerLevel = 20,
                OnSpawn = function(pet) pet:SetInternalVariable("m_iNumGrenades", 0) end -- Bomba yasağı
            },
            [20] = { 
                class = "npc_zombine", name = "Zombine", 
                baseHealth = 20000,
                dmgMultiplier = 5,
                xpRequired = 60, xpIncreasePerLevel = 20,
                OnSpawn = function(pet) pet:SetInternalVariable("m_iNumGrenades", 0) end -- Bomba yasağı
            }
        }
    },
    ["pet_antlion"] = {
        Evolutions = {
            [1] = { 
                class = "npc_antlion_worker", name = "Yavru Antlion", 
                baseHealth = 80, healthPerLevel = 15,
                dmgMultiplier = 1.2,
                xpRequired = 12, xpIncreasePerLevel = 6,
                OnEnemyFound = function(pet, enemy)
                    local dist = pet:GetPos():Distance(enemy:GetPos())
                    if dist > 200 then pet:SetSchedule(SCHED_RANGE_ATTACK1) end -- Asit önceliği
                end
            },
            [10] = { 
                class = "npc_antlion_guard", name = "Koruyucu Antlion", 
                baseHealth = 500, healthPerLevel = 50,
                dmgMultiplier = 4.0,
                xpRequired = 50, xpIncreasePerLevel = 18
            }
        }
    },
    ["pet_rollermine"] = {
        Evolutions = {
            [1] = { 
                class = "npc_rollermine", name = "Combine Er", 
                baseHealth = 100, healthPerLevel = 20,
                dmgMultiplier = 1.0, evolutionThreshold = 1,
                xpRequired = 1, xpIncreasePerLevel = 7
            },
            [2] = { 
                class = "npc_combine_s", name = "Combine Er", 
                modelScale = 0.5,
                weapon = "weapon_smg1", -- Silah burada tanımlı
                baseHealth = 100, healthPerLevel = 20,
                dmgMultiplier = 1.0, evolutionThreshold = 1,
                xpRequired = 1, xpIncreasePerLevel = 7
            },
            [3] = { 
                class = "npc_combine_s", name = "Combine Elite", 
                modelScale = 0.5,
                weapon = "weapon_ar2", -- Evrimleşince silah değişir
                baseHealth = 250, healthPerLevel = 30,
                dmgMultiplier = 2.0, evolutionThreshold = 1,
                xpRequired = 1, xpIncreasePerLevel = 14
            },
            [4] = { 
                class = "npc_hunter", name = "Combine Komutan",
                modelScale = 0.5,
                baseHealth = 600, healthPerLevel = 50,
                dmgMultiplier = 3.5,
                xpRequired = 80, xpIncreasePerLevel = 25
            },
            [100] = { 
                class = "npc_hunter", name = "Combine Komutan",
                modelScale = 0.5,
                baseHealth = 600, healthPerLevel = 50,
                dmgMultiplier = 3.5,
                xpRequired = 80, xpIncreasePerLevel = 25
            }
        }
    }
}

function HLRPG_GetPlayerPetRequiredXP(ply, petID)
    if not IsValid(ply) or not petID or petID == "none" then return 100 end
    
    local level = ply:GetNWInt("PetLevel_" .. petID, 1)
    
    local stage = HLRPG_GetPetEvolutionStage(petID, level)
    local pData = HLRPG.PetData[petID]
    local evo = pData and pData.Evolutions[stage]
    
    if not evo then return 100 end
    
    local relativeLevel = level - stage
    local requiredXP = evo.xpRequired + (relativeLevel * evo.xpIncreasePerLevel)
    
    return math.max(1, requiredXP)
end

function HLRPG_GetPetEvolutionStage(petID, currentLevel)
    local pData = HLRPG.PetData[petID]
    if not pData then return 0 end

    local activeStage = 0
    for stageLevel, _ in pairs(pData.Evolutions) do
        if currentLevel >= stageLevel and stageLevel >= activeStage then
            activeStage = stageLevel
        end
    end
    return activeStage
end