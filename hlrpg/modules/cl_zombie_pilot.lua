-- addons/halflife_rpg/lua/hlrpg/modules/cl_zombie_pilot.lua
hook.Add("CalcView", "HLRPG_ZombieChaseCam", function(ply, pos, angles, fov)
    if ply:GetNWBool("HLRPG_InZombieForm") then
        local npc = ply:GetNWEntity("HLRPG_PilotedZombie")
        if IsValid(npc) then
            local view = {}
            local targetPos = npc:GetPos() + Vector(0, 0, 70)
            
            view.origin = targetPos - (angles:Forward() * 150) + (angles:Up() * 30)
            view.angles = angles
            view.drawviewer = true
            
            local tr = util.TraceLine({start = targetPos, endpos = view.origin, filter = {ply, npc}})
            view.origin = tr.HitPos + tr.Normal * 5
            
            return view
        end
    end
end)