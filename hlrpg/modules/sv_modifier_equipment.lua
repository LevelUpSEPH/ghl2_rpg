-- hlrpg/modules/sv_modifier_equipment.lua
-- Upgrade items. One item per scope (weapon class, or "Global"); equipping another replaces it.
-- Their effects come from the abilities they list (sh_abilities.lua).

local function SetUpgradeActive(ply, itemID, active)
    ply:SetNWBool("HLRPG_ModActive_" .. itemID, active)
end

function HLRPG.ToggleModifierItem(ply, itemID)
    local item = HLRPG.Assets[itemID]
    if not IsValid(ply) or not item then return end

    local scope = item.scope or "Global"
    ply.HLRPG_EquippedMods = ply.HLRPG_EquippedMods or {}

    local current = ply.HLRPG_EquippedMods[scope]
    if current then
        SetUpgradeActive(ply, current, false)
        ply.HLRPG_EquippedMods[scope] = nil
    end

    if current == itemID then
        HLRPG.OnEquipmentChanged(ply, itemID, "none")
        ply:ChatPrint("[MOD] " .. item.name .. " disabled.")
        return
    end

    SetUpgradeActive(ply, itemID, true)
    ply.HLRPG_EquippedMods[scope] = itemID
    HLRPG.OnEquipmentChanged(ply, current or "none", itemID)

    ply:ChatPrint(string.format("[MOD] %s activated (%s)", item.name, scope))
    ply:EmitSound("buttons/button9.wav", 70, 150)
end
