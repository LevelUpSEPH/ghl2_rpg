-- lua/hlrpg/core/sv_player.lua

-- Server tarafında olduğumuzu garantileyelim
if not SERVER then return end

print("[HLRPG] Player modulu yuklendi.")

-- Oyuncu oyuna girince (Roblox'taki PlayerAdded)
hook.Add("PlayerInitialSpawn", "HLRPG_IlkGiris", function(ply)
    -- Oyuncunun üzerine geçici olarak veri ekleyelim
    ply.HLRPG_XP = 0
    ply.HLRPG_Level = 1
    
    ply:ChatPrint("Sunucuya hos geldin! Su an Seviyen: " .. ply.HLRPG_Level)
end)

-- Konsol komutu: XP Ekleme Testi
concommand.Add("hlrpg_xp_ver", function(ply, cmd, args)
    -- Eğer komutu yazan geçerli bir oyuncuysa
    if IsValid(ply) then
        local miktar = 100
        ply.HLRPG_XP = ply.HLRPG_XP + miktar
        
        ply:ChatPrint("Tebrikler! " .. miktar .. " XP kazandın. Toplam: " .. ply.HLRPG_XP)
    end
end)