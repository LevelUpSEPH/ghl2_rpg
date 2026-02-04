-- addons/halflife_rpg/lua/hlrpg/modules/cl_npc_tags.lua
if not CLIENT then return end

hook.Add("HUDShouldDraw", "HLRPG_HideVanillaTargetID", function(name)
    if name == "CHudTargetID" then return false end
end)

surface.CreateFont("HLRPG_NPCTag", { font = "Verdana", size = 48, weight = 900, antialias = true }) -- Büyütüldü
surface.CreateFont("HLRPG_NPCLvl", { font = "Verdana", size = 32, weight = 700, antialias = true }) -- Büyütüldü
surface.CreateFont("HLRPG_PlayerHP", { font = "Verdana", size = 26, weight = 800, antialias = true }) -- Büyütüldü

hook.Add("PostDrawTranslucentRenderables", "HLRPG_DrawNPCTags", function()
    local ply = LocalPlayer()
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not IsValid(ent) or ent:Health() <= 0 or ent == ply then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > 1000000 then return end

    local class = ent:GetClass()
    local isKnown = HLRPG_NPC_Configs and HLRPG_NPC_Configs[class]
    
    if not (ent:IsNPC() or ent:IsPlayer() or isKnown) then return end

    local zMax = ent:OBBMaxs().z
    if zMax <= 5 then zMax = 15 end 
    local pos = ent:GetPos() + Vector(0, 0, zMax + 25)
    
    local ang = ply:EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
        
        if ent:IsPlayer() then
            local name = ent:Nick()
            local hp = ent:Health()
            local color = Color(0, 200, 255)

            draw.SimpleText(name, "HLRPG_NPCTag", 2, 125, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER)
            draw.SimpleText(name, "HLRPG_NPCTag", 0, 125, color, TEXT_ALIGN_CENTER)
            
            local hpText = hp .. " HP"
            draw.SimpleText(hpText, "HLRPG_PlayerHP", 0, 200, Color(255, 255, 255, 220), TEXT_ALIGN_CENTER)

        else
            local npcLevel = 1
            local name = ""
            local color = Color(255, 255, 255)
            local isBoss = ent:GetNWBool("HLRPG_IsBoss", false)

            if ent.IsHLRPGPet or ent:GetNWBool("HLRPG_ISPET", false) then
                npcLevel = ent:GetNWInt("HLRPG_PetEntityLevel", 1)
                name = ent:GetNWString("HLRPG_PetEntityName", "Pet")
                color = Color(255, 200, 0)
            else
                npcLevel = ent:GetNWInt("HLRPG_NPCLevel", 1)
                name = (HLRPG_GetNPCName and HLRPG_GetNPCName(ent)) or class:gsub("npc_", ""):upper()
                color = (HLRPG_GetNPCColor and HLRPG_GetNPCColor(ent)) or Color(255, 255, 255)
            end

            if isBoss then color = Color(255, 0, 0) end
            
            draw.SimpleText("Lv. " .. npcLevel, "HLRPG_NPCLvl", 2, 52, Color(0,0,0,200), TEXT_ALIGN_CENTER) -- Gölge
            draw.SimpleText("Lv. " .. npcLevel, "HLRPG_NPCLvl", 0, 50, color, TEXT_ALIGN_CENTER)
            
            draw.SimpleText(name, "HLRPG_NPCTag", 2, 152, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER) -- Gölge
            draw.SimpleText(name, "HLRPG_NPCTag", 0, 150, color, TEXT_ALIGN_CENTER)
            
            if ent.IsHLRPGPet or ent:GetNWBool("IsHLRPGPet", false) then
                local owner = ent:GetNWEntity("HLRPG_PetOwner")
                if IsValid(owner) then
                    draw.SimpleText("< " .. owner:Nick() .. " >", "HLRPG_PlayerHP", 0, 220, Color(200, 200, 200, 150), TEXT_ALIGN_CENTER)
                end
            end
        end

    cam.End3D2D()
end)