-- lua/autorun/sh_hlrpg_loader.lua

-- YENİ GLOBAL NAMESPACE: HLRPG
HLRPG = HLRPG or {}

HLRPG.Version = "1.0.0"
HLRPG.Authors = "Ege SEFERTAS"

print("\n>>> [HALF LIFE RPG] Sistem Yukleniyor... <<<")

-- Yükleyici Fonksiyon
local function LoadFile(path)
    if path:find("sv_") then
        if SERVER then include(path) end
    elseif path:find("cl_") then
        if SERVER then AddCSLuaFile(path) end
        if CLIENT then include(path) end
    elseif path:find("sh_") then
        if SERVER then AddCSLuaFile(path) end
        include(path)
    end
    print("[HLRPG] Yuklendi: " .. path)
end

-- ==============================
-- MODÜL YÜKLEME LİSTESİ (YENİ KLASÖR ADIYLA)
-- ==============================

-- 1. Config
LoadFile("hlrpg/config/sh_config.lua")
LoadFile("hlrpg/core/sh_npc_names.lua")
LoadFile("hlrpg/core/sh_difficulty_core.lua")

-- 2. Core Sistemler
LoadFile("hlrpg/core/sv_database.lua")
LoadFile("hlrpg/core/sv_player.lua")
LoadFile("hlrpg/core/sh_modifiers.lua")
LoadFile("hlrpg/core/sh_skills.lua")
LoadFile("hlrpg/modules/sv_modifier_manager.lua")
LoadFile("hlrpg/modules/sv_difficulty_manager.lua")
LoadFile("hlrpg/modules/sv_combat_hook.lua")
LoadFile("hlrpg/modules/cl_hud.lua")

LoadFile("hlrpg/modules/sv_rpg_system.lua")


LoadFile("hlrpg/modules/sv_npc_difficulty.lua")
LoadFile("hlrpg/modules/cl_boss_hud.lua")
LoadFile("hlrpg/modules/cl_npc_tags.lua")

LoadFile("hlrpg/modules/cl_visuals.lua")
LoadFile("hlrpg/modules/cl_hat_visuals.lua")

LoadFile("hlrpg/modules/sv_skill_manager.lua")

LoadFile("hlrpg/ui/cl_scoreboard.lua")
LoadFile("hlrpg/ui/cl_menu.lua")
LoadFile("hlrpg/ui/cl_difficulty_ui.lua")
LoadFile("hlrpg/ui/cl_xp_notify.lua")
LoadFile("hlrpg/ui/cl_killfeed_cleaner.lua")
LoadFile("hlrpg/ui/cl_player_hub.lua")
LoadFile("hlrpg/ui/cl_pet_customizer.lua")
LoadFile("hlrpg/ui/cl_achievement_hud.lua")
LoadFile("hlrpg/ui/cl_achievement_menu.lua")

LoadFile("hlrpg/modules/sv_npc_damage.lua")
LoadFile("hlrpg/modules/sv_player_cleanup.lua")
LoadFile("hlrpg/modules/sv_temp_points.lua")

LoadFile("hlrpg/modules/sv_shop_logic.lua")
LoadFile("hlrpg/modules/sv_inventory_logic.lua")
LoadFile("hlrpg/modules/sv_equipment.lua")
LoadFile("hlrpg/modules/sv_hat_equipment.lua")
LoadFile("hlrpg/modules/sv_pet_equipment.lua")
LoadFile("hlrpg/modules/sv_modifier_equipment.lua")

LoadFile("hlrpg/modules/sv_zombie_pilot.lua")
LoadFile("hlrpg/modules/cl_zombie_pilot.lua")

LoadFile("hlrpg/ui/cl_pet_hud.lua")
LoadFile("hlrpg/modules/sv_pet_core.lua")
LoadFile("hlrpg/modules/sv_pet_ai.lua")

LoadFile("hlrpg/core/sh_achievements.lua")
LoadFile("hlrpg/core/sh_trigger_maps.lua")
LoadFile("hlrpg/modules/sv_achievement_core.lua")
LoadFile("hlrpg/modules/sv_achievement_logic.lua")
LoadFile("hlrpg/modules/cl_announcer.lua")

LoadFile("hlrpg/modules/sv_test_commands.lua")

LoadFile("hlrpg/core/sh_central_assets.lua")
LoadFile("hlrpg/core/sh_hat_effects.lua")
LoadFile("hlrpg/core/sh_pets.lua")

print(">>> [HALF LIFE RPG] Hazir! <<<\n")