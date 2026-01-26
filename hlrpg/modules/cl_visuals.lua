-- addons/halflife_rpg/lua/hlrpg/modules/cl_visuals.lua

if not CLIENT then return end

local Visuals = {}
local INVISIBLE_MAT = "models/effects/vol_light001"

-- YARDIMCI: Hiyerarşi Bulucu
local function GetAllChildrenBones(ent, parentID)
    local children = {}
    local count = ent:GetBoneCount()
    
    for i = 0, count - 1 do
        local parent = ent:GetBoneParent(i)
        if parent == parentID then
            table.insert(children, i)
            local grandChildren = GetAllChildrenBones(ent, i)
            for _, gc in ipairs(grandChildren) do
                table.insert(children, gc)
            end
        end
    end
    return children
end

local function RemoveVisuals(sid)
    if not Visuals[sid] then return end
    local data = Visuals[sid]
    if IsValid(data.Suit) then data.Suit:Remove() end
    if IsValid(data.FakeHead) then data.FakeHead:Remove() end
    
    local ply = player.GetBySteamID(sid)
    if IsValid(ply) then
        ply:SetMaterial("")
        ply:SetRenderMode(RENDERMODE_NORMAL)
        ply:SetColor(Color(255, 255, 255, 255))
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            wep:SetMaterial("")
            wep:SetRenderMode(RENDERMODE_NORMAL)
            wep:SetColor(Color(255, 255, 255, 255))
        end
    end
    Visuals[sid] = nil
end

net.Receive("HLRPG_Sync_Suit", function()
    local ply = net.ReadEntity()
    local suitModel = net.ReadString()
    if IsValid(ply) then UpdatePlayerVisuals(ply, suitModel) end
end)

