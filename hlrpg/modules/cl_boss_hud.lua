-- addons/halflife_rpg/lua/hlrpg/modules/cl_boss_hud.lua
if not CLIENT then return end

local activeBosses = {}

-- Fontlar
surface.CreateFont("HLRPG_BossName", { font = "Verdana", size = 13, weight = 800, antialias = true })
surface.CreateFont("HLRPG_BossPerc", { font = "Verdana", size = 11, weight = 700, antialias = true })

hook.Add("HUDPaint", "HLRPG_MultiBossHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- 1. YAKINDAKİ BOSS'LARI TESPİT ET
    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 3000)) do
        if IsValid(ent) and ent:IsNPC() and not ent:GetNWBool("HLRPG_ISPET", false) and ent:GetNWBool("HLRPG_IsBoss") and ent:Health() > 0 then
            activeBosses[ent:EntIndex()] = ent
        end
    end

    -- 2. LİSTEYİ TEMİZLE VE ÇİZ
    local yOffset = 0
    local startY = 120 -- Ulti barının biraz altından başlasın
    
    for id, boss in pairs(activeBosses) do
        -- Mesafe veya canlılık kontrolü
        if not IsValid(boss) or boss:Health() <= 0 or boss:GetPos():DistToSqr(ply:GetPos()) > 4000000 then
            activeBosses[id] = nil
            continue
        end

        -- Çizim Ayarları (Sağ Taraf)
        local w, h = 180, 30
        local x = ScrW() - w - 25
        local y = startY + yOffset
        
        local hp = boss:Health()
        local max = boss:GetMaxHealth()
        local hpPerc = math.Clamp(hp / max, 0, 1)
        local displayPerc = math.ceil(hpPerc * 100) -- Yüzdeyi yukarı yuvarla
        
        -- 1. Arka Plan Kutusu
        draw.RoundedBox(4, x, y, w, h, Color(0, 0, 0, 180))
        
        -- 2. Can Barı (Kırmızı degrade veya koyu kırmızı)
        surface.SetDrawColor(40, 0, 0, 200) -- Bar arka planı
        surface.DrawRect(x + 5, y + 18, w - 10, 7)
        
        surface.SetDrawColor(200, 30, 30, 255) -- Aktif can
        surface.DrawRect(x + 5, y + 18, (w - 10) * hpPerc, 7)

        -- 3. Yazılar
        local name = HLRPG_GetNPCName(boss) or boss:GetClass():gsub("npc_", ""):upper()
        
        -- İsim (Sol Üst)
        draw.SimpleText(name, "HLRPG_BossName", x + 5, y + 3, Color(255, 255, 255, 255))
        
        -- Yüzdelik (Sağ Üst - % işaretiyle)
        local percColor = Color(255, 255, 255)
        if displayPerc <= 20 then percColor = Color(255, 50, 50) end -- Kritik can kırmızı yansın
        
        draw.SimpleText("%" .. displayPerc, "HLRPG_BossPerc", x + w - 5, y + 3, percColor, TEXT_ALIGN_RIGHT)

        yOffset = yOffset + h + 8 -- Bir sonraki Boss barı için boşluk
    end
end)