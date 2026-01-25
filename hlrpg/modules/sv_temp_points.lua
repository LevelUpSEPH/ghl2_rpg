-- addons/halflife_rpg/lua/hlrpg/modules/sv_temp_points.lua
if not SERVER then return end

-- Oyuncu ilk katıldığında puanını sıfırla
hook.Add("PlayerInitialSpawn", "HLRPG_InitTempPoints", function(ply)
    ply.HLRPG_TempPoints = 0
    ply:SetNWInt("HLRPG_TempPoints", 0)
end)

-- XP kazanıldığında Temp Point de ekle
-- sv_rpg_system.lua içindeki xpGain kısmından sonra bunu tetikleyeceğiz
function HLRPG_AddTempPoints(ply, amount)
    if not IsValid(ply) then return end
    
    -- Örnek: Kazanılan her 10 XP için 1 Temp Point (Oranı istediğin gibi değiştirebilirsin)
    local pointGain = math.floor(amount / 5) 
    
    if pointGain > 0 then
        ply.HLRPG_TempPoints = (ply.HLRPG_TempPoints or 0) + pointGain
        ply:SetNWInt("HLRPG_TempPoints", ply.HLRPG_TempPoints)
        
        -- Hafif bir ses efekti (Sadece oyuncuya)
        ply:SendLua([[surface.PlaySound("buttons/lightswitch2.wav")]])
    end
end