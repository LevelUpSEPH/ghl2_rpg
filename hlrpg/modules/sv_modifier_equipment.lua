-- addons/halflife_rpg/lua/hlrpg/modules/sv_modifier_equipment.lua
if not SERVER then return end

-- addons/halflife_rpg/lua/hlrpg/modules/sv_modifier_equipment.lua

function HLRPG_ApplyModifier(ply, modID, modVal, scope)
    if not IsValid(ply) or not modID then return end
    
    local modDef = HLRPG.Modifiers.Definitions[modID]
    if not modDef then return end

    -- Scope varsa (ör: weapon_smg1) oraya ekle, yoksa Global kalsın
    local targetScope = scope or "Global"
    
    ply:AddRPGModifier(modID, modVal or 1, targetScope)

    ply:SetNWBool("HLRPG_ModActive_" .. modID, true)

    -- UI için NWBool setle (itemID üzerinden gitmek daha doğru olur)
    ply:ChatPrint(string.format("[MOD] %s aktif edildi (%s)", modDef.Name, targetScope))
    ply:EmitSound("buttons/button9.wav", 70, 150)
end

function HLRPG_RemoveModifier(ply, modID)
    if not IsValid(ply) then return end
    ply:RemoveRPGModifier(modID, "Global")
    ply:SetNWBool("HLRPG_ModActive_" .. modID, false)
    ply:ChatPrint("[MOD] Yetenek devredisi.")
end