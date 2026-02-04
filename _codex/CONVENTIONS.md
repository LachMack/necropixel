# Necropixel Codex Conventions

## Golden rules
1. Never modify engine or gameplay code unless explicitly instructed.
2. Prefer data-driven design: add content in `/data/**` as JSON.
3. All referencable assets must have stable IDs (`lowercase_snake_case`).
4. Keep changes small and atomic. One task = one commit-sized change.

## Folder layout
```
/data/schemas
/data/rulesets
/data/factions
/data/fighters
/data/items
/data/missions
```

## ID conventions
- ids: `lowercase_snake_case` (e.g., `van_saar`, `plasma_pistol`)
- file names: match primary id where possible
- references: use `item_id` / `faction_id` / `archetype_id` strings

## Validation
- Add a `DataLoader` that loads JSON and validates required fields.
- Fail fast: if a required key is missing, report error and stop loading.
