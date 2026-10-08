-- hlrpg/modules/sv_skill_manager.lua
-- Skill casting with cooldowns, and the ult charge that skills spend.

local meta = FindMetaTable("Player")

function meta:InitSkills()
    self.HLRPG_Cooldowns = {}
end
hook.Add("PlayerInitialSpawn", "HLRPG_InitSkills", function(ply) ply:InitSkills() end)

function meta:CastSkill(skillID)
    local skillDef = HLRPG.Skills.Database[skillID]
    if not skillDef then return end

    self.HLRPG_Cooldowns = self.HLRPG_Cooldowns or {}

    if CurTime() < (self.HLRPG_Cooldowns[skillID] or 0) then
        self:EmitSound("buttons/combine_button_locked.wav")
        return
    end

    if skillDef.OnCast(self) ~= false then
        local cooldownReduction = HLRPG.GetAbilityValue(self, "overclock")
        self.HLRPG_Cooldowns[skillID] = CurTime() + skillDef.Cooldown * (1 - cooldownReduction)
    end
end

-- Ult charge (0-100)

function meta:GetUltCharge()
    return self:GetNWInt("HLRPG_UltCharge", 0)
end

function meta:SetUltCharge(val)
    self:SetNWInt("HLRPG_UltCharge", math.Clamp(val, 0, 100))
end

function meta:AddUltCharge(val)
    self:SetUltCharge(self:GetUltCharge() + val)
end

hook.Add("OnNPCKilled", "HLRPG_ChargeOnKillNPC", function(npc, attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() and not attacker:GetNWBool("HLRPG_IsCastingUlt", false) then
        attacker:AddUltCharge(math.random(10, 15))
    end
end)