function UpdatePlayerVisuals(ply, suitPath)
    local sid = ply:SteamID()
    RemoveVisuals(sid)

    if not suitPath or suitPath == "none" or suitPath == "" then return end

    local suitConfig = nil
    for _, s in ipairs(HLRPG.Config.Suits) do
        if s.model == suitPath then suitConfig = s; break end
    end
    
    local headOffset = (suitConfig and suitConfig.head_offset) or Vector(0,0,0)
    
    local hideSuitHands = (suitConfig and suitConfig.hide_suit_hands) or false

    Visuals[sid] = { Active = true }

    -- ====================================================
    -- 1. SUIT (ZIRH)
    -- ====================================================
    local suit = ClientsideModel(suitPath)
    if IsValid(suit) then
        suit:SetPos(ply:GetPos())
        suit:SetParent(ply)
        suit:AddEffects(EF_BONEMERGE)
        suit:SetModelScale(1.01, 0)
        
        -- A) GİZLENECEK KEMİKLERİ HAZIRLA
        local bonesToHide = {}      -- Basitçe gizlenecekler (Kafa gibi)
        local handChildren = {}     -- Ebeveynine (Bileğe) yapıştırılacaklar

        -- Kafayı ekle (Basit gizleme)
        local hBone = suit:LookupBone("ValveBiped.Bip01_Head1")
        if hBone then bonesToHide[hBone] = true end

        -- Elleri İşle (Zombi Fix)
        local lHandID, rHandID
        if hideSuitHands then
            lHandID = suit:LookupBone("ValveBiped.Bip01_L_Hand")
            rHandID = suit:LookupBone("ValveBiped.Bip01_R_Hand")

            -- Sol el parmaklarını topla -> Sol El'e (lHandID) zimmetle
            if lHandID then
                bonesToHide[lHandID] = true -- Eli de gizle
                for _, child in ipairs(GetAllChildrenBones(suit, lHandID)) do
                    handChildren[child] = lHandID -- Bu çocuk, bu babaya gidecek
                end
            end

            -- Sağ el parmaklarını topla -> Sağ El'e (rHandID) zimmetle
            if rHandID then
                bonesToHide[rHandID] = true
                for _, child in ipairs(GetAllChildrenBones(suit, rHandID)) do
                    handChildren[child] = rHandID
                end
            end
        end
        
        Visuals[sid].SuitSimpleHide = bonesToHide
        Visuals[sid].SuitHandChildren = handChildren

        -- CALLBACK
        suit:AddCallback("BuildBonePositions", function(ent, nbones)
            if not Visuals[sid] or not IsValid(ent) then return end
            
            -- 1. BASİT GİZLEME (Kafa, Bilekler)
            -- Bunlar zaten doğru yerde (Bonemerge), sadece küçült.
            for bid, _ in pairs(Visuals[sid].SuitSimpleHide) do
                local m = ent:GetBoneMatrix(bid)
                if m then 
                    m:Scale(Vector(0.001, 0.001, 0.001))
                    ent:SetBoneMatrix(bid, m) 
                end
            end

            -- 2. KOPYALA YAPIŞTIR (Parmaklar -> Bileğe)
            -- Void'deki parmak matrisini OKUMA. Bilek matrisini AL, parmağa YAZ.
            for childID, parentID in pairs(Visuals[sid].SuitHandChildren) do
                local parentMatrix = ent:GetBoneMatrix(parentID)
                
                if parentMatrix then
                    -- Matrisin bir kopyasını oluştur ki orijinal bileği bozmayalım
                    local newM = Matrix(parentMatrix) 
                    
                    -- Kopyayı küçült
                    newM:Scale(Vector(0.001, 0.001, 0.001))
                    
                    -- Çocuğa (Parmağa) bu yeni matrisi zorla
                    ent:SetBoneMatrix(childID, newM)
                end
            end
        end)
        
        Visuals[sid].Suit = suit
    end

    local head = ClientsideModel(ply:GetModel())
    if IsValid(head) then
        head:SetPos(ply:GetPos())
        head:SetParent(ply)
        head:AddEffects(EF_BONEMERGE)
        
        local hBone = head:LookupBone("ValveBiped.Bip01_Head1")
        
        if not hBone then
            head:Remove()
            Visuals[sid].FakeHead = nil
        else
            -- Görünür Listesi
            local visibleBones = {}
            visibleBones[hBone] = true
            for _, id in ipairs(GetAllChildrenBones(head, hBone)) do visibleBones[id] = true end
            
            local nBone = head:LookupBone("ValveBiped.Bip01_Neck1")
            if nBone then
                visibleBones[nBone] = true
                for _, id in ipairs(GetAllChildrenBones(head, nBone)) do visibleBones[id] = true end
            end
            
            Visuals[sid].CachedHeadID_Fake = hBone
            Visuals[sid].VisibleBones = visibleBones
            
            head:AddCallback("BuildBonePositions", function(ent, nbones)
                if not Visuals[sid] or not IsValid(ent) or not IsValid(ply) then return end
                
                for i = 0, nbones - 1 do
                    if Visuals[sid].VisibleBones[i] then
                        -- GÖRÜNÜR: Offset varsa uygula
                        if i == hBone and headOffset ~= Vector(0,0,0) then
                            local m = ent:GetBoneMatrix(i)
                            if m then m:Translate(headOffset); ent:SetBoneMatrix(i, m) end
                        end
                    else
                        -- GİZLİ (VÜCUT): SADECE KÜÇÜLT!
                        -- BURADA 'SetTranslation' YOK! VÜCUT BOZULMAYACAK.
                        local m = ent:GetBoneMatrix(i)
                        if m then
                            m:Scale(Vector(0.001, 0.001, 0.001))
                            ent:SetBoneMatrix(i, m)
                        end
                    end
                end
            end)
            Visuals[sid].FakeHead = head
        end
    end
end

-- THINK LOOP
hook.Add("Think", "HLRPG_Global_Visual_Enforce", function()
    for sid, data in pairs(Visuals) do
        local ply = player.GetBySteamID(sid)
        if not IsValid(ply) or not ply:Alive() then
            RemoveVisuals(sid)
            continue
        end
        if ply:IsDormant() then continue end

        if ply:GetMaterial() ~= INVISIBLE_MAT then ply:SetMaterial(INVISIBLE_MAT) end
        
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            if wep:GetMaterial() == INVISIBLE_MAT then wep:SetMaterial("") end
            if wep:GetColor().a ~= 255 then
                wep:SetColor(Color(255,255,255,255))
                wep:SetRenderMode(RENDERMODE_NORMAL)
            end
        end
    end
end)