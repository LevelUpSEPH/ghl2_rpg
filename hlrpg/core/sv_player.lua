-- addons/halflife_rpg/lua/hlrpg/core/sv_player.lua

if not SERVER then return end

print("[HLRPG] Player Manager Loading...")

hook.Add("PlayerInitialSpawn", "HLRPG_InitialLoad", function(ply)
    timer.Create("HLRPG_InitTimer_" .. ply:UserID(), 0.5, 5, function()
        if not IsValid(ply) then return end
        
        if ply.InitialRPGSetup then
            ply:InitialRPGSetup()
            timer.Remove("HLRPG_InitTimer_" .. ply:UserID()) -- Başarılı, timer'ı durdur
            
            local level = ply.HLRPG_Level or 1
            ply:ChatPrint(">>> Hoş geldin, " .. ply:Nick() .. "! Veriler yüklendi. (Seviye: " .. level .. ")")
        else
            print("[HLRPG] Database bekleniyor... " .. ply:Nick())
        end
    end)
end)