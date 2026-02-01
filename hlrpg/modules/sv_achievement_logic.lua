-- sv_achievement_logic.lua

local TriggerMap = {
    ["lcs_CupCop_Pass"] = "HL2_SUBMISSIVE",       -- Çöpe atınca başlayan sahne
    ["lcs_CupCop_Fail"] = "HL2_DEFIANT",          -- Polise vurunca başlayan sahne
    ["relay_break_miniteleporter"] = "HL2_WHAT_CAT", -- Laboratuvar rölesi
    ["relay_found_HEVplate"] = "HL2_VORTIGAL_ENERGY", -- Gizli mağara rölesi
}

hook.Add("AcceptInput", "HLRPG_Achievement_Bridge", function(ent, input, activator, caller, value)
    local name = ent:GetName()
    local achID = TriggerMap[name]

    -- Karar noktası yakalandıysa
    if achID and (input == "Start" or input == "Trigger") then
        local ply = (IsValid(activator) and activator:IsPlayer()) and activator or player.GetAll()[1]
        
        -- Senin ana başarım fonksiyonunu çağırıyoruz
        HLRPG_AwardAchievement(ply, achID)
    end
end)