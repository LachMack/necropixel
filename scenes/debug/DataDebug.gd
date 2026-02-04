extends Node

func _ready() -> void:
	var ok := DataLoader.load_all()
	print("DataLoader.load_all() =", ok)
	if not ok:
		print("ERROR:", DataLoader.get_last_error())
		return

	var factions = DataLoader.get_factions()
	var fighters = DataLoader.get_fighter_archetypes()
	var weapons = DataLoader.get_weapons()
	var armour = DataLoader.get_armour_items()

	print("Factions:", factions.size())
	print("Fighter archetypes:", fighters.size())
	print("Weapons:", weapons.size())
	print("Armour:", armour.size())

	var vs = DataLoader.get_faction("van_saar")
	print("van_saar faction:", vs)

	var lasgun = DataLoader.get_weapon("lasgun")
	print("lasgun:", lasgun)

	var mesh = DataLoader.get_armour("mesh_armour")
	print("mesh_armour:", mesh)
