-- addons/halflife_rpg/lua/hlrpg/modules/sv_temp_points.lua
if not SERVER then return end

hook.Add("PlayerInitialSpawn", "HLRPG_InitTempPoints", function(ply)
    ply.HLRPG_TempPoints = 0
    ply:SetNWInt("HLRPG_TempPoints", 0)
end)

function HLRPG_AddTempPoints(ply, amount)
    if not IsValid(ply) then return end
    
    local pointGain = math.floor(amount / 5) 
    
    if pointGain > 0 then
        ply.HLRPG_TempPoints = (ply.HLRPG_TempPoints or 0) + pointGain
        ply:SetNWInt("HLRPG_TempPoints", ply.HLRPG_TempPoints)
        
        ply:SendLua([[surface.PlaySound("buttons/lightswitch2.wav")]])
    end
end