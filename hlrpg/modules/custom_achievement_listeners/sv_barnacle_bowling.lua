-- addons/halflife_rpg/lua/hlrpg/modules/sv_barnacle_bowling.lua

HLRPG.BarnacleBowling = HLRPG.BarnacleBowling or {}
local BowlingTracker = {}

hook.Add("OnNPCKilled", "HLRPG_BarnacleBowling_Tracker", function(npc, attacker, inflictor)
    if npc:GetClass() ~= "npc_barnacle" then return end
    
    if not IsValid(inflictor) then return end

    local ply = (IsValid(attacker) and attacker:IsPlayer()) and attacker or nil
    local barrel = nil

    local modelPath = inflictor:GetModel() or ""
    modelPath = modelPath:lower()

    if inflictor:GetClass() == "prop_physics" and (string.find(modelPath, "explosive") or string.find(modelPath, "barrel")) then
        barrel = inflictor
    end

    if not barrel and inflictor:GetClass() == "prop_physics" then
        barrel = inflictor
    end

    if not barrel then return end
    
    if not IsValid(ply) then
        ply = barrel:GetPhysicsAttacker(10)
    end

    if not IsValid(ply) then 
        ply = player.GetAll()[1]
    end

    local barrelIndex = barrel:EntIndex()
    BowlingTracker[barrelIndex] = BowlingTracker[barrelIndex] or { count = 0, owner = ply }
    
    BowlingTracker[barrelIndex].count = BowlingTracker[barrelIndex].count + 1

    if BowlingTracker[barrelIndex].count >= 5 then
        for _, ply in ipairs(player.GetAll()) do
            HLRPG_AwardAchievement(ply, "HL2_BARNACLE_BOWLING")
        end
        BowlingTracker[barrelIndex] = nil 
    end
end)

hook.Add("EntityRemoved", "HLRPG_BarnacleBowling_Cleanup", function(ent)
    local idx = ent:EntIndex()
    if BowlingTracker[idx] then
        timer.Simple(2, function() BowlingTracker[idx] = nil end)
    end
end)