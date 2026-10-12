-- entities/logic_achievement.lua
-- Valve's maps (HL2, Episode Two) mark achievement moments with logic_achievement entities, but GMod
-- doesn't ship the class. Defining it here lets the maps report those moments: FireEvent passes the
-- entity's AchievementEvent to HLRPG.OnAchievementEvent (modules/sv_achievements.lua).

ENT.Type = "point"
ENT.Base = "base_point"

function ENT:KeyValue(key, value)
    key = string.lower(key)
    if key == "achievementevent" then
        self.AchievementEvent = value
    elseif key == "startdisabled" then
        self.Disabled = value == "1"
    end
end

function ENT:AcceptInput(name, activator, caller, data)
    name = string.lower(name)

    if name == "fireevent" then
        if not self.Disabled and self.AchievementEvent and HLRPG and HLRPG.OnAchievementEvent then
            HLRPG.OnAchievementEvent(self.AchievementEvent, activator)
        end
    elseif name == "enable" then
        self.Disabled = false
    elseif name == "disable" then
        self.Disabled = true
    elseif name == "toggle" then
        self.Disabled = not self.Disabled
    else
        return false
    end

    return true
end
