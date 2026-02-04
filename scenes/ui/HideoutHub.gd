extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"
const TACTICAL_SCENE: String = "res://scenes/tactical/TacticalCombat.tscn"
const DEFAULT_FACTION_ID: String = "van_saar" # MVP default until faction selection UI exists

# Necromunda-ish stat order for display
const STAT_ORDER: Array[String] = ["m", "ws", "bs", "s", "t", "w", "i", "a", "ld", "cl", "wil", "int"]

@onready var lbl_faction: Label = %FactionLabel
@onready var lbl_credits: Label = %CreditsLabel
@onready var lbl_fighter_count: Label = %FighterCountLabel
@onready var last_mission_label: Label = %LastMissionLabel
@onready var btn_menu: Button = %MenuButton

@onready var btn_save: Button = %SaveButton
@onready var btn_reload: Button = %ReloadButton
@onready var lbl_status: Label = %StatusLabel

@onready var tabs: TabBar = %Tabs
@onready var roster_view: HSplitContainer = %RosterView
@onready var stash_view: VBoxContainer = %StashView
@onready var missions_view: VBoxContainer = %MissionsView

@onready var roster_list: ItemList = %RosterList
@onready var details: RichTextLabel = %DetailsText

@onready var stash_summary: Label = %StashSummary
@onready var stash_list: ItemList = %StashList
@onready var stash_details: RichTextLabel = %StashDetailsText

@onready var btn_mission_start: Button = %StartTutorialButton
@onready var mission_log_list: ItemList = %MissionLogList
@onready var btn_clear_mission_log: Button = %ClearMissionLogButton

var _roster: Array = []
var _stash: Array = []

func _ready() -> void:
	# Guardrail: if these are null, the scene unique names aren't set correctly.
	if not _check_required_nodes():
		return

	_safe_connect(btn_menu, "pressed", Callable(self, "_on_back_to_menu"), "MenuButton")
	_safe_connect(btn_save, "pressed", Callable(self, "_on_save_pressed"), "SaveButton")
	_safe_connect(btn_reload, "pressed", Callable(self, "_on_reload_pressed"), "ReloadButton")
	_safe_connect(tabs, "tab_changed", Callable(self, "_on_tab_changed"), "Tabs")
	_safe_connect(roster_list, "item_selected", Callable(self, "_on_roster_selected"), "RosterList")
	_safe_connect(stash_list, "item_selected", Callable(self, "_on_stash_selected"), "StashList")
	_safe_connect(btn_mission_start, "pressed", Callable(self, "_on_start_mission_pressed"), "StartTutorialButton")
	_safe_connect(btn_clear_mission_log, "pressed", Callable(self, "_on_clear_mission_log_pressed"), "ClearMissionLogButton")

	_ensure_save_exists()
	_refresh_view()

func _check_required_nodes() -> bool:
	var missing: Array[String] = []
	if lbl_faction == null:
		missing.append("FactionLabel")
	if lbl_credits == null:
		missing.append("CreditsLabel")
	if lbl_fighter_count == null:
		missing.append("FighterCountLabel")
	if last_mission_label == null:
		missing.append("LastMissionLabel")
	if btn_menu == null:
		missing.append("MenuButton")
	if btn_save == null:
		missing.append("SaveButton")
	if btn_reload == null:
		missing.append("ReloadButton")
	if lbl_status == null:
		missing.append("StatusLabel")
	if tabs == null:
		missing.append("Tabs")
	if roster_view == null:
		missing.append("RosterView")
	if stash_view == null:
		missing.append("StashView")
	if missions_view == null:
		missing.append("MissionsView")
	if roster_list == null:
		missing.append("RosterList")
	if details == null:
		missing.append("DetailsText")
	if stash_summary == null:
		missing.append("StashSummary")
	if stash_list == null:
		missing.append("StashList")
	if stash_details == null:
		missing.append("StashDetailsText")
	if btn_mission_start == null:
		missing.append("StartTutorialButton")
	if mission_log_list == null:
		missing.append("MissionLogList")
	if btn_clear_mission_log == null:
		missing.append("ClearMissionLogButton")

	if missing.is_empty():
		return true

	push_error("HideoutHub: Required UI nodes are null: %s. Check unique_name_in_owner flags in HideoutHub.tscn." % ", ".join(missing))
	return false

