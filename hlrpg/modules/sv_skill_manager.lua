-- addons/halflife_rpg/lua/hlrpg/modules/sv_skill_manager.lua

if not SERVER then return end

local meta = FindMetaTable("Player")

function meta:InitSkills()
    self.HLRPG_Cooldowns = {} 
end
hook.Add("PlayerInitialSpawn", "HLRPG_InitSkills", function(ply) ply:InitSkills() end)

function meta:CastSkill(skillID)
    local skillDef = HLRPG.Skills.Database[skillID]
    if not skillDef then return end
    
    self.HLRPG_Cooldowns = self.HLRPG_Cooldowns or {}
    
    local readyTime = self.HLRPG_Cooldowns[skillID] or 0
    if CurTime() < readyTime then
        self:EmitSound("buttons/combine_button_locked.wav") 
        return
    end
    
    local result = skillDef.OnCast(self)
    
    if result ~= false then
        local cdr = self:GetModifierVal("mod_overclock") or 0
        
        local cd = skillDef.Cooldown * (1 - cdr)
        
        self.HLRPG_Cooldowns[skillID] = CurTime() + cd
    end
end