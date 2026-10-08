-- autorun/sh_hlrpg_loader.lua

HLRPG = HLRPG or {}

HLRPG.Version = "1.0.0"
HLRPG.Authors = "Ege SEFERTAS"

local ROOT = "hlrpg/"

-- Folders load in this order. Inside a folder, files load alphabetically, then its subfolders.
-- The file prefix decides the realm: sv_ = server, cl_ = client, sh_ = both.
local LOAD_ORDER = { "config", "core", "modules", "ui" }

local function LoadFile(path)
    local prefix = string.GetFileFromFilename(path):sub(1, 3)

    if prefix == "sv_" then
        if SERVER then include(path) end
    elseif prefix == "cl_" then
        if SERVER then AddCSLuaFile(path) else include(path) end
    elseif prefix == "sh_" then
        if SERVER then AddCSLuaFile(path) end
        include(path)
    else
        ErrorNoHalt("[HLRPG] Skipping file without a realm prefix: " .. path .. "\n")
    end
end

local function LoadFolder(folder)
    local files, folders = file.Find(folder .. "*", "LUA")
    table.sort(files)
    table.sort(folders)

    for _, name in ipairs(files) do
        if name:EndsWith(".lua") then LoadFile(folder .. name) end
    end

    for _, name in ipairs(folders) do
        LoadFolder(folder .. name .. "/")
    end
end

print("\n>>> [HALF LIFE RPG] Loading Systems... <<<")

for _, folder in ipairs(LOAD_ORDER) do
    LoadFolder(ROOT .. folder .. "/")
end

print(">>> [HALF LIFE RPG] All Modules Loaded! <<<\n")
