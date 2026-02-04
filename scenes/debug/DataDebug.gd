extends Node

func _ready() -> void:
	print("=== DATA LOADER TEST ===")

	var ok: bool = DataLoader.load_all()
	print("DataLoader.load_all() =", ok)
	if not ok:
		print("ERROR:", DataLoader.get_last_error())
		return

	var factions: Array = DataLoader.get_factions()
	var archetypes: Array = DataLoader.get_fighter_archetypes()
	var weapons: Array = DataLoader.get_weapons()
	var armour: Array = DataLoader.get_armour_items()

	print("Factions:", factions.size())
	print("Fighter archetypes:", archetypes.size())
	print("Weapons:", weapons.size())
	print("Armour:", armour.size())

	print("\n=== GANG GENERATION TEST ===")

	SaveGame.new_game("van_saar")
	var created: Dictionary = SaveGame.get_current()

	if created.is_empty():
		print("ERROR: SaveGame is empty after new_game()")
		return

	print("Created Campaign ID:", str(created.get("campaign_id", "")))
	print("Created Faction:", str(created.get("faction_id", "")))
	print("Created Credits:", int(created.get("credits", 0)))
	var created_roster: Array = created.get("fighters", []) as Array
	print("Created Fighter count:", created_roster.size())

	print("\n=== PERSISTENCE TEST (SAVE -> CLEAR -> LOAD) ===")

	var save_ok: bool = SaveGame.save_to_disk()
	print("SaveGame.save_to_disk() =", save_ok, " path =", SaveGame.get_save_path())
	if not save_ok:
		print("FAIL: Save to disk failed")
		return

	SaveGame.clear()
	if SaveGame.has_game():
		print("FAIL: SaveGame.clear() did not clear current state")
		return

	var load_ok: bool = SaveGame.load_from_disk()
	print("SaveGame.load_from_disk() =", load_ok)
	if not load_ok:
		print("FAIL: Load from disk failed")
		return

	var loaded: Dictionary = SaveGame.get_current()
	if loaded.is_empty():
		print("FAIL: Loaded savegame is empty")
		return

	# Compare key fields
	var test_pass: bool = true

	if str(loaded.get("faction_id", "")) != str(created.get("faction_id", "")):
		test_pass = false
		print("Mismatch: faction_id", loaded.get("faction_id"), "!=", created.get("faction_id"))

	if int(loaded.get("credits", 0)) != int(created.get("credits", 0)):
		test_pass = false
		print("Mismatch: credits", loaded.get("credits"), "!=", created.get("credits"))

	var loaded_roster: Array = loaded.get("fighters", []) as Array
	if loaded_roster.size() != created_roster.size():
		test_pass = false
		print("Mismatch: fighter count", loaded_roster.size(), "!=", created_roster.size())

	# Optional: compare first fighter identity
	if loaded_roster.size() > 0 and created_roster.size() > 0:
		var lf: Dictionary = loaded_roster[0] as Dictionary
		var cf: Dictionary = created_roster[0] as Dictionary
		if str(lf.get("archetype_id", "")) != str(cf.get("archetype_id", "")):
			test_pass = false
			print(
				"Mismatch: first fighter archetype_id",
				lf.get("archetype_id"),
				"!=",
				cf.get("archetype_id")
			)

	print("\n=== RESULT ===")
	if test_pass:
		print("PASS: Save/Load persistence works.")
	else:
		print("FAIL: Persistence mismatch detected.")

	print("\n=== TEST COMPLETE ===")
