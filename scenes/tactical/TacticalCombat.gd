extends Control

const HIDEOUT_SCENE: String = "res://scenes/ui/HideoutHub.tscn"

@onready var board_container: SubViewportContainer = %BoardContainer
@onready var board_viewport: SubViewport = %BoardViewport
@onready var world: Node2D = %World
@onready var lbl_mission: Label = %MissionLabel
@onready var lbl_selected: Label = %SelectedLabel
@onready var btn_return: Button = %ReturnButton
@onready var btn_complete: Button = %CompleteButton

var _selected_token: Area2D = null

func _ready() -> void:
	if board_container == null or board_viewport == null or world == null or lbl_mission == null or lbl_selected == null or btn_return == null:
		push_error("TacticalCombat: Required nodes are null.")
		return
	if btn_complete == null:
		push_error("TacticalCombat: CompleteButton node is missing.")
		return

	if board_viewport != null:
		board_viewport.physics_object_picking = true
		board_viewport.handle_input_locally = true

	_sync_board_viewport_size()
	board_container.resized.connect(_sync_board_viewport_size)

	btn_return.pressed.connect(_on_return_pressed)
	btn_complete.pressed.connect(_on_complete_pressed)

	var active: Dictionary = SaveGame.get_active_mission()
	var mission_id: String = str(active.get("mission_id", ""))
	if mission_id.is_empty():
		mission_id = "(none)"
	lbl_mission.text = "Mission: %s" % mission_id
	lbl_selected.text = "Selected: (none)"

	_spawn_tokens()

func _sync_board_viewport_size() -> void:
	if board_container == null or board_viewport == null:
		return
	var container_size: Vector2 = board_container.size
	if container_size.x <= 0.0 or container_size.y <= 0.0:
		return
	board_viewport.size = Vector2i(int(container_size.x), int(container_size.y))
	var camera: Camera2D = world.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.position = container_size * 0.5

func _spawn_tokens() -> void:
	if world == null:
		push_error("TacticalCombat: World node missing.")
		return

	for child in world.get_children():
		if child is Camera2D:
			continue
		child.queue_free()

	_selected_token = null
	lbl_selected.text = "Selected: (none)"

	var fighters: Array = SaveGame.get_fighters()
	for i in range(6):
		var display_name: String = "Ally %d" % (i + 1)
		if i < fighters.size():
			var fighter_raw: Variant = fighters[i]
			if typeof(fighter_raw) == TYPE_DICTIONARY:
				var fighter: Dictionary = fighter_raw as Dictionary
				display_name = str(fighter.get("name", display_name))
		_spawn_token("friendly", display_name, i, Vector2(120 + i * 100, 120))

	for i in range(6):
		_spawn_token("enemy", "Enemy %d" % (i + 1), i, Vector2(120 + i * 100, 240))

func _spawn_token(side: String, display_name: String, index: int, spawn_pos: Vector2) -> void:
	var token: Area2D = Area2D.new()
	token.position = spawn_pos
	token.input_pickable = true
	token.set_meta("side", side)
	token.set_meta("display_name", display_name)
	token.set_meta("index", index)

	var base_color: Color = Color(0.3, 0.7, 1.0) if side == "friendly" else Color(1.0, 0.4, 0.4)
	token.set_meta("base_color", base_color)

	var body: Polygon2D = Polygon2D.new()
	body.name = "Body"
	body.color = base_color
	body.polygon = PackedVector2Array([
		Vector2(0, -18),
		Vector2(18, 0),
		Vector2(0, 18),
		Vector2(-18, 0)
	])
	token.add_child(body)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 20.0
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

	_set_token_highlight(_selected_token, false)
	_selected_token = token
	_set_token_highlight(_selected_token, true)

	var side: String = str(token.get_meta("side", "unknown"))
	var display_name: String = str(token.get_meta("display_name", "(unnamed)"))
	lbl_selected.text = "Selected: %s - %s" % [side, display_name]

func _set_token_highlight(token: Area2D, highlighted: bool) -> void:
	if token == null:
		return
	var body: Polygon2D = token.get_node_or_null("Body") as Polygon2D
	if body == null:
		return

	if highlighted:
		body.color = Color(1.0, 0.95, 0.35)
		return

	var base_color_raw: Variant = token.get_meta("base_color", body.color)
	if typeof(base_color_raw) == TYPE_COLOR:
		body.color = base_color_raw as Color

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
