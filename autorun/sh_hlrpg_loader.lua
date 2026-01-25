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

-- 2. Core Sistemler
LoadFile("hlrpg/core/sv_database.lua")
LoadFile("hlrpg/core/sv_player.lua")
LoadFile("hlrpg/core/sh_modifiers.lua")
LoadFile("hlrpg/core/sh_skills.lua")
LoadFile("hlrpg/modules/sv_modifier_manager.lua")
LoadFile("hlrpg/modules/sv_combat_hook.lua")
LoadFile("hlrpg/modules/cl_hud.lua")

LoadFile("hlrpg/modules/sv_rpg_system.lua")

LoadFile("hlrpg/modules/sv_equipment.lua")

LoadFile("hlrpg/modules/cl_visuals.lua")
LoadFile("hlrpg/modules/sv_skill_manager.lua")

LoadFile("hlrpg/ui/cl_scoreboard.lua")
LoadFile("hlrpg/ui/cl_menu.lua")

print(">>> [HALF LIFE RPG] Hazir! <<<\n")