func _safe_connect(node: Object, signal_name: StringName, callable: Callable, label: String) -> bool:
	if node == null:
		push_error("HideoutHub: Missing node for %s" % label)
		return false
	if not node.has_signal(signal_name):
		push_error("HideoutHub: Node '%s' missing signal '%s'" % [label, signal_name])
		return false
	if node.is_connected(signal_name, callable):
		return true
	var err: int = node.connect(signal_name, callable)
	if err != OK:
		push_error("HideoutHub: Failed to connect %s.%s (err %d)" % [label, signal_name, err])
		return false
	return true

func _ensure_save_exists() -> void:
	# 1) If we already have a game in memory, we're good.
	if SaveGame.has_game():
		return

	# 2) Try loading from disk.
	SaveGame.load_from_disk()
	if SaveGame.has_game():
		return

	# 3) No save found -> create a default new game (temporary until faction selection exists).
	SaveGame.new_game(DEFAULT_FACTION_ID)

func _refresh_view() -> void:
	lbl_status.text = ""

	_ensure_save_exists()

	lbl_faction.text = "Faction: %s" % SaveGame.get_faction_id()
	lbl_credits.text = "Credits: %d" % SaveGame.get_credits()
	_refresh_last_mission_banner()

	var save: Dictionary = SaveGame.get_current()
	_roster = save.get("fighters", []) as Array
	_stash = save.get("stash", []) as Array

	lbl_fighter_count.text = "Fighters: %d" % _roster.size()

	_refresh_roster()
	_refresh_stash()
	_apply_tab(tabs.current_tab)

func _refresh_roster() -> void:
	roster_list.clear()

	for i in range(_roster.size()):
		var f: Dictionary = _roster[i] as Dictionary
		var name := str(f.get("name", "Unnamed"))
		var role := _infer_role_from_archetype(str(f.get("archetype_id", "")))
		roster_list.add_item("%s  [%s]" % [name, role])

	if _roster.is_empty():
		details.text = "[i]No fighters found.[/i]"
	else:
		details.text = "[i]Select a fighter to view details.[/i]"

func _refresh_stash() -> void:
	stash_list.clear()

	if _stash.is_empty():
		stash_summary.text = "Items: 0"
		stash_list.add_item("No items in stash.")
		stash_details.text = "[i]No items in stash.[/i]"
		return

	stash_summary.text = "Items: %d" % _stash.size()

	for entry in _stash:
		var item_id: String = _stash_entry_id(entry)
		var item_name: String = _resolve_item_name(item_id)
		if item_id.is_empty():
			stash_list.add_item("%s" % item_name)
		else:
			stash_list.add_item("%s (%s)" % [item_name, item_id])

	stash_details.text = "[i]Select an item to view details.[/i]"

func _on_tab_changed(tab_index: int) -> void:
	_apply_tab(tab_index)

func _apply_tab(tab_index: int) -> void:
	roster_view.visible = (tab_index == 0)
	stash_view.visible = (tab_index == 1)
	missions_view.visible = (tab_index == 2)
	if tab_index == 2:
		_refresh_mission_log()
		_refresh_last_mission_banner()

