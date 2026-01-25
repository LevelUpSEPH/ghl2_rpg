-- addons/halflife_rpg/lua/hlrpg/modules/sv_player_cleanup.lua
if not SERVER then return end

hook.Add("PlayerDeath", "HLRPG_AdvancedCleanup", function(ply, inflictor, attacker)
    -- GMod'un oluşturduğu ragdoll'u yakala
    -- Not: 'ragdoll' parametresi bazı sürümlerde 4. argüman olabilir, 
    -- garantiye almak için timer içinde kontrol edeceğiz.
    
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        
        local corpse = ply:GetRagdollEntity()
        
        if IsValid(corpse) then
            -- 1. Görsel Efekt (Kaybolma hissi için)
            local ed = EffectData()
            ed:SetOrigin(corpse:GetPos())
            ed:SetEntity(corpse)
            util.Effect("EntityDissolve", ed) -- Dağılma efekti

            -- 2. Zamanlı Silme (Oyuncunun ölümü görmesi için 2 saniye bekler)
            timer.Simple(2, function()
                if IsValid(corpse) then
                    corpse:Remove()
                end
            end)
        else
            -- EĞER RAGDOLL BULUNAMADIYSA (Multiplayer Bug Fix)
            -- Bazen ragdoll geç oluşur, çevredeki sınıfsız ragdoll'ları tara
            for _, ent in ipairs(ents.FindByClass("class GMOD_PlayerCorpse")) do
                if ent:GetPos():DistToSqr(ply:GetPos()) < 10000 then -- Yakınındakini sil
                    ent:Remove()
                end
            end
        end
    end)
end)

-- EKSTRA GÜVENLİK: Harita çok kirlenirse diye her 60 saniyede bir sahipsiz cesetleri temizle
timer.Create("HLRPG_GlobalCleanup", 60, 0, function()
    for _, ent in ipairs(ents.FindByClass("class GMOD_PlayerCorpse")) do
        ent:Remove()
    end
end)