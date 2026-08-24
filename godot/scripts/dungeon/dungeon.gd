class_name Dungeon
extends Control

# NOTE: Route arrays are intentionally read through get_dungeon_route() so the
# UI never relies on the dynamic type of the Autoload properties. This avoids
# Godot's "String -> Array[String]" inference error after route refactors.

@onready var map: Control = $MarginContainer/Content/Map
@onready var run_status_label: Label = $MarginContainer/Content/RunStatusLabel
@onready var status_label: Label = $MarginContainer/Content/StatusLabel
@onready var new_run_button: Button = $MarginContainer/Content/NewRunButton

var route_map: VBoxContainer
var route_start_button: Button
var route_elite_button: Button
var route_boss_button: Button
var route_stage_one_buttons: Array[Button] = []
var route_stage_two_buttons: Array[Button] = []

func _ready() -> void:
	_build_route_map()
	_update_progress()

func _build_route_map() -> void:
	for child: Node in map.get_children():
		child.queue_free()

	route_stage_one_buttons.clear()
	route_stage_two_buttons.clear()

	route_map = VBoxContainer.new()
	route_map.name = "BranchingRouteMap"
	route_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_map.add_theme_constant_override("separation", 8)
	map.add_child(route_map)

	var route_data: Dictionary = RunState.get_dungeon_route()
	var route_one: Array[String] = _string_array(route_data.get("stage_one", []))
	var route_two: Array[String] = _string_array(route_data.get("stage_two", []))

	var start_row: HBoxContainer = _make_route_row()
	route_start_button = _make_route_button("⚔ 일반 전투", "시작 전투")
	route_start_button.custom_minimum_size = Vector2(250, 78)
	route_start_button.pressed.connect(_on_start_battle_button_pressed)
	start_row.add_child(route_start_button)
	route_map.add_child(start_row)

	# 이벤트는 플레이어가 고르는 랜덤 선택지가 아니라 런 시작 시 확정된 노드다.
	route_map.add_child(_make_route_arrow("↓"))
	var first_event_row: HBoxContainer = _make_route_row()
	var first_event_id: String = route_one[0] if not route_one.is_empty() else "forge"
	var first_event_button: Button = _make_route_button(_event_title(first_event_id), _event_description(first_event_id))
	first_event_button.custom_minimum_size = Vector2(250, 78)
	first_event_button.pressed.connect(func() -> void: _on_fixed_event_pressed(1))
	route_stage_one_buttons.append(first_event_button)
	first_event_row.add_child(first_event_button)
	route_map.add_child(first_event_row)

	route_map.add_child(_make_route_arrow("↓"))
	var elite_row: HBoxContainer = _make_route_row()
	route_elite_button = _make_route_button("♛ 엘리트 전투", "첫 번째 이벤트 후 진행")
	route_elite_button.custom_minimum_size = Vector2(250, 78)
	route_elite_button.pressed.connect(_on_elite_button_pressed)
	elite_row.add_child(route_elite_button)
	route_map.add_child(elite_row)

	route_map.add_child(_make_route_arrow("↓"))
	var second_event_row: HBoxContainer = _make_route_row()
	var second_event_id: String = route_two[0] if not route_two.is_empty() else "camp"
	var second_event_button: Button = _make_route_button(_event_title(second_event_id), _event_description(second_event_id))
	second_event_button.custom_minimum_size = Vector2(250, 78)
	second_event_button.pressed.connect(func() -> void: _on_fixed_event_pressed(2))
	route_stage_two_buttons.append(second_event_button)
	second_event_row.add_child(second_event_button)
	route_map.add_child(second_event_row)

	route_map.add_child(_make_route_arrow("↓"))
	var boss_row: HBoxContainer = _make_route_row()
	route_boss_button = _make_route_button("☠ 보스 전투", "최종 전투")
	route_boss_button.custom_minimum_size = Vector2(250, 78)
	route_boss_button.pressed.connect(_on_boss_button_pressed)
	boss_row.add_child(route_boss_button)
	route_map.add_child(boss_row)

func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value:
			result.append(str(item))
	elif value is String and not str(value).is_empty():
		result.append(str(value))
	return result