func _on_roster_selected(index: int) -> void:
	if index < 0 or index >= _roster.size():
		return

	if not DataLoader.is_loaded():
		DataLoader.load_all()

	var f: Dictionary = _roster[index] as Dictionary
	var name := str(f.get("name", "Unnamed"))
	var archetype_id := str(f.get("archetype_id", ""))
	var xp := int(f.get("xp", 0))
	var role := _infer_role_from_archetype(archetype_id)

	var archetype: Dictionary = DataLoader.get_fighter_archetype(archetype_id)
	var stats: Dictionary = archetype.get("stats", {}) as Dictionary

	var loadout: Dictionary = f.get("loadout", {}) as Dictionary
	var equipped: Dictionary = loadout.get("equipped", {}) as Dictionary

	details.text = ""
	details.append_text("[b]%s[/b]  [%s]\n" % [name, role])
	details.append_text("Archetype: %s\n" % archetype_id)
	details.append_text("XP: %d\n\n" % xp)

	details.append_text("[b]Stats[/b]\n")
	details.append_text(_format_stats(stats) + "\n\n")

	details.append_text("[b]Equipped[/b]\n")
	details.append_text("Primary: %s\n" % _equipped_name(equipped.get("primary", null)))
	details.append_text("Secondary: %s\n" % _equipped_name(equipped.get("secondary", null)))
	details.append_text("Armour: %s\n" % _equipped_name(equipped.get("armour", null)))

func _on_stash_selected(index: int) -> void:
	if index < 0 or index >= _stash.size():
		return

	var entry: Variant = _stash[index]
	var item_id: String = _stash_entry_id(entry)
	if item_id.is_empty():
		stash_details.text = "[i]Unknown item.[/i]"
		return

	var item_data: Dictionary = _get_item_data(item_id)
	var name: String = _resolve_item_name(item_id)

	stash_details.text = ""
	stash_details.append_text("[b]%s[/b]\n" % name)
	stash_details.append_text("ID: %s\n" % item_id)

	var category: String = ""
	if not item_data.is_empty():
		if item_data.has("category"):
			category = str(item_data.get("category", ""))
		elif item_data.has("armour"):
			category = "armour"

	if not category.is_empty():
		stash_details.append_text("Category: %s\n" % category)

	var cost_value: Variant = null
	if not item_data.is_empty() and item_data.has("cost"):
		cost_value = item_data.get("cost")
	if cost_value != null:
		stash_details.append_text("Cost: %s\n" % str(cost_value))

func _on_start_mission_pressed() -> void:
	_ensure_save_exists()
	if not SaveGame.has_game():
		push_error("HideoutHub: No savegame available to start mission.")
		return
	SaveGame.set_active_mission("tutorial_skirmish")
	get_tree().change_scene_to_file(TACTICAL_SCENE)

func _refresh_mission_log() -> void:
	if mission_log_list == null:
		push_error("HideoutHub: MissionLogList is missing.")
		return

	mission_log_list.clear()
	var log: Array = SaveGame.get_mission_log()
	if log.is_empty():
		mission_log_list.add_item("(empty)")
		return

	var shown: int = 0
	var lower_bound: int = maxi(-1, log.size() - 21)
	for i in range(log.size() - 1, lower_bound, -1):
		if shown >= 20:
			break
		var line: String = "(invalid log entry)"
		var raw: Variant = log[i]
		if typeof(raw) == TYPE_DICTIONARY:
			var entry: Dictionary = raw as Dictionary
			var result: String = str(entry.get("result", "unknown"))
			var mission_id: String = str(entry.get("mission_id", "(unknown)"))
			var reward_text: String = ""
			var reward_val: Variant = entry.get("reward_credits", null)
			if reward_val != null:
				reward_text = " (+%s)" % str(reward_val)
			line = "%s: %s%s" % [result, mission_id, reward_text]
		mission_log_list.add_item(line)
		shown += 1

func _refresh_last_mission_banner() -> void:
	if last_mission_label == null:
		push_error("HideoutHub: LastMissionLabel is missing.")
		return

	var log: Array = SaveGame.get_mission_log()
	if log.is_empty():
		last_mission_label.text = "Last mission: (none)"
		return

	var raw: Variant = log[log.size() - 1]
	if typeof(raw) != TYPE_DICTIONARY:
		last_mission_label.text = "Last mission: (invalid entry)"
		return

	var entry: Dictionary = raw as Dictionary
	var result: String = str(entry.get("result", "unknown"))
	var mission_id: String = str(entry.get("mission_id", "(unknown)"))
	var reward_text: String = ""
	var reward: Variant = entry.get("reward_credits", null)
	if reward != null:
		reward_text = " (+%s)" % str(reward)
	last_mission_label.text = "Last mission: %s %s%s" % [result, mission_id, reward_text]

