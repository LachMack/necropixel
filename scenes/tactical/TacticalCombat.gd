extends Control

const HIDEOUT_SCENE: String = "res://scenes/ui/HideoutHub.tscn"

@onready var board_container: SubViewportContainer = %BoardContainer
@onready var board_viewport: SubViewport = %BoardViewport
@onready var world: Node2D = %World
@onready var move_ghosts: Node2D = %MoveGhosts
@onready var lbl_mission: Label = %MissionLabel
@onready var lbl_selected: Label = %SelectedLabel
@onready var lbl_turn: Label = %TurnLabel
@onready var lbl_ghost_count: Label = %GhostCountLabel
@onready var details_text: RichTextLabel = %DetailsText
@onready var btn_return: Button = %ReturnButton
@onready var btn_complete: Button = %CompleteButton
@onready var btn_end_turn: Button = %EndTurnButton

enum TurnSide { FRIENDLY, ENEMY }
var _turn_side: int = TurnSide.FRIENDLY

var _selected_token: Area2D = null

func _ready() -> void:
	if board_container == null or board_viewport == null or world == null or move_ghosts == null or lbl_mission == null or lbl_selected == null or lbl_turn == null or btn_return == null or btn_end_turn == null:
		push_error("TacticalCombat: Required nodes are null.")
		return
	if btn_complete == null:
		push_error("TacticalCombat: CompleteButton node is missing.")
		return
	if lbl_ghost_count == null:
		push_error("TacticalCombat: GhostCountLabel node is missing.")

	if board_viewport != null:
		board_viewport.physics_object_picking = true
		board_viewport.handle_input_locally = true

	_sync_board_viewport_size()
	board_container.resized.connect(_sync_board_viewport_size)

	btn_return.pressed.connect(_on_return_pressed)
	btn_complete.pressed.connect(_on_complete_pressed)
	btn_end_turn.pressed.connect(_on_end_turn_pressed)
	_refresh_turn_ui()

	var active: Dictionary = SaveGame.get_active_mission()
	var mission_id: String = str(active.get("mission_id", ""))
	if mission_id.is_empty():
		mission_id = "(none)"
	lbl_mission.text = "Mission: %s" % mission_id
	lbl_selected.text = "Selected: (none)"
	_clear_move_ghosts()
	if details_text != null:
		details_text.text = "Details: (none)"

	_spawn_tokens()

func _refresh_turn_ui() -> void:
	if lbl_turn == null:
		return
	if _turn_side == TurnSide.FRIENDLY:
		lbl_turn.text = "Turn: Friendly"
	else:
		lbl_turn.text = "Turn: Enemy"

func _on_end_turn_pressed() -> void:
	_turn_side = TurnSide.ENEMY if _turn_side == TurnSide.FRIENDLY else TurnSide.FRIENDLY
	_set_token_highlight(_selected_token, false)
	_selected_token = null
	if lbl_selected != null:
		lbl_selected.text = "Selected: (none)"
	if details_text != null:
		details_text.text = "Details: (none)"
	_clear_move_ghosts()
	_refresh_turn_ui()

func _sync_board_viewport_size() -> void:
	if board_container == null or board_viewport == null:
		return
	var container_size: Vector2 = board_container.size
	if container_size.x <= 0.0 or container_size.y <= 0.0:
		return
	var camera: Camera2D = world.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.position = _get_token_bounds_center(container_size)

func _spawn_tokens() -> void:
	if world == null:
		push_error("TacticalCombat: World node missing.")
		return

	for child in world.get_children():
		if child is Camera2D:
			continue
		if child == move_ghosts:
			continue
		child.queue_free()

	_selected_token = null
	lbl_selected.text = "Selected: (none)"
	if details_text != null:
		details_text.text = "Details: (none)"

	var fighters: Array = SaveGame.get_fighters()
	var start_x: float = 160.0
	var spacing_x: float = 140.0
	var friendly_y: float = 160.0
	var enemy_y: float = 340.0

	for i in range(6):
		var display_name: String = "Ally %d" % (i + 1)
		if i < fighters.size():
			var fighter_raw: Variant = fighters[i]
			if typeof(fighter_raw) == TYPE_DICTIONARY:
				var fighter: Dictionary = fighter_raw as Dictionary
				display_name = str(fighter.get("name", display_name))
		_spawn_token("friendly", display_name, i, Vector2(start_x + i * spacing_x, friendly_y))

	for i in range(6):
		_spawn_token("enemy", "Enemy %d" % (i + 1), i, Vector2(start_x + i * spacing_x, enemy_y))

	_sync_board_viewport_size()

