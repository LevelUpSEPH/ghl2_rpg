-- addons/halflife_rpg/lua/hlrpg/modules/cl_xp_notify.lua
if not CLIENT then return end

net.Receive("HLRPG_XPNotify", function()
    local xp = net.ReadInt(32)
    local perc = net.ReadInt(16)
    local name = net.ReadString()
    local npcCol = net.ReadColor()

    -- Renkli Chat Mesajı
    chat.AddText(
        Color(255, 255, 255), "You got ", 
        Color(50, 255, 50), xp .. " xp ",        -- Yeşil XP
        Color(255, 255, 255), "for dealing ", 
        Color(255, 200, 0), perc .. "% ",      -- Sarı Yüzde
        Color(255, 255, 255), "of the damage to ", 
        npcCol, name                           -- Sözlükteki NPC Rengi
    )
end)