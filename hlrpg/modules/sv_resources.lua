-- hlrpg/modules/sv_resources.lua

for _, workshopID in ipairs(HLRPG.Config.WorkshopContent) do
    resource.AddWorkshop(workshopID)
end

-- Achievement icons (materials/resources/icons/achievements/)
for _, ach in pairs(HLRPG.Achievements) do
    if ach.icon then resource.AddFile("materials/" .. ach.icon) end
end
