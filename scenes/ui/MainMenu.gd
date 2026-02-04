extends Control

const HIDEOUT_SCENE: String = "res://scenes/ui/HideoutHub.tscn"
const DEFAULT_FACTION_ID: String = "van_saar"

@onready var btn_continue: Button = $Panel/VBox/ContinueButton
@onready var btn_new: Button = $Panel/VBox/NewGameButton
@onready var btn_quit: Button = $Panel/VBox/QuitButton

func _ready() -> void:
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_new.pressed.connect(_on_new_game_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	# Enable continue only if a save exists on disk
	btn_continue.disabled = not FileAccess.file_exists(SaveGame.get_save_path())

func _on_continue_pressed() -> void:
	var ok: bool = SaveGame.load_from_disk()
	if not ok:
		push_error("MainMenu: Failed to load save from disk.")
		return
	get_tree().change_scene_to_file(HIDEOUT_SCENE)

func _on_new_game_pressed() -> void:
	SaveGame.new_game(DEFAULT_FACTION_ID)
	var ok: bool = SaveGame.save_to_disk()
	if not ok:
		push_error("MainMenu: Failed to save new game to disk.")
		return
	get_tree().change_scene_to_file(HIDEOUT_SCENE)

func _on_quit_pressed() -> void:
	# In editor this won't quit, so keep it harmless.
	if OS.has_feature("editor"):
		print("Quit pressed (editor).")
	else:
		get_tree().quit()
