extends Node
class_name SaveGame

static var _current: Dictionary = {}

static func new_game(faction_id: String) -> void:
	var save: Dictionary = GangGenerator.generate_new_gang(faction_id)
	if save.is_empty():
		push_error("SaveGame.new_game(): GangGenerator failed for faction_id: %s" % faction_id)
		return
	_current = save

static func clear() -> void:
	_current = {}

static func get_current() -> Dictionary:
	return _current.duplicate(true)

static func has_game() -> bool:
	return not _current.is_empty()

static func get_fighters() -> Array:
	if _current.is_empty():
		return []
	return _current.get("fighters", []) as Array

static func get_credits() -> int:
	return int(_current.get("credits", 0))

static func get_faction_id() -> String:
	return str(_current.get("faction_id", ""))

static func get_save_path() -> String:
	return "user://savegame.json"

static func set_active_mission(mission_id: String, data: Dictionary = {}) -> void:
	if mission_id.is_empty():
		push_error("SaveGame.set_active_mission(): mission_id is empty.")
		return
	if _current.is_empty():
		push_error("SaveGame.set_active_mission(): No current savegame loaded.")
		return

	var active_mission: Dictionary = {"mission_id": mission_id}
	for key in data.keys():
		active_mission[str(key)] = data.get(key)

	_current["active_mission"] = active_mission
	save_to_disk()

static func clear_active_mission() -> void:
	if _current.is_empty():
		push_error("SaveGame.clear_active_mission(): No current savegame loaded.")
		return
	if _current.has("active_mission"):
		_current.erase("active_mission")
	save_to_disk()

static func get_active_mission() -> Dictionary:
	if _current.is_empty():
		return {}
	var data: Variant = _current.get("active_mission", {})
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data as Dictionary

static func add_credits(amount: int) -> void:
	if _current.is_empty():
		push_error("SaveGame.add_credits(): No current savegame loaded.")
		return
	var credits: int = int(_current.get("credits", 0))
	_current["credits"] = credits + amount
	save_to_disk()

static func append_mission_log(entry: Dictionary) -> void:
	if _current.is_empty():
		push_error("SaveGame.append_mission_log(): No current savegame loaded.")
		return
	var mission_log: Array = _current.get("mission_log", []) as Array
	mission_log.append(entry)
	_current["mission_log"] = mission_log
	save_to_disk()

static func get_mission_log() -> Array:
	if _current.is_empty():
		return []
	return _current.get("mission_log", []) as Array

static func clear_mission_log() -> void:
	if _current.is_empty():
		push_error("SaveGame.clear_mission_log(): No current savegame loaded.")
		return
	_current["mission_log"] = []
	save_to_disk()

static func save_to_disk() -> bool:
	if _current.is_empty():
		push_error("SaveGame.save_to_disk(): No current savegame to write.")
		return false

	var json_text: String = JSON.stringify(_current, "\t")
	var path: String = get_save_path()

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveGame.save_to_disk(): Unable to open file for writing: %s" % path)
		return false

	file.store_string(json_text)
	file.flush()
	file.close()

	return true

static func load_from_disk() -> bool:
	var path: String = get_save_path()

	if not FileAccess.file_exists(path):
		push_error("SaveGame.load_from_disk(): Save file does not exist: %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveGame.load_from_disk(): Unable to open file for reading: %s" % path)
		return false

	var text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("SaveGame.load_from_disk(): Invalid JSON: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return false

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("SaveGame.load_from_disk(): Expected JSON object at root.")
		return false

	_current = json.data as Dictionary
	return true
