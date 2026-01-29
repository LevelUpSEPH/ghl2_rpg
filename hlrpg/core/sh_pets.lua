-- sh_pets.lua
HLRPG = HLRPG or {}

HLRPG.PetData = {
    ["pet_headcrab"] = {
        Evolutions = {
            [0] = { 
                class = "npc_headcrab", name = "Yavru Headcrab", 
                baseHealth = 50, healthPerLevel = 10,
                dmgMultiplier = 10.0, evolutionThreshold = 2,
                xpRequired = 1, xpIncreasePerLevel = 1
            },
            [2] = { 
                class = "npc_zombie_torso", name = "Sürünen Gövde", 
                baseHealth = 150, healthPerLevel = 20,
                dmgMultiplier = 1.5, evolutionThreshold = 10,
                xpRequired = 25, xpIncreasePerLevel = 10
            },
            [15] = { 
                class = "npc_zombine", name = "Zombine", 
                baseHealth = 800, healthPerLevel = 60,
                dmgMultiplier = 3.5,
                xpRequired = 60, xpIncreasePerLevel = 20,
                OnSpawn = function(pet) pet:SetInternalVariable("m_iNumGrenades", 0) end -- Bomba yasağı
            }
        }
    },
    ["pet_antlion"] = {
        Evolutions = {
            [0] = { 
                class = "npc_antlion_worker", name = "Yavru Antlion", 
                baseHealth = 80, healthPerLevel = 15,
                dmgMultiplier = 1.2, evolutionThreshold = 5,
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
    }
}

function HLRPG_GetPlayerPetRequiredXP(ply, petID)
    if not IsValid(ply) or not petID or petID == "none" then return 100 end
    local stage = ply:GetNWInt("PetStage_" .. petID, 0)
    local level = ply:GetNWInt("PetLevel_" .. petID, 1)
    local pData = HLRPG.PetData[petID]
    local evo = pData and pData.Evolutions[stage]
    if not evo then return 100 end
    return evo.xpRequired + ((level - 1) * evo.xpIncreasePerLevel)
end