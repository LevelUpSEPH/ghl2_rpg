-- addons/halflife_rpg/lua/hlrpg/modules/sv_modifier_manager.lua

if not SERVER then return end

local meta = FindMetaTable("Player")

function meta:InitModifiers()
    self.RPG_Mods = { Global = {} }
end
hook.Add("PlayerInitialSpawn", "HLRPG_InitMods", function(ply) ply:InitModifiers() end)

-- =========================================================
-- MODIFIER EKLEME
-- =========================================================
function meta:AddRPGModifier(modID, value, scope)
    self.RPG_Mods = self.RPG_Mods or { Global = {} }
    
    local category = scope or "Global"
    
    if not self.RPG_Mods[category] then
        self.RPG_Mods[category] = {}
    end
    
    self.RPG_Mods[category][modID] = value
    -- Debug kapatıldı (Spam olmasın)
    -- print(string.format("[RPG SYS] Eklendi: %s | Scope: %s | Val: %s", modID, category, tostring(value)))
end

-- =========================================================
-- MODIFIER SİLME
-- =========================================================
function meta:RemoveRPGModifier(modID, scope)
    if not self.RPG_Mods then return false end
    
    local category = scope or "Global"
    
    if self.RPG_Mods[category] and self.RPG_Mods[category][modID] then
        self.RPG_Mods[category][modID] = nil
        
        if table.Count(self.RPG_Mods[category]) == 0 then
            self.RPG_Mods[category] = nil
        end
        return true 
    end
    return false 
end

-- =========================================================
-- HESAPLAMA (Tüm listeyi döndürür)
-- =========================================================
function meta:GetCalculatedModifiers(activeWeaponClass)
    if not self.RPG_Mods then return {} end
    
    local finalMods = {}
    
    -- 1. Global
    if self.RPG_Mods["Global"] then
        for modID, val in pairs(self.RPG_Mods["Global"]) do
            finalMods[modID] = val
        end
    end
    
    -- 2. Silah Özel
    if activeWeaponClass and self.RPG_Mods[activeWeaponClass] then
        for modID, val in pairs(self.RPG_Mods[activeWeaponClass]) do
            finalMods[modID] = val 
        end
    end
    
    return finalMods
end

-- =========================================================
-- TEKİL DEĞER GETİRME (EKSİK OLAN PARÇA BU!)
-- =========================================================
-- Skill sistemi ve diğer sistemler tek bir modifier'ın değerini 
-- hızlıca öğrenmek için bunu kullanır.
function meta:GetModifierVal(modID)
    -- Elindeki silaha bak
    local wep = self:GetActiveWeapon()
    local cls = IsValid(wep) and wep:GetClass() or nil
    
    -- Hesaplamayı yap
    local mods = self:GetCalculatedModifiers(cls)
    
    -- İstenen modifier varsa değerini, yoksa nil döndür
    return mods[modID]
end

-- addons/halflife_rpg/lua/hlrpg/modules/sv_modifier_manager.lua (EN ALTA EKLE)

-- Şarjı ayarla ve sınırla (0-100)
function meta:SetUltCharge(val)
    self:SetNWInt("HLRPG_UltCharge", math.Clamp(val, 0, 100))
end

function meta:GetUltCharge()
    return self:GetNWInt("HLRPG_UltCharge", 0)
end

function meta:AddUltCharge(val)
    local current = self:GetUltCharge()
    self:SetUltCharge(current + val)
    
    -- %100 olduğunda sesli uyarı (Opsiyonel)
    if current < 100 and self:GetUltCharge() >= 100 then
        self:EmitSound("buttons/combine_button7.wav", 70, 120)
        self:ChatPrint(">>> WARP CANNON HAZIR <<<")
    end
end

hook.Add("OnNPCKilled", "HLRPG_ChargeOnKillNPC", function(npc, attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() then
        -- Eğer oyuncu o an Warp Cannon kullanmıyorsa şarj ekle
        if not attacker:GetNWBool("HLRPG_IsCastingUlt", false) then
            -- NPC başına %10-15 arası rastgele şarj (Dengelemek için değiştirebilirsin)
            attacker:AddUltCharge(math.random(10, 15))
        end
    end
end)

-- =========================================================
-- TEST KOMUTLARI
-- =========================================================
concommand.Add("rpg_add", function(ply, cmd, args)
    if not IsValid(ply) then return end
    local modID = args[1]
    local val = tonumber(args[2]) or 1
    local scope = args[3] 
    if not modID then return end
    
    ply:AddRPGModifier(modID, val, scope)
    ply:ChatPrint("Eklendi: " .. modID)
end)

concommand.Add("rpg_rem", function(ply, cmd, args)
    if not IsValid(ply) then return end
    local modID = args[1]
    local scope = args[2] 
    if not modID then return end
    
    local success = ply:RemoveRPGModifier(modID, scope)
    if success then ply:ChatPrint("Silindi: " .. modID) else ply:ChatPrint("Bulunamadı.") end
end)

concommand.Add("rpg_status", function(ply)
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    local cls = IsValid(wep) and wep:GetClass() or "Yok"
    ply:ChatPrint("--- DURUM: " .. cls .. " ---")
    local mods = ply:GetCalculatedModifiers(cls)
    for k, v in pairs(mods) do ply:ChatPrint(k .. " = " .. tostring(v)) end
end)