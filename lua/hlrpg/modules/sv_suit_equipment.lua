-- hlrpg/modules/sv_suit_equipment.lua
-- Suits (drawn client-side over the player via bonemerge, see cl_suit_visuals.lua) and base player models.

util.AddNetworkString("HLRPG_OpenMenu")
util.AddNetworkString("HLRPG_SetPlayerModel")
util.AddNetworkString("HLRPG_Sync_Suit")

local function GetSuit(suitID)
    local asset = HLRPG.Assets[suitID]
    return (asset and asset.group == "Suits") and asset or nil
end

-- Whether ply shows their suit's own helmet instead of their face: the suit has one (helmet = true) and the
-- worn hat asks for it (suitHelmet = true, the Metrocop Helmet). The hat itself is then not drawn.
local function IsHelmetShown(ply)
    local suit, hat = GetSuit(ply.HLRPG_Suit), HLRPG.Assets[ply.HLRPG_ActiveHat or ""]
    return suit ~= nil and suit.helmet == true and hat ~= nil and hat.suitHelmet == true
end

-- Sends ply's suit to target, or to everyone if target is nil
local function SendSuit(ply, target)
    net.Start("HLRPG_Sync_Suit")
        net.WriteEntity(ply)
        net.WriteString(ply.HLRPG_Suit or "none")
        net.WriteBool(IsHelmetShown(ply))
    if target then net.Send(target) else net.Broadcast() end
end

-- Changing hats can show or hide the suit's helmet, so the suit is redrawn
hook.Add("HLRPG_HatChanged", "HLRPG_SuitHelmet", function(ply)
    if GetSuit(ply.HLRPG_Suit) then SendSuit(ply) end
end)

local function ApplySuitHands(ply)
    ply:SetupHands()

    local suit = GetSuit(ply.HLRPG_Suit)
    local hands = ply:GetHands()
    if not suit or not suit.hands or not IsValid(hands) then return end

    hands:SetModel(suit.hands)
    if suit.skin then hands:SetSkin(suit.skin) end
    hands:SetRenderMode(RENDERMODE_NORMAL)
    hands:SetColor(Color(255, 255, 255, 255))
end

-- suitID "none" removes the current suit
function HLRPG.ApplySuit(ply, suitID)
    if not IsValid(ply) then return end

    local suit = GetSuit(suitID)
    if not suit and suitID ~= "none" then return end

    local oldSuitID = ply.HLRPG_Suit or "none"
    ply.HLRPG_Suit = suitID
    ply:SetNWString("HLRPG_ActiveSuit", suitID)
    SendSuit(ply)
    HLRPG.OnEquipmentChanged(ply, oldSuitID, suitID)

    ply:ChatPrint(suit and ("Equipped suit: " .. suit.name) or "[INV] Suit removed.")

    timer.Simple(0.1, function()
        if IsValid(ply) then ApplySuitHands(ply) end
    end)
end

function HLRPG.ToggleSuit(ply, suitID)
    HLRPG.ApplySuit(ply, ply.HLRPG_Suit == suitID and "none" or suitID)
    ply:SaveSuit()
end

function HLRPG.SetPlayerModel(ply, model)
    ply.HLRPG_Model = model
    ply:SavePlayerModel()
    ply:SetModel(model)
    ply:SetupHands()
    -- A worn suit draws the player's head from their model, so redraw it with the new one
    if ply.HLRPG_Suit then SendSuit(ply) end
    ply:ChatPrint("Clothing changed.")
end

hook.Add("ShowHelp", "HLRPG_Override_F1", function(ply)
    net.Start("HLRPG_OpenMenu")
    net.Send(ply)
    return false
end)

-- Only models listed in HLRPG.Config.Models are accepted from clients
net.Receive("HLRPG_SetPlayerModel", function(len, ply)
    local model = net.ReadString()

    for _, entry in ipairs(HLRPG.Config.Models) do
        if entry.model == model then
            HLRPG.SetPlayerModel(ply, model)
            return
        end
    end
end)

hook.Add("PlayerSetHands", "HLRPG_Hook_SetHands", function(ply, ent)
    local suit = GetSuit(ply.HLRPG_Suit)
    if not suit or not suit.hands then return end

    ent:SetModel(suit.hands)
    if suit.skin then ent:SetSkin(suit.skin) end
    return true
end)

hook.Add("PlayerSpawn", "HLRPG_Spawn_Hands", function(ply)
    timer.Simple(0.2, function()
        if not IsValid(ply) then return end

        if ply.HLRPG_Model then ply:SetModel(ply.HLRPG_Model) end

        if ply.HLRPG_Suit then
            SendSuit(ply)
            ApplySuitHands(ply)
        end
    end)
end)

-- Late joiners need everyone else's suits
-- A client that just finished loading needs every suit, its own included
hook.Add("HLRPG_ClientReady", "HLRPG_Sync_Suits", function(newPly)
    for _, ply in ipairs(player.GetAll()) do
        if GetSuit(ply.HLRPG_Suit) then SendSuit(ply, newPly) end
    end
end)
