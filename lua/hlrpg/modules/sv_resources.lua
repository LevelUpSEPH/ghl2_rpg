-- hlrpg/modules/sv_resources.lua

for _, workshopID in ipairs(HLRPG.Config.WorkshopContent) do
    resource.AddWorkshop(workshopID)
end

-- Achievement icons (materials/resources/icons/achievements/)
for _, ach in pairs(HLRPG.Achievements) do
    if ach.icon then resource.AddFile("materials/" .. ach.icon) end
end

-- Suit textures (materials/hlrpg/suits/); adding the .vmt sends its .vtf too
for _, item in pairs(HLRPG.Assets) do
    if item.material then resource.AddFile("materials/" .. item.material .. ".vmt") end
    for _, extra in ipairs(item.extraMaterials or {}) do resource.AddFile("materials/" .. extra .. ".vmt") end
end
