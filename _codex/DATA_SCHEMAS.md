# Data Schemas & Seed Content (v0.1)

This file is the single source of truth for **Codex generation**.
Codex should copy the code blocks **verbatim** into the target files during Tasks 2–4.

---

## `/data/schemas/item_slot.schema.json`
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "item_slot.schema.json",
  "type": ["object", "null"],
  "required": ["item_id"],
  "properties": {
    "item_id": { "type": "string", "minLength": 1 },
    "ammo_profile": { "type": "string", "default": "standard" }
  },
  "additionalProperties": false
}
```

---

## `/data/schemas/weapon.schema.json`
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "weapon.schema.json",
  "type": "object",
  "required": ["id", "name", "category", "profiles"],
  "properties": {
    "id": { "type": "string", "minLength": 1 },
    "name": { "type": "string", "minLength": 1 },
    "category": {
      "type": "string",
      "enum": ["pistol", "basic", "special", "heavy", "melee", "grenade", "wargear"]
    },
    "rarity": { "type": "integer", "minimum": 0, "default": 0 },
    "cost": { "type": "integer", "minimum": 0, "default": 0 },
    "tags": { "type": "array", "items": { "type": "string" }, "default": [] },
    "profiles": {
      "type": "object",
      "minProperties": 1,
      "additionalProperties": {
        "type": "object",
        "required": ["range", "acc", "s", "ap", "d", "traits"],
        "properties": {
          "range": {
            "type": "object",
            "required": ["short", "long"],
            "properties": {
              "short": { "type": "integer", "minimum": 0 },
              "long": { "type": "integer", "minimum": 0 }
            },
            "additionalProperties": false
          },
          "acc": {
            "type": "object",
            "required": ["short", "long"],
            "properties": {
              "short": { "type": "integer" },
              "long": { "type": "integer" }
            },
            "additionalProperties": false
          },
          "s": { "type": "integer", "minimum": 1, "maximum": 10 },
          "ap": { "type": "integer", "minimum": -6, "maximum": 6 },
          "d": { "type": "integer", "minimum": 1, "maximum": 10 },
          "ammo": {
            "type": "object",
            "properties": {
              "check": { "type": "integer", "minimum": 0, "maximum": 12 },
              "type": { "type": "string", "default": "standard" }
            },
            "additionalProperties": false,
            "default": { "check": 0, "type": "standard" }
          },
          "traits": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["id"],
              "properties": {
                "id": { "type": "string" },
                "value": { "type": ["integer", "string", "null"], "default": null }
              },
              "additionalProperties": false
            },
            "default": []
          }
        },
        "additionalProperties": false
      }
    }
  },
  "additionalProperties": false
}
```

---

