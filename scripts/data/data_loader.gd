extends Node
class_name DataLoader

const SCHEMA_FILES := {
	"item_slot": "res://data/schemas/item_slot.schema.json",
	"weapon": "res://data/schemas/weapon.schema.json",
	"fighter": "res://data/schemas/fighter.schema.json"
}

const FACTION_FILE := "res://data/factions/van_saar.faction.json"
const FIGHTER_ARCHETYPES_FILE := "res://data/fighters/van_saar_archetypes.json"
const WEAPONS_FILE := "res://data/items/weapons_core.json"
const ARMOUR_FILE := "res://data/items/armour_core.json"

const REQUIRED_FACTION_KEYS := ["id", "name"]
const REQUIRED_FIGHTER_KEYS := ["id", "name", "faction_id", "role", "stats", "loadout"]
const REQUIRED_WEAPON_KEYS := ["id", "name", "category", "profiles"]
# category is optional for armour in v0.1
const REQUIRED_ARMOUR_KEYS := ["id", "name", "armour"]

static var _loaded: bool = false
static var _last_error: String = ""

static var _schemas: Dictionary = {}

static var _faction_by_id: Dictionary = {}
static var _faction_list: Array = []

static var _fighter_archetypes: Array = []
static var _fighter_by_id: Dictionary = {}

static var _weapons: Array = []
static var _weapon_by_id: Dictionary = {}

static var _armour: Array = []
static var _armour_by_id: Dictionary = {}

static var _item_by_id: Dictionary = {}


static func is_loaded() -> bool:
	return _loaded


static func get_last_error() -> String:
	return _last_error


static func load_all() -> bool:
	if _loaded:
		return true

	_clear()

	if not _load_schemas():
		return false
	if not _load_factions():
		return false
	if not _load_weapons():
		return false
	if not _load_armour():
		return false
	if not _build_item_index():
		return false
	if not _load_fighters():
		return false
	if not _validate_references():
		return false

	_loaded = true
	return true


static func get_schema(id: String) -> Dictionary:
	var schema = _schemas.get(id, null)
	if schema == null:
		return {}
	return schema.duplicate(true)


static func get_faction(id: String) -> Dictionary:
	var faction = _faction_by_id.get(id, null)
	if faction == null:
		return {}
	return faction.duplicate(true)


static func get_factions() -> Array:
	return _faction_list.duplicate(true)


static func get_fighter_archetype(id: String) -> Dictionary:
	var fighter = _fighter_by_id.get(id, null)
	if fighter == null:
		return {}
	return fighter.duplicate(true)


static func get_fighter_archetypes() -> Array:
	return _fighter_archetypes.duplicate(true)


static func get_weapon(id: String) -> Dictionary:
	var weapon = _weapon_by_id.get(id, null)
	if weapon == null:
		return {}
	return weapon.duplicate(true)


static func get_weapons() -> Array:
	return _weapons.duplicate(true)


static func get_armour(id: String) -> Dictionary:
	var armour = _armour_by_id.get(id, null)
	if armour == null:
		return {}
	return armour.duplicate(true)


static func get_armour_items() -> Array:
	return _armour.duplicate(true)


static func _clear() -> void:
	_loaded = false
	_last_error = ""
	_schemas = {}
	_faction_by_id = {}
	_faction_list = []
	_fighter_archetypes = []
	_fighter_by_id = {}
	_weapons = []
	_weapon_by_id = {}
	_armour = []
	_armour_by_id = {}
	_item_by_id = {}


static func _load_schemas() -> bool:
	for key in SCHEMA_FILES.keys():
		var data = _load_json(SCHEMA_FILES[key], "schema:%s" % key)
		if data == null:
			return false
		_schemas[key] = data
	return true


static func _load_factions() -> bool:
	var data = _load_json(FACTION_FILE, "faction")
	if data == null:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return _fail("Faction JSON must be an object: %s" % FACTION_FILE)
	if not _validate_required_keys(data, REQUIRED_FACTION_KEYS, "faction"):
		return false

	var faction_id := str(data.get("id", ""))
	if faction_id.is_empty():
		return _fail("Faction id cannot be empty")
	if _faction_by_id.has(faction_id):
		return _fail("Duplicate faction id: %s" % faction_id)

	_faction_by_id[faction_id] = data
	_faction_list.append(data)
	return true


static func _load_weapons() -> bool:
	var data = _load_json(WEAPONS_FILE, "weapons")
	if data == null:
		return false
	if typeof(data) != TYPE_ARRAY:
		return _fail("Weapons JSON must be an array: %s" % WEAPONS_FILE)

	for entry in data:
		if typeof(entry) != TYPE_DICTIONARY:
			return _fail("Weapon entry must be an object")
		if not _validate_required_keys(entry, REQUIRED_WEAPON_KEYS, "weapon"):
			return false

		var weapon_id := str(entry.get("id", ""))
		if weapon_id.is_empty():
			return _fail("Weapon id cannot be empty")
		if _weapon_by_id.has(weapon_id):
			return _fail("Duplicate weapon id: %s" % weapon_id)

		_weapon_by_id[weapon_id] = entry
		_weapons.append(entry)

	return true


