🚀 Half-Life RPG: Core System
A modular, high-performance RPG framework for Garry's Mod, inspired by Leiftiger's HL2C Server. It features a dedicated clientside suit system, specialized equipment controllers, and a strategic modifier engine.

✨ Key Features
Clientside Visuals: Renders high-quality suits over the player model via BoneMerge without changing the base entity.

Modular Controllers: Dedicated logic for Suits, Hats, Pets, and Modifiers to ensure clean debugging.

Strategic Slot Policy: Strict Single-Slot rule. Equipping a new item or modifier automatically de-equips the previous one in that category.

Scope-Based Modifiers: Passive abilities (Lifesteal, Fire Ammo, etc.) that can be global or locked to specific weapon classes.

📂 Structure
core/: Asset definitions (sh_assets.lua) and modifier logic (sh_modifiers.lua).

modules/: Server-side logic for equipment, inventory routing, and combat modifiers.

ui/: Dashboard interface and clientside rendering systems.

Credits: Inspired by the mechanics found in Leiftiger's HL2C server.
