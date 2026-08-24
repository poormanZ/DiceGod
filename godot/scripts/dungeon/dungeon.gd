class_name Dungeon
extends Control

# 현재 런의 던전 구조:
# 일반 전투
#   -> 대장간 / 상점
#   -> 엘리트 전투
#   -> 캠프 / 도박장
#   -> 보스 전투
# 각 분기에서 하나를 선택하며, 선택한 이벤트는 해당 런에서만 진행된다.

@onready var map: Control = $MarginContainer/Content/Map
@onready var run_status_label: Label = $MarginContainer/Content/RunStatusLabel
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

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

	# 일반 전투
	var start_row: HBoxContainer = _make_route_row()
	route_start_button = _make_route_button("⚔ 일반 전투", "시작 전투")
	route_start_button.custom_minimum_size = Vector2(250, 78)
	route_start_button.pressed.connect(_on_start_battle_button_pressed)
	start_row.add_child(route_start_button)
	route_map.add_child(start_row)

	# 1차 분기: 대장간 / 상점
	route_map.add_child(_make_route_arrow("↙                         ↘"))
	var first_row: HBoxContainer = _make_route_row()
	var forge_button: Button = _make_route_button("🔨 대장간", "주사위 심볼 수정")
	var shop_button: Button = _make_route_button("🏪 상점", "장비 / 아이템 구매")
	forge_button.custom_minimum_size = Vector2(220, 78)
	shop_button.custom_minimum_size = Vector2(220, 78)
	forge_button.pressed.connect(_on_fixed_event_pressed.bind(1, "forge"))
	shop_button.pressed.connect(_on_fixed_event_pressed.bind(1, "shop"))
	route_stage_one_buttons.append(forge_button)
	route_stage_one_buttons.append(shop_button)
	first_row.add_child(forge_button)
	first_row.add_child(shop_button)
	route_map.add_child(first_row)

	# 엘리트에서 합류
	route_map.add_child(_make_route_arrow("↘                         ↙"))
	var elite_row: HBoxContainer = _make_route_row()
	route_elite_button = _make_route_button("♛ 엘리트 전투", "두 경로가 여기서 합류")
	route_elite_button.custom_minimum_size = Vector2(250, 78)
	route_elite_button.pressed.connect(_on_elite_button_pressed)
	elite_row.add_child(route_elite_button)
	route_map.add_child(elite_row)

	# 2차 분기: 캠프 / 도박장
	route_map.add_child(_make_route_arrow("↙                         ↘"))
	var second_row: HBoxContainer = _make_route_row()
	var camp_button: Button = _make_route_button("⛺ 캠프", "HP 회복")
	var gamble_button: Button = _make_route_button("🎰 도박장", "골드 도박")
	camp_button.custom_minimum_size = Vector2(220, 78)
	gamble_button.custom_minimum_size = Vector2(220, 78)
	camp_button.pressed.connect(_on_fixed_event_pressed.bind(2, "camp"))
	gamble_button.pressed.connect(_on_fixed_event_pressed.bind(2, "gamble"))
	route_stage_two_buttons.append(camp_button)
	route_stage_two_buttons.append(gamble_button)
	second_row.add_child(camp_button)
	second_row.add_child(gamble_button)
	route_map.add_child(second_row)

	# 보스에서 최종 합류
	route_map.add_child(_make_route_arrow("↘                         ↙"))
	var boss_row: HBoxContainer = _make_route_row()
	route_boss_button = _make_route_button("☠ 보스 전투", "최종 전투")
	route_boss_button.custom_minimum_size = Vector2(250, 78)
	route_boss_button.pressed.connect(_on_boss_button_pressed)
	boss_row.add_child(route_boss_button)
	route_map.add_child(boss_row)

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
		status_label.text = "👑 보스 처치 완료! 현재 런이 종료되었습니다."
	elif RunState.event_stage == 2 and RunState.event_resolved:
		_disable_all_nodes()
		route_boss_button.disabled = false
		status_label.text = "두 번째 이벤트가 끝났습니다. 보스 전투로 진행하세요."
	elif RunState.elite_cleared:
		_disable_all_nodes()
		for button: Button in route_stage_two_buttons:
			button.disabled = false
		status_label.text = "♛ 엘리트를 돌파했습니다. 캠프 또는 도박장을 선택하세요."
	elif RunState.event_stage == 1 and RunState.event_resolved:
		_disable_all_nodes()
		route_elite_button.disabled = false
		status_label.text = "첫 번째 이벤트가 끝났습니다. 엘리트 전투로 진행하세요."
	elif RunState.reward_claimed:
		_disable_all_nodes()
		for button: Button in route_stage_one_buttons:
			button.disabled = false
		status_label.text = "💰 전투 보상을 획득했습니다. 대장간 또는 상점을 선택하세요."
	else:
		_disable_all_nodes()
		route_start_button.disabled = false
		status_label.text = "일반 전투부터 시작하세요."

func _disable_all_nodes() -> void:
	route_start_button.disabled = true
	route_elite_button.disabled = true
	route_boss_button.disabled = true
	for button: Button in route_stage_one_buttons:
		button.disabled = true
	for button: Button in route_stage_two_buttons:
		button.disabled = true

func _on_fixed_event_pressed(stage: int, event_type: String) -> void:
	if stage != 1 and stage != 2:
		return
	RunState.begin_event(stage)
	RunState.choose_event(event_type)
	var scene_path: String = "res://scenes/dungeon/%s.tscn" % _event_scene_name(event_type)
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		status_label.text = "이벤트 씬을 찾을 수 없습니다: %s" % event_type
		_update_progress()

func _event_scene_name(event_type: String) -> String:
	match event_type:
		"forge": return "forge"
		"shop": return "shop"
		"camp": return "event"
		"gamble": return "gambling"
	return "event"

func _on_start_battle_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/run_battle.tscn")

func _on_elite_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/elite_run_battle.tscn")

func _on_boss_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/boss_run_battle.tscn")

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
