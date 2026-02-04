-- addons/halflife_rpg/lua/hlrpg/core/sh_hat_effects.lua
HLRPG = HLRPG or {}
HLRPG.HatEffects = HLRPG.HatEffects or {}
HLRPG.HatEffects.Definitions = {}

HLRPG.HatEffects.Definitions["wireframe"] = {
    Name = "Combine Tactical Interface",
    
    OnRender = function()
        DrawColorModify({
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0.02,
            ["$pp_colour_addb"] = 0.1,
            ["$pp_colour_brightness"] = -0.05,
            ["$pp_colour_contrast"] = 1.2,
            ["$pp_colour_colour"] = 0.4,
        })
    end,

    OnUI = function()
        surface.SetDrawColor(0, 0, 0, 80)
        local w, h = ScrW(), ScrH()
        local lineSpacing = 3
        
        for i = 0, h, lineSpacing do
            surface.DrawRect(0, i, w, 1)
        end

        draw.SimpleText("• SYSTEM ONLINE", "DermaDefault", 20, 20, Color(0, 200, 255, 150))
    end,

    OnDraw = function()
        local targets = ents.FindByClass("npc_combine_s")
        table.Add(targets, ents.FindByClass("npc_metropolice"))
        halo.Add(targets, Color(0, 150, 255), 2, 2, 1, true, true)
    end
}