func _event_title(event_id: String) -> String:
	match event_id:
		"camp": return "⛺ 캠프"
		"shop": return "🏪 상점"
		"forge": return "🔨 대장간"
		"gamble": return "🎰 도박장"
	return "🎲 이벤트"

func _event_description(event_id: String) -> String:
	match event_id:
		"camp": return "HP 회복"
		"shop": return "장비 / 주사위 구매"
		"forge": return "주사위 심볼 수정"
		"gamble": return "골드 도박"
	return "이번 런에 확정된 이벤트"

func _format_run_status() -> String:
	var summary: Dictionary = RunState.get_run_summary()
	var hp_text: String = "%d/%d" % [int(summary.get("current_hp", 0)), int(summary.get("max_hp", 0))]
	var dice_count: int = int(summary.get("dice_count", 0))
	var divine_count: int = int(summary.get("divine_symbol_count", 0))
	var gold: int = int(summary.get("gold", 0))
	var run_number: int = int(summary.get("run_number", 0))
	return "런 %d  |  ❤️ %s  |  💰 %dG  |  🎲 주사위 %d  |  ✨ 신성 %d" % [run_number, hp_text, gold, dice_count, divine_count]

func _update_progress() -> void:
	run_status_label.text = _format_run_status()
	if RunState.boss_cleared:
		_disable_all_nodes()
		new_run_button.show()
		status_label.text = "👑 보스 처치 완료! 새 런에서 이벤트가 다시 랜덤 생성됩니다."
	elif RunState.event_stage == 2 and RunState.event_resolved:
		_disable_all_nodes()
		route_boss_button.disabled = false
		status_label.text = "두 번째 이벤트가 끝났습니다. 보스로 진행합니다."
	elif RunState.elite_cleared:
		_disable_all_nodes()
		for button: Button in route_stage_two_buttons:
			button.disabled = false
		status_label.text = "♛ 엘리트를 돌파했습니다. 이번 런에 확정된 두 번째 이벤트로 진행하세요."
	elif RunState.event_stage == 1 and RunState.event_resolved:
		_disable_all_nodes()
		route_elite_button.disabled = false
		status_label.text = "첫 번째 이벤트가 끝났습니다. 엘리트로 진행합니다."
	elif RunState.reward_claimed:
		_disable_all_nodes()
		for button: Button in route_stage_one_buttons:
			button.disabled = false
		status_label.text = "💰 전투 보상을 획득했습니다. 이번 런의 확정 이벤트로 진행하세요."
	else:
		_disable_all_nodes()
		route_start_button.disabled = false
		status_label.text = "일반 전투부터 시작하세요. 이벤트는 새 런에서 랜덤으로 미리 결정됩니다."

func _disable_all_nodes() -> void:
	route_start_button.disabled = true
	route_elite_button.disabled = true
	route_boss_button.disabled = true
	for button: Button in route_stage_one_buttons:
		button.disabled = true
	for button: Button in route_stage_two_buttons:
		button.disabled = true

func _on_fixed_event_pressed(stage: int) -> void:
	RunState.begin_event(stage)
	var route_data: Dictionary = RunState.get_dungeon_route()
	var ids: Array[String] = _string_array(route_data.get("stage_one", []) if stage == 1 else route_data.get("stage_two", []))
	if ids.is_empty():
		return
	var event_id: String = ids[0]
	RunState.choose_event(event_id)
	get_tree().change_scene_to_file("res://scenes/dungeon/event.tscn")

func _on_start_battle_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeon/battle.tscn")

func _on_elite_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeon/elite_battle.tscn")

func _on_boss_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeon/boss_battle.tscn")

func _make_route_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return row

func _make_route_arrow(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _make_route_button(title: String, description: String) -> Button:
	var button: Button = Button.new()
	button.text = "%s\n%s" % [title, description]
	button.custom_minimum_size = Vector2(250, 72)
	return button

func _on_route_event_pressed(_stage: int, _branch_index: int) -> void:
	# 이전 분기 UI와의 호환용. 이벤트 종류는 이미 런 시작 시 확정되어 있으므로
	# 여기서 branch를 변경하지 않는다.
	return

func _on_new_run_button_pressed() -> void:
	RunState.start_new_run()
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