static func _load_armour() -> bool:
	var data = _load_json(ARMOUR_FILE, "armour")
	if data == null:
		return false
	if typeof(data) != TYPE_ARRAY:
		return _fail("Armour JSON must be an array: %s" % ARMOUR_FILE)

	for entry in data:
		if typeof(entry) != TYPE_DICTIONARY:
			return _fail("Armour entry must be an object")
		if not _validate_required_keys(entry, REQUIRED_ARMOUR_KEYS, "armour"):
			return false

		var armour_id := str(entry.get("id", ""))
		if armour_id.is_empty():
			return _fail("Armour id cannot be empty")
		if _armour_by_id.has(armour_id):
			return _fail("Duplicate armour id: %s" % armour_id)

		_armour_by_id[armour_id] = entry
		_armour.append(entry)

	return true


static func _build_item_index() -> bool:
	_item_by_id = {}

	for w in _weapons:
		var wid := str(w.get("id", ""))
		if wid.is_empty():
			return _fail("Weapon missing id while building item index")
		_item_by_id[wid] = w

	for a in _armour:
		var aid := str(a.get("id", ""))
		if aid.is_empty():
			return _fail("Armour missing id while building item index")
		_item_by_id[aid] = a

	return true


static func _load_fighters() -> bool:
	var data = _load_json(FIGHTER_ARCHETYPES_FILE, "fighter_archetypes")
	if data == null:
		return false
	if typeof(data) != TYPE_ARRAY:
		return _fail("Fighter archetypes JSON must be an array: %s" % FIGHTER_ARCHETYPES_FILE)

	for entry in data:
		if typeof(entry) != TYPE_DICTIONARY:
			return _fail("Fighter archetype entry must be an object")
		if not _validate_required_keys(entry, REQUIRED_FIGHTER_KEYS, "fighter_archetype"):
			return false

		var fighter_id := str(entry.get("id", ""))
		if fighter_id.is_empty():
			return _fail("Fighter archetype id cannot be empty")
		if _fighter_by_id.has(fighter_id):
			return _fail("Duplicate fighter archetype id: %s" % fighter_id)

		_fighter_by_id[fighter_id] = entry
		_fighter_archetypes.append(entry)

	return true


static func _validate_references() -> bool:
	for fighter in _fighter_archetypes:
		var fid := str(fighter.get("id", ""))
		var faction_id := str(fighter.get("faction_id", ""))
		if not _faction_by_id.has(faction_id):
			return _fail("Fighter '%s' references missing faction_id: %s" % [fid, faction_id])

		var loadout: Dictionary = fighter.get("loadout", {})
		var equipped: Dictionary = loadout.get("equipped", {})

		if not _validate_item_slot_ref(fid, "primary", equipped.get("primary", null)):
			return false
		if not _validate_item_slot_ref(fid, "secondary", equipped.get("secondary", null)):
			return false
		if not _validate_item_slot_ref(fid, "armour", equipped.get("armour", null)):
			return false

		var wargear_arr: Array = equipped.get("wargear", [])
		if typeof(wargear_arr) != TYPE_ARRAY:
			return _fail("Fighter '%s' loadout.equipped.wargear must be an array" % fid)

		for i in range(wargear_arr.size()):
			if not _validate_item_slot_ref(fid, "wargear[%d]" % i, wargear_arr[i]):
				return false

	return true


static func _validate_item_slot_ref(fighter_id: String, slot_label: String, slot_value: Variant) -> bool:
	if slot_value == null:
		return true
	if typeof(slot_value) != TYPE_DICTIONARY:
		return _fail("Fighter '%s' slot '%s' must be an object or null" % [fighter_id, slot_label])

	var item_id := str(slot_value.get("item_id", ""))
	if item_id.is_empty():
		return _fail("Fighter '%s' slot '%s' has empty item_id" % [fighter_id, slot_label])
	if not _item_by_id.has(item_id):
		return _fail("Fighter '%s' slot '%s' references missing item_id: %s" % [fighter_id, slot_label, item_id])

	return true


static func _load_json(path: String, label: String) -> Variant:
	if not FileAccess.file_exists(path):
		_fail("Missing JSON file (%s): %s" % [label, path])
		return null

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open JSON file (%s): %s" % [label, path])
		return null

	var text := file.get_as_text()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		_fail("Invalid JSON (%s): %s at line %d" % [label, json.get_error_message(), json.get_error_line()])
		return null

	return json.data


static func _validate_required_keys(obj: Dictionary, keys: Array, label: String) -> bool:
	for key in keys:
		if not obj.has(key):
			return _fail("%s missing required key '%s'" % [label, key])
	return true


static func _fail(message: String) -> bool:
	_last_error = message
	push_error("DataLoader: %s" % message)
	return false
