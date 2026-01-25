-- addons/halflife_rpg/lua/hlrpg/modules/sv_hat_equipment.lua
if not SERVER then return end

util.AddNetworkString("HLRPG_EquipHat")

function HLRPG_ApplyHat(ply, hatID)
    if not IsValid(ply) then return end
    
    local asset = HLRPG_Assets[hatID]
    if not asset then return end

    -- 1. Veriyi Kaydet
    ply.HLRPG_ActiveHat = hatID
    ply:SetNWString("HLRPG_ActiveHat", hatID)

    -- 2. Görselleştirme (Gelecekte buraya Clientside şapka takma mesajı gelecek)
    -- net.Start("HLRPG_Sync_Hat") ...

    ply:ChatPrint("[HAT] Şapka kuşandın: " .. asset.name)
    print("[HLRPG] Hat Equip: " .. hatID .. " to " .. ply:Nick())
end

net.Receive("HLRPG_EquipHat", function(len, ply)
    local id = net.ReadString()
    if ply:GetNWBool("HLRPG_Owned_" .. id, false) then
        HLRPG_ApplyHat(ply, id)
    end
end)