-- hlrpg/core/sh_pets.lua
-- Evolutions are keyed by the pet level they unlock at. A pet uses the highest stage it has reached.
-- Optional per evolution: modelScale, weapon, OnSpawn(pet), OnThink(pet, owner).

HLRPG.PetData = {
    ["pet_headcrab"] = {
        Evolutions = {
            [1] = {
                class = "npc_headcrab", name = "Parasyte",
                baseHealth = 100, healthPerLevel = 15,
                dmgMultiplier = 1.0,
                xpRequired = 3, xpIncreasePerLevel = 2
            },
            [5] = {
                class = "npc_zombie_torso", name = "Half Baked",
                baseHealth = 400, healthPerLevel = 40,
                dmgMultiplier = 2.0,
                xpRequired = 15, xpIncreasePerLevel = 4
            },
            [12] = {
                class = "npc_zombie", name = "Full Deal",
                baseHealth = 800, healthPerLevel = 70,
                dmgMultiplier = 3.5,
                xpRequired = 40, xpIncreasePerLevel = 8
            },
            [20] = {
                class = "npc_zombine", name = "Comzine",
                baseHealth = 5000, healthPerLevel = 400,
                dmgMultiplier = 8.0,
                xpRequired = 150, xpIncreasePerLevel = 30
            }
        }
    },
    ["pet_antlion"] = {
        Evolutions = {
            [1] = {
                class = "npc_antlion", name = "Bee",
                baseHealth = 150, healthPerLevel = 25,
                dmgMultiplier = 1.2,
                xpRequired = 5, xpIncreasePerLevel = 2,
                modelScale = 0.7
            },
            [7] = {
                class = "npc_antlion_worker", name = "Bee",
                baseHealth = 150, healthPerLevel = 25,
                dmgMultiplier = 1.2,
                xpRequired = 30, xpIncreasePerLevel = 5,
                modelScale = 0.7
            },
            [15] = {
                class = "npc_antlionguard", name = "Antlion Guardian",
                modelScale = 0.5,
                baseHealth = 3000, healthPerLevel = 300,
                dmgMultiplier = 6.0,
                xpRequired = 100, xpIncreasePerLevel = 25
            }
        }
    },
    ["pet_rollermine"] = {
        Evolutions = {
            [1] = {
                class = "npc_rollermine", name = "Scout Drone",
                baseHealth = 80, healthPerLevel = 10,
                dmgMultiplier = 1.0,
                xpRequired = 10, xpIncreasePerLevel = 3
            },
            [6] = {
                class = "npc_metropolice", name = "Metro Police",
                weapon = "weapon_pistol",
                baseHealth = 350, healthPerLevel = 30,
                dmgMultiplier = 1.8,
                xpRequired = 25, xpIncreasePerLevel = 6
            },
            [10] = {
                class = "npc_combine_s", name = "Combine Soldier",
                weapon = "weapon_smg1",
                baseHealth = 700, healthPerLevel = 60,
                dmgMultiplier = 2.5,
                xpRequired = 50, xpIncreasePerLevel = 8
            },
            [14] = {
                class = "npc_combine_s", name = "Combine Elite",
                weapon = "weapon_ar2",
                modelScale = 1.1,
                baseHealth = 1200, healthPerLevel = 100,
                dmgMultiplier = 4.0,
                xpRequired = 500, xpIncreasePerLevel = 100
            },
            [20] = {
                class = "npc_hunter", name = "Hunter Unit",
                modelScale = 0.6,
                baseHealth = 4500, healthPerLevel = 500,
                dmgMultiplier = 7.0,
                xpRequired = 3000, xpIncreasePerLevel = 700
            }
        }
    },
    ["pet_vortigaunt"] = {
        Evolutions = {
            [1] = {
                class = "npc_vortigaunt", name = "Vortigaunt",
                modelScale = 0.8,
                baseHealth = 200, healthPerLevel = 20,
                dmgMultiplier = 1.0,
                xpRequired = 15, xpIncreasePerLevel = 5
            },
            [8] = {
                class = "npc_vortigaunt", name = "Elder Vortigaunt",
                modelScale = 1,
                baseHealth = 800, healthPerLevel = 80,
                dmgMultiplier = 2.5,
                xpRequired = 60, xpIncreasePerLevel = 15
            },
            [16] = {
                class = "npc_vortigaunt", name = "Vortigaunt Champion",
                modelScale = 1.5,
                baseHealth = 3000, healthPerLevel = 250,
                dmgMultiplier = 5.0,
                xpRequired = 200, xpIncreasePerLevel = 50
            }
        }
    }
}

-- Returns the evolution stage (the level key in Evolutions) for a pet at the given level, or 0
function HLRPG.GetPetEvolutionStage(petID, level)
    local pData = HLRPG.PetData[petID]
    if not pData then return 0 end

    local activeStage = 0
    for stageLevel in pairs(pData.Evolutions) do
        if level >= stageLevel and stageLevel >= activeStage then
            activeStage = stageLevel
        end
    end
    return activeStage
end

function HLRPG.GetPetEvolution(petID, level)
    local pData = HLRPG.PetData[petID]
    local stage = HLRPG.GetPetEvolutionStage(petID, level)
    return pData and pData.Evolutions[stage], stage
end

-- Kills needed for the pet to reach its next level
function HLRPG.GetPetRequiredXP(petID, level)
    local evo, stage = HLRPG.GetPetEvolution(petID, level)
    if not evo then return 100 end

    return math.max(1, evo.xpRequired + ((level - stage) * evo.xpIncreasePerLevel))
end