func _get_token_bounds_center(fallback_size: Vector2) -> Vector2:
	var min_pos: Vector2 = Vector2(INF, INF)
	var max_pos: Vector2 = Vector2(-INF, -INF)
	var found: bool = false

	for child in world.get_children():
		if not (child is Area2D):
			continue
		var token: Area2D = child as Area2D
		if not token.has_meta("side"):
			continue
		var pos: Vector2 = token.position
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)
		found = true

	if not found:
		return fallback_size * 0.5

	return (min_pos + max_pos) * 0.5

func _spawn_token(side: String, display_name: String, index: int, spawn_pos: Vector2) -> void:
	var token: Area2D = Area2D.new()
	token.position = spawn_pos
	token.input_pickable = true
	token.set_meta("side", side)
	token.set_meta("display_name", display_name)
	token.set_meta("index", index)
	token.set_meta("fighter_index", index if side == "friendly" else -1)

	var base_color: Color = Color(0.3, 0.7, 1.0) if side == "friendly" else Color(1.0, 0.4, 0.4)
	token.set_meta("base_color", base_color)

	var body: Polygon2D = Polygon2D.new()
	body.name = "Body"
	body.color = base_color
	var size: float = 30.0
	body.polygon = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size, 0),
		Vector2(0, size),
		Vector2(-size, 0)
	])
	token.add_child(body)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = size
	collision.shape = shape
	token.add_child(collision)

	token.input_event.connect(Callable(self, "_on_token_input_event").bind(token))
	world.add_child(token)

func _on_token_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int, token: Area2D) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_select_token(token)

func _select_token(token: Area2D) -> void:
	if token == null:
		return

	var side: String = str(token.get_meta("side", "unknown"))
	if _turn_side == TurnSide.FRIENDLY and side != "friendly":
		return
	if _turn_side == TurnSide.ENEMY and side != "enemy":
		return

	var display_name: String = str(token.get_meta("display_name", "(unnamed)"))
	print("Selected token:", side, display_name)

	_set_token_highlight(_selected_token, false)
	_selected_token = token
	_set_token_highlight(_selected_token, true)

	lbl_selected.text = "Selected: %s - %s" % [side, display_name]
	_refresh_details_for_token(token)
	_refresh_move_ghosts_for_selected()


func _clear_move_ghosts() -> void:
	if move_ghosts == null:
		return
	for child in move_ghosts.get_children():
		child.queue_free()
	if lbl_ghost_count != null:
		lbl_ghost_count.text = "Ghosts: 0"

func _refresh_move_ghosts_for_selected() -> void:
	_clear_move_ghosts()
	if _turn_side != TurnSide.FRIENDLY:
		return
	if _selected_token == null:
		return
	var side: String = str(_selected_token.get_meta("side", "unknown"))
	if side != "friendly":
		return
	if move_ghosts == null:
		return

	var move_range: int = 5
	var idx: int = int(_selected_token.get_meta("fighter_index", -1))
	if idx < 0:
		idx = int(_selected_token.get_meta("index", -1))
	var fighters: Array = SaveGame.get_fighters()
	if idx >= 0 and idx < fighters.size():
		var raw_entry: Variant = fighters[idx]
		if typeof(raw_entry) == TYPE_DICTIONARY:
			var fighter: Dictionary = raw_entry as Dictionary
			var mv_val: Variant = null
			if fighter.has("movement"):
				mv_val = fighter.get("movement")
			elif fighter.has("m"):
				mv_val = fighter.get("m")
			if mv_val != null:
				move_range = int(mv_val)

	var step: float = 64.0
	var origin: Vector2 = _selected_token.position
	var ghost_size: float = 14.0
	var ghost_color: Color = Color(1.0, 1.0, 0.2, 0.45)
	var positions: Array[Vector2] = []
	positions.append(origin + Vector2(step, 0.0))
	positions.append(origin + Vector2(-step, 0.0))
	positions.append(origin + Vector2(0.0, step))
	positions.append(origin + Vector2(0.0, -step))

	for dx in range(-move_range, move_range + 1):
		for dy in range(-move_range, move_range + 1):
			if dx == 0 and dy == 0:
				continue
			if abs(dx) + abs(dy) > move_range:
				continue
			positions.append(origin + Vector2(dx * step, dy * step))

	var ghost_count: int = 0
	var spawned: Dictionary = {}
	for pos in positions:
		var key: String = "%d,%d" % [int(pos.x), int(pos.y)]
		if spawned.has(key):
			continue
		spawned[key] = true
		var ghost: Polygon2D = Polygon2D.new()
		ghost.color = ghost_color
		ghost.polygon = PackedVector2Array([
			Vector2(0, -ghost_size),
			Vector2(ghost_size, 0),
			Vector2(0, ghost_size),
			Vector2(-ghost_size, 0)
		])
		ghost.position = pos
		move_ghosts.add_child(ghost)
		ghost_count += 1

	if lbl_ghost_count != null:
		lbl_ghost_count.text = "Ghosts: %d" % ghost_count

