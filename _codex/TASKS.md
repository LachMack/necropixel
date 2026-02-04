# TASKS (do in order, stop after each task)

## Task 1: Create data folders
Create `/data` and subfolders:
- `/data/schemas`
- `/data/rulesets`
- `/data/factions`
- `/data/fighters`
- `/data/items`
- `/data/missions`

## Task 2: Create schema files
Create JSON schema files in `/data/schemas`:
- `fighter.schema.json`
- `weapon.schema.json`
- `item_slot.schema.json`

Use the exact content provided in `DATA_SCHEMAS.md`.

## Task 3: Create Van Saar data
Create:
- `/data/factions/van_saar.faction.json`
- `/data/fighters/van_saar_archetypes.json`

Use the exact content provided in `DATA_SCHEMAS.md`.

## Task 4: Create item data
Create:
- `/data/items/weapons_core.json`
- `/data/items/armour_core.json`

Use the exact content provided in `DATA_SCHEMAS.md`.

## Task 5: Add Godot DataLoader (read-only integration)
Add a Godot script:
- `/scripts/data/data_loader.gd`

Responsibilities:
- Load all JSON files above from `res://data/**`
- Parse into Dictionaries/Arrays
- Provide getters (e.g., `get_faction(id)`, `get_weapon(id)`)
- Print clear errors on missing file or invalid JSON  
**DO NOT add gameplay logic.**

## Task 6: Add debug scene to verify
Add a minimal debug scene:
- `/scenes/debug/DataDebug.tscn`
- `/scenes/debug/DataDebug.gd`

It should:
- Load `DataLoader`
- Print loaded counts (fighters, weapons, factions)
- Print one sample lookup (`van_saar` faction, `lasgun` weapon)
