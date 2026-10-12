🚀 Half-Life RPG: Core System
A modular, high-performance RPG framework for Garry's Mod, inspired by Leiftiger's HL2C Server. It features a dedicated clientside suit system, specialized equipment controllers, and a strategic modifier engine.
My aim was to build a system thats open for further development at all times, hence why I left most things abstract for developers' imaginations. (Some parts might be forgotten rather than intentional)

You are free to use this locally or open a server using this. I am just asking not to monetize this in any way, as this was a passion project and was meant to be enjoyed off, rather than profited.

✨ Key Features
Clientside Visuals: Renders high-quality suits over the player model via BoneMerge without changing the base entity.

Modular Controllers: Dedicated logic for Suits, Hats, Pets, and Modifiers to ensure clean debugging.

Strategic Slot Policy: Strict Single-Slot rule. Equipping a new item or modifier automatically de-equips the previous one in that category.

Scope-Based Modifiers: Passive abilities (Lifesteal, Fire Ammo, etc.) that can be global or locked to specific weapon classes.

📂 Structure
This repository is the addon's `lua/` folder: install it as `garrysmod/addons/<name>/lua/`. Achievement icons go in `garrysmod/addons/<name>/materials/resources/icons/achievements/`.

config/: Server operator settings (welcome message, workshop content, safe maps, map reset, selectable player models).

core/: Shared game content and helpers. Assets (sh_assets.lua), achievements and map triggers, NPC data, difficulty and level curve, pets, modifiers, skills, hat effects.

modules/: Server-side logic. Persistence (sv_database.lua), progression, combat, difficulty, inventory/shop, and one controller per equipment type (sv_suit_equipment, sv_hat_equipment, sv_pet_equipment, sv_modifier_equipment). Custom achievement listeners go in modules/custom_achievement_listeners/.

ui/: Everything clientside: HUDs, menus, and the suit/hat renderers.

entities/: Map entities GMod doesn't ship. logic_achievement lets Valve's maps report their achievement events (see core/sh_achievement_events.lua).

🧩 Conventions
Load order: autorun/sh_hlrpg_loader.lua loads config/, core/, modules/, ui/ in that order (files alphabetically, then subfolders). Dropping a new file in the right folder is enough; it doesn't need to be registered.

Realm prefixes: sv_ = server only, cl_ = client only, sh_ = both. Files without a prefix are skipped.

Namespace: everything public lives under the HLRPG table (HLRPG.Assets, HLRPG.AwardAchievement, ...). No new globals.

Abilities: every gameplay effect lives in core/sh_abilities.lua. Items never contain logic; they list abilities, e.g. abilities = { { id = "armor_regen", value = 1 } }. To give an item a new effect, add an ability definition (or reuse one) and reference it from the item in core/sh_assets.lua.

Chat commands: register server commands with HLRPG.AddChatCommand("!name", function(ply, args) end).

Extension hooks: hook.Add("HLRPG_LambdaFound", ..., function(ply, lambdaID) end).

Save data: player progress is stored with PData. Don't rename the PData keys in sv_database.lua or existing saves stop loading.

Credits: Inspired by the mechanics found in Leiftiger's HL2C server.