func _refresh_details_for_token(token: Area2D) -> void:
	if details_text == null:
		push_error("TacticalCombat: DetailsText node is missing.")
		return
	if token == null:
		details_text.text = "Details: (none)"
		return

	var side: String = str(token.get_meta("side", "unknown"))
	if side != "friendly":
		details_text.text = "Enemy placeholder\n(No data)"
		return

	var fighter_index: int = int(token.get_meta("fighter_index", -1))
	var fighters: Array = SaveGame.get_fighters()
	if fighter_index < 0 or fighter_index >= fighters.size():
		details_text.text = "Details: (missing fighter data)"
		return

	var raw_entry: Variant = fighters[fighter_index]
	if typeof(raw_entry) != TYPE_DICTIONARY:
		details_text.text = "Details: (invalid fighter entry)"
		return

	var fighter: Dictionary = raw_entry as Dictionary
	var lines: Array[String] = []
	var name: String = str(fighter.get("name", "Unnamed"))
	lines.append("Name: %s" % name)

	var role_value: String = _get_first_string(fighter, ["archetype", "archetype_id", "type", "type_id", "role"])
	if not role_value.is_empty():
		lines.append("Role: %s" % role_value)

	var xp_value: String = _get_first_string(fighter, ["xp", "experience"])
	if not xp_value.is_empty():
		lines.append("XP: %s" % xp_value)

	var wound_value: String = _get_first_string(fighter, ["wounds", "w", "hp"])
	var move_value: String = _get_first_string(fighter, ["movement", "m"])
	var stat_parts: Array[String] = []
	if not wound_value.is_empty():
		stat_parts.append("W %s" % wound_value)
	if not move_value.is_empty():
		stat_parts.append("M %s" % move_value)
	if not stat_parts.is_empty():
		lines.append("Stats: %s" % " | ".join(stat_parts))

	var gear_items: Array[String] = []
	for key in ["weapons", "armour", "armor", "equipment", "gear"]:
		var raw_val: Variant = fighter.get(key, null)
		if typeof(raw_val) == TYPE_ARRAY:
			var arr: Array = raw_val as Array
			for entry in arr:
				var s: String = str(entry)
				if s.is_empty():
					continue
				gear_items.append(_resolve_item_name(s))
		elif typeof(raw_val) == TYPE_STRING:
			var s2: String = str(raw_val)
			if not s2.is_empty():
				gear_items.append(_resolve_item_name(s2))
	if not gear_items.is_empty():
		lines.append("Gear: %s" % ", ".join(gear_items))

	if lines.size() <= 1:
		lines.append("No additional fighter data.")

	details_text.text = "\n".join(lines)

func _get_first_string(data: Dictionary, keys: Array[String]) -> String:
	for key in keys:
		if data.has(key):
			var value: Variant = data.get(key, "")
			var s: String = str(value)
			if not s.is_empty():
				return s
	return ""

func _resolve_item_name(item_id: String) -> String:
	if item_id.is_empty():
		return ""
	DataLoader.load_all()
	var w: Dictionary = DataLoader.get_weapon(item_id)
	if not w.is_empty():
		return str(w.get("name", item_id))
	var a: Dictionary = DataLoader.get_armour(item_id)
	if not a.is_empty():
		return str(a.get("name", item_id))
	return item_id


func _set_token_highlight(token: Area2D, highlighted: bool) -> void:
	if token == null:
		return
	var body: Polygon2D = token.get_node_or_null("Body") as Polygon2D
	if body == null:
		return

	if highlighted:
		body.color = Color(1.0, 0.95, 0.35, 1.0)
		token.scale = Vector2(1.15, 1.15)
		return

	var base_color_raw: Variant = token.get_meta("base_color", body.color)
	if typeof(base_color_raw) == TYPE_COLOR:
		body.color = base_color_raw as Color
	token.scale = Vector2(1.0, 1.0)

func _on_return_pressed() -> void:
	SaveGame.clear_active_mission()
	get_tree().change_scene_to_file(HIDEOUT_SCENE)

func _on_complete_pressed() -> void:
	var active: Dictionary = SaveGame.get_active_mission()
	var mission_id: String = str(active.get("mission_id", "(none)"))
	if mission_id.is_empty():
		mission_id = "(none)"

	SaveGame.add_credits(50)
	SaveGame.append_mission_log({
		"mission_id": mission_id,
		"result": "completed",
		"reward_credits": 50
	})
	SaveGame.clear_active_mission()
	get_tree().change_scene_to_file(HIDEOUT_SCENE)
