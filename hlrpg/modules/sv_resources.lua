-- hlrpg/modules/sv_resources.lua

for _, workshopID in ipairs(HLRPG.Config.WorkshopContent) do
    resource.AddWorkshop(workshopID)
end
