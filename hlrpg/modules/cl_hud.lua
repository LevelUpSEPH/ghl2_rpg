-- addons/halflife_rpg/lua/hlrpg/modules/cl_hud.lua

if not CLIENT then return end

-- Fontlar (Yüklenmediyse hata vermemesi için tekrar tanımlıyoruz)
surface.CreateFont("HLRPG_HUD_Bold", { font = "Verdana", size = 14, weight = 800, antialias = true })
surface.CreateFont("HLRPG_HUD_XP", { font = "Verdana", size = 12, weight = 700, antialias = true })

hook.Add("HUDPaint", "HLRPG_StrictHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    -- 1. VERİLERİ ÇEK
    local ult = ply:GetNWInt("HLRPG_UltCharge", 0)
    local xp = ply:GetNWInt("HLRPG_XP", 0)
    local lvl = ply:GetNWInt("HLRPG_Level", 1)
    
    -- Senin sistemindeki XP sınırı: Level * 100
    local maxXP = ply:GetNWInt("HLRPG_MaxXP", lvl * 100)
    if maxXP <= 0 then maxXP = 100 end -- 0'a bölme hatası koruması
    
    local xpPercent = math.Clamp(xp / maxXP, 0, 1)

    -- 2. XP BAR (Ekranın En Altı)
    local xpBarH = 18
    local xpY = ScrH() - xpBarH
    
    -- XP Arka Plan (Siyah Şerit)
    surface.SetDrawColor(0, 0, 0, 180)
    surface.DrawRect(0, xpY, ScrW(), xpBarH)
    
    -- XP Doluluk (Yeşil)
    surface.SetDrawColor(50, 200, 50, 150)
    surface.DrawRect(0, xpY, ScrW() * xpPercent, xpBarH)
    
    -- [GÜNCELLENDİ] Progress Yazısı (Barın tam üstünde ve ortasında)
    local progressValue = math.floor(xpPercent * 100)
    local xpText = "LEVEL " .. lvl .. " - PROGRESS: %" .. progressValue .. " (" .. xp .. "/" .. maxXP .. ")"
    
    draw.SimpleText(xpText, "HLRPG_HUD_XP", (ScrW() / 2) + 1, xpY + 3, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER) -- Gölge
    draw.SimpleText(xpText, "HLRPG_HUD_XP", ScrW() / 2, xpY + 2, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER)

    local diffLevel = GetGlobalInt("HLRPG_CurrentDifficulty", 1)
    local diffData = (HLRPG_DifficultyScales and HLRPG_DifficultyScales[diffLevel]) 

    if diffData then
        draw.SimpleText("MODE: " .. diffData.name, "HLRPG_HUD_Bold", 20, ScrH() - 40, diffData.color, TEXT_ALIGN_LEFT)
    else
        draw.SimpleText("MODE: INITIALIZING...", "HLRPG_HUD_Bold", 20, ScrH() - 40, Color(255,255,255), TEXT_ALIGN_LEFT)
    end

    -- 3. ULT BAR (Health ve Armor Üstünde Hizalı)
    local ultW = 180 
    local ultH = 8
    local ultX = 40  
    local ultY = ScrH() - 110 -- Vanilla can değerlerinin üstü
    
    -- Ult Arka Plan
    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(ultX, ultY, ultW, ultH)
    
    -- Ult Doluluk (Hazırsa Mavi, Doluyorsa Turuncu)
    local isReady = ult >= 100
    local ultColor = isReady and Color(0, 255, 255) or Color(255, 120, 0)
    
    surface.SetDrawColor(ultColor)
    surface.DrawRect(ultX, ultY, ultW * (math.Clamp(ult, 0, 100) / 100), ultH)
    
    -- Warp Cannon Yazısı
    local status = isReady and "STRIDER CORE: READY" or "CORE CHARGE: %" .. math.floor(ult)
    draw.SimpleText(status, "HLRPG_HUD_Bold", ultX, ultY - 18, ultColor)
    
    -- Hazır Parlama Efekti
    if isReady then
        surface.SetDrawColor(255, 255, 255, math.abs(math.sin(CurTime() * 10) * 150))
        surface.DrawOutlinedRect(ultX - 1, ultY - 1, ultW + 2, ultH + 2)
    end
end)