func _on_clear_mission_log_pressed() -> void:
	SaveGame.clear_mission_log()
	_refresh_mission_log()
	_refresh_last_mission_banner()

func _stash_entry_id(entry: Variant) -> String:
	if entry == null:
		return ""
	var t: int = typeof(entry)
	if t == TYPE_STRING:
		return str(entry)
	if t == TYPE_DICTIONARY:
		var d: Dictionary = entry as Dictionary
		if d.has("item_id"):
			return str(d.get("item_id", ""))
		if d.has("id"):
			return str(d.get("id", ""))
	return ""

func _get_item_data(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}
	if not DataLoader.is_loaded():
		DataLoader.load_all()

	var w: Dictionary = DataLoader.get_weapon(item_id)
	if not w.is_empty():
		return w

	var a: Dictionary = DataLoader.get_armour(item_id)
	if not a.is_empty():
		return a

	return {}

func _format_stats(stats: Dictionary) -> String:
	# Produces a compact, ordered line: M 5\" | WS 3+ | BS 3+ | S 3 | ...
	if stats.is_empty():
		return "(no stats)"

	var parts: Array[String] = []

	for key in STAT_ORDER:
		if stats.has(key):
			var label := _stat_label(key)
			var value: Variant = stats.get(key)
			parts.append("%s %s" % [label, _stat_value_to_string(key, value)])

	# Include any extra keys not in our order at the end (stable, readable)
	for k in stats.keys():
		var ks := str(k)
		if STAT_ORDER.has(ks):
			continue
		parts.append("%s %s" % [_stat_label(ks), _stat_value_to_string(ks, stats.get(k))])

	return " | ".join(parts)

func _stat_label(key: String) -> String:
	match key:
		"m": return "M"
		"ws": return "WS"
		"bs": return "BS"
		"s": return "S"
		"t": return "T"
		"w": return "W"
		"i": return "I"
		"a": return "A"
		"ld": return "Ld"
		"cl": return "Cl"
		"wil": return "Wil"
		"int": return "Int"
		_: return key.capitalize()

func _stat_value_to_string(key: String, value: Variant) -> String:
	# Some common niceties: movement inches, ensure + stays visible, etc.
	if value == null:
		return "-"
	var t := typeof(value)
	if t == TYPE_INT or t == TYPE_FLOAT:
		if key == "m":
			return "%s\"" % str(value)
		return str(value)
	return str(value)

func _equipped_name(slot_value: Variant) -> String:
	if slot_value == null:
		return "(none)"
	if typeof(slot_value) != TYPE_DICTIONARY:
		return "(invalid)"
	var d: Dictionary = slot_value as Dictionary
	return _resolve_item_name(str(d.get("item_id", "")))

func _resolve_item_name(item_id: String) -> String:
	if item_id.is_empty():
		return "(none)"
	if not DataLoader.is_loaded():
		DataLoader.load_all()

	var w: Dictionary = DataLoader.get_weapon(item_id)
	if not w.is_empty():
		return str(w.get("name", item_id))

	var a: Dictionary = DataLoader.get_armour(item_id)
	if not a.is_empty():
		return str(a.get("name", item_id))

	return item_id

func _infer_role_from_archetype(archetype_id: String) -> String:
	if archetype_id.is_empty():
		return "unknown"
	if not DataLoader.is_loaded():
		DataLoader.load_all()
	var a: Dictionary = DataLoader.get_fighter_archetype(archetype_id)
	if a.is_empty():
		return "unknown"
	return str(a.get("role", "unknown"))

func _on_save_pressed() -> void:
	if SaveGame.save_to_disk():
		lbl_status.text = "Saved."
	else:
		lbl_status.text = "Save failed."

func _on_reload_pressed() -> void:
	SaveGame.clear()
	SaveGame.load_from_disk()
	_ensure_save_exists()
	lbl_status.text = "Reloaded."
	_refresh_view()

func _on_back_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
