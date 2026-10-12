-- hlrpg/modules/sv_player_cleanup.lua
-- Dissolves player corpses shortly after death so maps don't fill up with ragdolls.

local CORPSE_CLASS = "class GMOD_PlayerCorpse"

hook.Add("PlayerDeath", "HLRPG_AdvancedCleanup", function(ply, inflictor, attacker)
    -- The ragdoll may not exist yet when this hook runs
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end

        local corpse = ply:GetRagdollEntity()

        if IsValid(corpse) then
            local ed = EffectData()
            ed:SetOrigin(corpse:GetPos())
            ed:SetEntity(corpse)
            util.Effect("EntityDissolve", ed)

            SafeRemoveEntityDelayed(corpse, 2)
        else
            for _, ent in ipairs(ents.FindByClass(CORPSE_CLASS)) do
                if ent:GetPos():DistToSqr(ply:GetPos()) < 10000 then
                    ent:Remove()
                end
            end
        end
    end)
end)

timer.Create("HLRPG_GlobalCleanup", 60, 0, function()
    for _, ent in ipairs(ents.FindByClass(CORPSE_CLASS)) do
        ent:Remove()
    end
end)
