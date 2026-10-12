-- hlrpg/ui/cl_zombie_pilot.lua
-- Third-person camera and input lockout while piloting a zombie (see sv_zombie_pilot.lua).

local function InZombieForm(ply)
    return ply:GetNWBool("HLRPG_InZombieForm")
end

hook.Add("CalcView", "HLRPG_ZombieChaseCam", function(ply, pos, angles, fov)
    if not InZombieForm(ply) then return end

    local npc = ply:GetNWEntity("HLRPG_PilotedZombie")
    if not IsValid(npc) then return end

    local targetPos = npc:GetPos() + Vector(0, 0, 70)
    local desiredOrigin = targetPos - (angles:Forward() * 150) + (angles:Up() * 30)
    local tr = util.TraceLine({ start = targetPos, endpos = desiredOrigin, filter = { ply, npc } })

    return {
        origin = tr.HitPos + tr.Normal * 5,
        angles = angles,
        drawviewer = true
    }
end)

hook.Add("PrePlayerDraw", "HLRPG_HideZombiePilot", function(ply)
    if InZombieForm(ply) then return true end
end)

hook.Add("PlayerBindPress", "HLRPG_Zombie_NoWeaponChange", function(ply, bind, pressed)
    if not InZombieForm(ply) then return end

    if string.find(bind, "slot") or string.find(bind, "invprev") or string.find(bind, "invnext") or string.find(bind, "lastinv") then
        return true
    end
end)
