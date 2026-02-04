extends Node

const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"
const HIDEOUT_SCENE: String = "res://scenes/ui/HideoutHub.tscn"

func _ready() -> void:
	# Boot flow: try load save. If not available, go to menu.
	var loaded: bool = SaveGame.load_from_disk()
	if loaded:
		get_tree().change_scene_to_file(HIDEOUT_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
