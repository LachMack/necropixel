extends Node
class_name GangGenerator

static func generate_new_gang(faction_id: String) -> Dictionary:
	if not DataLoader.load_all():
		push_error("GangGenerator: DataLoader failed: %s" % DataLoader.get_last_error())
		return {}

	var faction: Dictionary = DataLoader.get_faction(faction_id)
	if faction.is_empty():
		push_error("GangGenerator: Unknown faction_id: %s" % faction_id)
		return {}

	var archetypes: Array = DataLoader.get_fighter_archetypes()

	# Deterministic role order (repeatable tests)
	var role_order: Array = ["leader", "champion", "ganger", "juve"]
	var role_counts: Dictionary = {
		"leader": 1,
		"champion": 1,
		"ganger": 3,
		"juve": 1
	}

	var roster: Array = []

	for role in role_order:
		var needed: int = int(role_counts.get(role, 0))
		if needed <= 0:
			continue

		# Find ONE matching archetype for this role, then instantiate it N times.
		var chosen: Dictionary = _find_archetype(archetypes, faction_id, str(role))
		if chosen.is_empty():
			push_error("GangGenerator: Missing archetype for role '%s' in faction '%s'" % [role, faction_id])
			return {}

		for i in range(needed):
			roster.append(_instantiate_fighter(chosen))

	var savegame: Dictionary = {
		"campaign_id": _generate_id("campaign"),
		"faction_id": faction_id,
		"credits": int(faction.get("starting_credits", 0)),
		"fighters": roster,
		"stash": [],
		"completed_missions": []
	}
	var stash: Array = savegame.get("stash", []) as Array
	if stash.is_empty():
		stash = ["lasgun", "mesh_armour"]
	savegame["stash"] = stash

	return savegame


static func _find_archetype(archetypes: Array, faction_id: String, role: String) -> Dictionary:
	for entry in archetypes:
		var a: Dictionary = entry as Dictionary
		if str(a.get("faction_id", "")) != faction_id:
			continue
		if str(a.get("role", "")) != role:
			continue
		return a
	return {}


static func _instantiate_fighter(archetype: Dictionary) -> Dictionary:
	return {
		"id": _generate_id("fighter"),
		"archetype_id": str(archetype.get("id", "")),
		"name": str(archetype.get("name", "Unnamed")),
		"xp": 0,
		"status": {
			"alive": true,
			"injuries": []
		},
		"loadout": archetype.get("loadout", {}).duplicate(true)
	}


static func _generate_id(prefix: String) -> String:
	return "%s_%s" % [prefix, str(Time.get_unix_time_from_system()) + "_" + str(randi())]
