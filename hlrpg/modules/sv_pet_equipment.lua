-- addons/halflife_rpg/lua/hlrpg/modules/sv_pet_equipment.lua
if not SERVER then return end

util.AddNetworkString("HLRPG_EquipPet")

function HLRPG_ApplyPet(ply, petID)
    if not IsValid(ply) then return end
    
    local asset = HLRPG_Assets[petID]
    if not asset then return end

    -- 1. Eski Peti Temizle (Varsa)
    if IsValid(ply.CurrentRPGPet) then
        ply.CurrentRPGPet:Remove()
    end

    -- 2. Veriyi Kaydet
    ply.HLRPG_ActivePet = petID
    ply:SetNWString("HLRPG_ActivePet", petID)

    -- 3. Pet Spawn Logic (İleride buraya NPC/Ent çağırma gelecek)
    -- local pet = ents.Create("npc_pet_base") ...
    
    ply:ChatPrint("[PET] Yanına çağrıldı: " .. asset.name)
    print("[HLRPG] Pet Equip: " .. petID .. " to " .. ply:Nick())
end

net.Receive("HLRPG_EquipPet", function(len, ply)
    local id = net.ReadString()
    if ply:GetNWBool("HLRPG_Owned_" .. id, false) then
        HLRPG_ApplyPet(ply, id)
    end
end)