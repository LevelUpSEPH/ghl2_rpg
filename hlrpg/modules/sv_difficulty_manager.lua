-- addons/halflife_rpg/lua/hlrpg/modules/sv_difficulty_manager.lua
if not SERVER then return end

-- addons/halflife_rpg/lua/hlrpg/modules/sv_difficulty_manager.lua

function HLRPG_SetDifficulty(level)
    level = math.Clamp(tonumber(level) or 1, 1, table.Count(HLRPG_DifficultyScales))
    SetGlobalInt("HLRPG_CurrentDifficulty", level)
    
    local diffData = HLRPG_DifficultyScales[level]

    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:IsNPC() then
            
            if ent:Health() == ent:GetMaxHealth() then
                
                local randomLvl = math.random(diffData.minLvl, diffData.maxLvl)
                ent:SetNWInt("HLRPG_NPCLevel", randomLvl)

                if ScaleNPC then 
                    ScaleNPC(ent) 
                end
            end
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        ply:PrintMessage(HUD_PRINTCENTER, "DÜNYA SEVİYESİ: " .. diffData.name:upper())
    end
end

hook.Add("PlayerSay", "HLRPG_DifficultyCommands", function(ply, text)
    if string.StartWith(text, "!setdiff") then
        if not ply:IsAdmin() then 
            ply:ChatPrint("Yetkiniz yok.")
            return "" 
        end
        local args = string.Explode(" ", text)
        HLRPG_SetDifficulty(args[2])
        return ""
    end
end)