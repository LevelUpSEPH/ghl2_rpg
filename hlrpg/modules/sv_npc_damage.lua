-- addons/halflife_rpg/lua/hlrpg/modules/sv_npc_damage.lua
if not SERVER then return end

hook.Add("EntityTakeDamage", "HLRPG_NPC_Damage_Scaling", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()

    -- Sadece bir NPC oyuncuya (veya başka bir şeye) saldırıyorsa
    if IsValid(attacker) and attacker:IsNPC() then
        
        -- NPC'nin üzerindeki Level'ı al (ScaleNPC'de atamıştık)
        local npcLevel = attacker:GetNWInt("HLRPG_NPCLevel", 1)
        
        -- Merkezi stat hesaplama fonksiyonumuzu çağıralım
        -- Bu fonksiyon hem Difficulty mult'u hem de Level bonusunu hesaba katar
        if HLRPG_CalculateStat then
            local baseDamage = dmginfo:GetDamage()
            local scaledDamage = HLRPG_CalculateStat(baseDamage, "DMG", npcLevel)
            
            -- Eğer Boss ise (Strider vb) hasarı bir kez daha katla
            if attacker:GetNWBool("HLRPG_IsBoss") then
                scaledDamage = scaledDamage * 1.5
            end

            dmginfo:SetDamage(scaledDamage)
        end
    end
end)