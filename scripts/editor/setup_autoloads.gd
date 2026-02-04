@tool
extends EditorScript

const AUTOLOAD_NAME := "DataLoader"
const AUTOLOAD_PATH := "res://scripts/data/data_loader.gd"

func _run() -> void:
	if ProjectSettings.has_setting("autoload/%s" % AUTOLOAD_NAME):
		print("Autoload already configured:", AUTOLOAD_NAME, "->", AUTOLOAD_PATH)
		return

	# Add as autoload singleton
	ProjectSettings.set_setting("autoload/%s" % AUTOLOAD_NAME, AUTOLOAD_PATH)
	ProjectSettings.save()
	print("Added autoload singleton:", AUTOLOAD_NAME, "->", AUTOLOAD_PATH)
