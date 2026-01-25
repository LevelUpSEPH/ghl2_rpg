-- addons/halflife_rpg/lua/hlrpg/modules/cl_hud.lua

if not CLIENT then return end

-- Fontlar
surface.CreateFont("HLRPG_HUD_Bold", { font = "Verdana", size = 14, weight = 800, antialias = true })
surface.CreateFont("HLRPG_HUD_XP", { font = "Verdana", size = 12, weight = 700, antialias = true })

hook.Add("HUDPaint", "HLRPG_StrictHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    -- Veriler
    local ult = ply:GetNWInt("HLRPG_UltCharge", 0)
    local xp = ply:GetNWInt("HLRPG_XP", 0)
    local lvl = ply:GetNWInt("HLRPG_Level", 1)

    -- 1. XP BAR (Ekranın En Altı)
    local xpBarH = 18
    local xpY = ScrH() - xpBarH
    
    -- XP Arka Plan
    surface.SetDrawColor(0, 0, 0, 180)
    surface.DrawRect(0, xpY, ScrW(), xpBarH)
    
    -- XP Doluluk (Yeşil)
    surface.SetDrawColor(50, 200, 50, 150)
    surface.DrawRect(0, xpY, ScrW() * (xp / 100), xpBarH)
    
    -- Level Yazısı (Barın üzerine ortalanmış)
    draw.SimpleText("LEVEL " .. lvl .. " - PROGRESS: %" .. math.floor(xp), "HLRPG_HUD_XP", ScrW() / 2, xpY + 2, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER)


    -- 2. ULT BAR (Health ve Armor Üstünde Hizalı)
    -- Vanilla Health genelde 40-50 pikselden başlar.
    local ultW = 180 -- Vanilla HUD'ın yaklaşık genişliği
    local ultH = 8
    local ultX = 40  -- Vanilla Health ile aynı hizada
    local ultY = ScrH() - 110 -- Health ve Armor sayılarının tam üstü
    
    -- Ult Arka Plan
    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(ultX, ultY, ultW, ultH)
    
    -- Ult Doluluk (Kondansatör Mavisi/Turuncusu)
    local isReady = ult >= 100
    local ultColor = isReady and Color(0, 255, 255) or Color(255, 120, 0)
    
    surface.SetDrawColor(ultColor)
    surface.DrawRect(ultX, ultY, ultW * (ult / 100), ultH)
    
    -- Warp Cannon Yazısı (Barın üstünde küçük)
    local status = isReady and "STRIDER CORE: READY" or "CORE CHARGE: %" .. math.floor(ult)
    draw.SimpleText(status, "HLRPG_HUD_Bold", ultX, ultY - 18, ultColor)
    
    -- Eğer hazırsa barın parlaması için ince bir çizgi daha
    if isReady then
        surface.SetDrawColor(255, 255, 255, math.abs(math.sin(CurTime() * 10) * 150))
        surface.DrawOutlinedRect(ultX - 1, ultY - 1, ultW + 2, ultH + 2)
    end
end)