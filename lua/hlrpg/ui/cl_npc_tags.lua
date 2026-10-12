-- hlrpg/ui/cl_npc_tags.lua
-- Floating name/level tags above whatever the player is looking at (replaces the default target ID).

surface.CreateFont("HLRPG_NPCTag", { font = "Verdana", size = 48, weight = 900, antialias = true })
surface.CreateFont("HLRPG_NPCLvl", { font = "Verdana", size = 32, weight = 700, antialias = true })
surface.CreateFont("HLRPG_PlayerHP", { font = "Verdana", size = 26, weight = 800, antialias = true })

local MAX_DISTANCE = 1000
local PET_COLOR = Color(255, 200, 0)
local BOSS_COLOR = Color(255, 0, 0)

hook.Add("HUDShouldDraw", "HLRPG_HideVanillaTargetID", function(name)
    if name == "CHudTargetID" then return false end
end)

local function DrawPlayerTag(ent)
    local name = ent:Nick()
    draw.SimpleText(name, "HLRPG_NPCTag", 2, 125, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER)
    draw.SimpleText(name, "HLRPG_NPCTag", 0, 125, Color(0, 200, 255), TEXT_ALIGN_CENTER)
    draw.SimpleText(ent:Health() .. " HP", "HLRPG_PlayerHP", 0, 200, Color(255, 255, 255, 220), TEXT_ALIGN_CENTER)
end

local function DrawNPCTag(ent)
    local isPet = ent:GetNWBool("HLRPG_ISPET", false)
    local level, name, color

    if isPet then
        level = ent:GetNWInt("HLRPG_PetEntityLevel", 1)
        name = ent:GetNWString("HLRPG_PetEntityName", "Pet")
        color = PET_COLOR
    else
        level = ent:GetNWInt("HLRPG_NPCLevel", 1)
        name = HLRPG.GetNPCName(ent)
        color = HLRPG.GetNPCColor(ent)
    end

    if ent:GetNWBool("HLRPG_IsBoss", false) then color = BOSS_COLOR end

    draw.SimpleText("Lv. " .. level, "HLRPG_NPCLvl", 2, 52, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER)
    draw.SimpleText("Lv. " .. level, "HLRPG_NPCLvl", 0, 50, color, TEXT_ALIGN_CENTER)

    draw.SimpleText(name, "HLRPG_NPCTag", 2, 152, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER)
    draw.SimpleText(name, "HLRPG_NPCTag", 0, 150, color, TEXT_ALIGN_CENTER)

    local owner = isPet and ent:GetNWEntity("HLRPG_PetOwner")
    if IsValid(owner) then
        draw.SimpleText("< " .. owner:Nick() .. " >", "HLRPG_PlayerHP", 0, 220, Color(200, 200, 200, 150), TEXT_ALIGN_CENTER)
    end
end

hook.Add("PostDrawTranslucentRenderables", "HLRPG_DrawNPCTags", function()
    local ply = LocalPlayer()
    local ent = ply:GetEyeTrace().Entity

    if not IsValid(ent) or ent:Health() <= 0 or ent == ply then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > MAX_DISTANCE * MAX_DISTANCE then return end
    if not (ent:IsNPC() or ent:IsPlayer() or HLRPG.NPCNames[ent:GetClass()]) then return end

    local zMax = ent:OBBMaxs().z
    if zMax <= 5 then zMax = 15 end
    local pos = ent:GetPos() + Vector(0, 0, zMax + 25)

    local ang = ply:EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
        if ent:IsPlayer() then
            DrawPlayerTag(ent)
        else
            DrawNPCTag(ent)
        end
    cam.End3D2D()
end)
