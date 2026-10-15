-- hlrpg/core/sh_arenas.lua
-- Miniboss arenas (sv_arenas.lua): on a given map, something starts the fight, walls go up, a boss and its
-- escorts spawn, and when the boss dies the walls come down and everyone present is rewarded.
--
-- Positions are world coordinates. Find them in game with the admin commands:
--   rpg_pos          prints where you stand and where you aim, ready to paste
--   rpg_wallcorner   run it twice, aiming at two opposite corners: prints a wall entry and previews it
--   rpg_arena list / start <id> / stop <id>    to test an arena
--
-- Each arena:
--   map       the map it belongs to (lowercase)
--   start     how it starts, one of:
--               { input = { name = "<entity name>", input = "<input>" } }  when that map entity gets that input
--               { area = { Vector(...), Vector(...) } }                    when a living player enters that box
--   walls     list of { Vector(corner), Vector(opposite corner), block = "players" | "npcs" | "all",
--                       visible = true (Combine force field) / false (invisible) }
--   boss      { class, pos, ang, name, weapon, model, skin, scale, color, health (extra multiplier on top of
--               the usual boss health), keyvalues = { ... } }
--   escorts   optional list of { class, pos, ang, weapon, model }: spawned with the boss, not required to win
--   reward    { kills = <XP, in standard kills at each player's level>, item = "<item id>" (optional) }
--   timeout   seconds before the walls drop anyway (default 600); the boss stays
--
-- Example (not a real location yet):
--   ["ep2_field_commander"] = {
--       map = "ep2_outland_03",
--       start = { area = { Vector(-1200, 300, 0), Vector(-800, 700, 200) } },
--       walls = {
--           { Vector(-1250, 250, 0), Vector(-1230, 750, 256), block = "players", visible = true },
--       },
--       boss = { class = "npc_combine_s", name = "Overwatch Commander", pos = Vector(-1000, 500, 8),
--                ang = Angle(0, 90, 0), weapon = "weapon_ar2", model = "models/combine_super_soldier.mdl",
--                scale = 1.25, color = Color(255, 120, 120), health = 3 },
--       escorts = {
--           { class = "npc_combine_s", pos = Vector(-950, 450, 8), weapon = "weapon_shotgun" },
--       },
--       reward = { kills = 40 },
--   },

HLRPG.Arenas = {
}

HLRPG.ArenaDefaultTimeout = 600