## `/data/schemas/fighter.schema.json`
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "fighter.schema.json",
  "type": "object",
  "required": ["id", "name", "faction_id", "role", "stats", "loadout"],
  "properties": {
    "id": { "type": "string", "minLength": 1 },
    "name": { "type": "string", "minLength": 1 },
    "faction_id": { "type": "string", "minLength": 1 },
    "role": {
      "type": "string",
      "enum": ["leader", "champion", "ganger", "juve", "prospect", "hanger_on", "hired_gun"]
    },
    "tags": { "type": "array", "items": { "type": "string" }, "default": [] },
    "stats": {
      "type": "object",
      "required": ["m", "ws", "bs", "s", "t", "w", "i", "a", "ld", "cl", "wil", "int"],
      "properties": {
        "m": { "type": "integer", "minimum": 1, "maximum": 10 },
        "ws": { "type": "integer", "minimum": 2, "maximum": 6 },
        "bs": { "type": "integer", "minimum": 2, "maximum": 6 },
        "s": { "type": "integer", "minimum": 1, "maximum": 6 },
        "t": { "type": "integer", "minimum": 1, "maximum": 6 },
        "w": { "type": "integer", "minimum": 1, "maximum": 6 },
        "i": { "type": "integer", "minimum": 2, "maximum": 6 },
        "a": { "type": "integer", "minimum": 1, "maximum": 6 },
        "ld": { "type": "integer", "minimum": 4, "maximum": 10 },
        "cl": { "type": "integer", "minimum": 4, "maximum": 10 },
        "wil": { "type": "integer", "minimum": 4, "maximum": 10 },
        "int": { "type": "integer", "minimum": 4, "maximum": 10 }
      },
      "additionalProperties": false
    },
    "status": {
      "type": "object",
      "properties": {
        "alive": { "type": "boolean", "default": true },
        "in_recovery": { "type": "boolean", "default": false },
        "conditions": { "type": "array", "items": { "type": "string" }, "default": [] }
      },
      "additionalProperties": false,
      "default": {}
    },
    "progression": {
      "type": "object",
      "properties": {
        "xp": { "type": "integer", "minimum": 0, "default": 0 },
        "advances": { "type": "array", "items": { "type": "object" }, "default": [] }
      },
      "additionalProperties": false,
      "default": {}
    },
    "loadout": {
      "type": "object",
      "required": ["equipped"],
      "properties": {
        "equipped": {
          "type": "object",
          "properties": {
            "primary": { "$ref": "item_slot.schema.json" },
            "secondary": { "$ref": "item_slot.schema.json" },
            "armour": { "$ref": "item_slot.schema.json" },
            "wargear": { "type": "array", "items": { "$ref": "item_slot.schema.json" }, "default": [] }
          },
          "additionalProperties": false
        }
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": false
}
```

---

## `/data/factions/van_saar.faction.json`
```json
{
  "id": "van_saar",
  "name": "Van Saar",
  "style_tags": ["precision", "tech", "shooting"],
  "starting_credits": 1000,
  "starting_gang_size": 6,
  "intro_story_id": "story_van_saar_01",
  "archetype_pool": [
    "van_saar_leader",
    "van_saar_champion",
    "van_saar_ganger",
    "van_saar_juve"
  ],
  "default_loadout_pools": {
    "leader": ["lasgun", "plasma_pistol"],
    "champion": ["hotshot_lasgun", "lasgun"],
    "ganger": ["lasgun"],
    "juve": ["laspistol"]
  }
}
```

---

## `/data/fighters/van_saar_archetypes.json`
```json
[
  {
    "id": "van_saar_leader",
    "name": "Prime",
    "faction_id": "van_saar",
    "role": "leader",
    "tags": ["house", "van_saar"],
    "stats": { "m": 5, "ws": 4, "bs": 2, "s": 3, "t": 3, "w": 2, "i": 3, "a": 2, "ld": 5, "cl": 5, "wil": 6, "int": 5 },
    "loadout": {
      "equipped": {
        "primary": { "item_id": "lasgun" },
        "secondary": { "item_id": "plasma_pistol", "ammo_profile": "low" },
        "armour": { "item_id": "mesh_armour" },
        "wargear": []
      }
    }
  },
  {
    "id": "van_saar_champion",
    "name": "Archeotek",
    "faction_id": "van_saar",
    "role": "champion",
    "tags": ["house", "van_saar"],
    "stats": { "m": 5, "ws": 4, "bs": 2, "s": 3, "t": 3, "w": 2, "i": 3, "a": 2, "ld": 6, "cl": 6, "wil": 6, "int": 5 },
    "loadout": {
      "equipped": {
        "primary": { "item_id": "hotshot_lasgun" },
        "secondary": null,
        "armour": { "item_id": "mesh_armour" },
        "wargear": []
      }
    }
  },
  {
    "id": "van_saar_ganger",
    "name": "Tek",
    "faction_id": "van_saar",
    "role": "ganger",
    "tags": ["house", "van_saar"],
    "stats": { "m": 5, "ws": 4, "bs": 3, "s": 3, "t": 3, "w": 1, "i": 3, "a": 1, "ld": 7, "cl": 7, "wil": 7, "int": 6 },
    "loadout": {
      "equipped": {
        "primary": { "item_id": "lasgun" },
        "secondary": null,
        "armour": { "item_id": "mesh_armour" },
        "wargear": []
      }
    }
  },
  {
    "id": "van_saar_juve",
    "name": "Subtek",
    "faction_id": "van_saar",
    "role": "juve",
    "tags": ["house", "van_saar"],
    "stats": { "m": 5, "ws": 5, "bs": 4, "s": 3, "t": 3, "w": 1, "i": 4, "a": 1, "ld": 8, "cl": 8, "wil": 8, "int": 7 },
    "loadout": {
      "equipped": {
        "primary": null,
        "secondary": { "item_id": "laspistol" },
        "armour": { "item_id": "mesh_armour" },
        "wargear": []
      }
    }
  }
]
```

---

## `/data/items/weapons_core.json`
```json
[
  {
    "id": "lasgun",
    "name": "Lasgun",
    "category": "basic",
    "cost": 15,
    "profiles": {
      "standard": {
        "range": { "short": 12, "long": 24 },
        "acc": { "short": 1, "long": 0 },
        "s": 3,
        "ap": 0,
        "d": 1,
        "ammo": { "check": 2, "type": "standard" },
        "traits": []
      }
    }
  },
  {
    "id": "laspistol",
    "name": "Laspistol",
    "category": "pistol",
    "cost": 10,
    "profiles": {
      "standard": {
        "range": { "short": 8, "long": 16 },
        "acc": { "short": 1, "long": 0 },
        "s": 3,
        "ap": 0,
        "d": 1,
        "ammo": { "check": 2, "type": "standard" },
        "traits": []
      }
    }
  },
  {
    "id": "hotshot_lasgun",
    "name": "Hot-shot Lasgun",
    "category": "basic",
    "cost": 25,
    "profiles": {
      "standard": {
        "range": { "short": 12, "long": 24 },
        "acc": { "short": 1, "long": 0 },
        "s": 4,
        "ap": -1,
        "d": 1,
        "ammo": { "check": 4, "type": "hotshot" },
        "traits": []
      }
    }
  },
  {
    "id": "plasma_pistol",
    "name": "Plasma Pistol",
    "category": "pistol",
    "cost": 35,
    "profiles": {
      "low": {
        "range": { "short": 8, "long": 16 },
        "acc": { "short": 1, "long": 0 },
        "s": 5,
        "ap": -2,
        "d": 1,
        "ammo": { "check": 6, "type": "plasma_low" },
        "traits": [{ "id": "plentiful", "value": null }]
      },
      "max": {
        "range": { "short": 8, "long": 16 },
        "acc": { "short": 1, "long": 0 },
        "s": 7,
        "ap": -3,
        "d": 2,
        "ammo": { "check": 8, "type": "plasma_max" },
        "traits": [{ "id": "unstable", "value": null }]
      }
    }
  }
]
```

---

## `/data/items/armour_core.json`
```json
[
  {
    "id": "mesh_armour",
    "name": "Mesh Armour",
    "category": "wargear",
    "cost": 15,
    "armour": { "save": 5, "tags": ["armour"] }
  }
]
```
