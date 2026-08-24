class_name Dungeon
extends Control

@export var start_node_data: DungeonNodeData
@export var reward_node_data: DungeonNodeData
@export var event_node_data: DungeonNodeData
@export var shop_node_data: DungeonNodeData
@export var elite_node_data: DungeonNodeData
@export var boss_node_data: DungeonNodeData

@onready var start_button: Button = $MarginContainer/Content/Map/Row1/StartBattleButton
@onready var reward_button: Button = $MarginContainer/Content/Map/Row1/RewardButton
@onready var event_button: Button = $MarginContainer/Content/Map/Row1/EventButton
@onready var shop_button: Button = $MarginContainer/Content/Map/Row2/ShopButton
@onready var elite_button: Button = $MarginContainer/Content/Map/Row2/EliteButton
@onready var boss_button: Button = $MarginContainer/Content/Map/Row2/BossButton
@onready var new_run_button: Button = $MarginContainer/Content/NewRunButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel
@onready var run_status_label: Label = $MarginContainer/Content/RunStatusLabel

var route_map: VBoxContainer
var route_stage_one_buttons: Array[Button] = []
var route_stage_two_buttons: Array[Button] = []
var route_start_button: Button
var route_elite_button: Button
var route_boss_button: Button

func _ready() -> void:
	if not RunState.active_run:
		RunState.start_new_run()
	_initialize_run_dice()
	BossRewardSystem.sync_owned_special_dice(RunState)
	_add_codex_button()
	_add_run_status_overlay()
	_add_dungeon_guide()
	_setup_node_buttons()
	_build_branching_route_map()
	_update_progress()

func _add_run_status_overlay() -> void:
	if get_node_or_null("RunStatusOverlay") == null:
		RunStatusOverlay.attach(self)

func _add_codex_button() -> void:
	var content: VBoxContainer = $MarginContainer/Content
	if content.get_node_or_null("GodCodexButton") != null:
		return
	var codex_button: Button = Button.new()
	codex_button.name = "GodCodexButton"
	codex_button.text = "📖 신의 축복 도감"
	codex_button.custom_minimum_size = Vector2(0, 34)
	codex_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/dungeon/god_codex.tscn"))
	content.add_child(codex_button)

func _add_dungeon_guide() -> void:
	var content: VBoxContainer = $MarginContainer/Content
	var guide: Label = content.get_node_or_null("DungeonGuide") as Label
	if guide == null:
		guide = Label.new()
		guide.name = "DungeonGuide"
		guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		guide.custom_minimum_size = Vector2(0, 40)
		content.add_child(guide)
	guide.text = "🗺️ 이번 런의 경로를 선택하세요\n⚔️ 일반 전투 → 🎲 이벤트 분기 → ♛ 엘리트 → 🎲 이벤트 분기 → ☠️ 보스"

func _initialize_run_dice() -> void:
	if not RunState.run_dice_faces.is_empty():
		return
	var basic_dice: DiceData = load("res://resources/dice/basic_dice.tres") as DiceData
	if basic_dice != null:
		RunState.initialize_run_dice(basic_dice.face_values)
	else:
		RunState.initialize_run_dice(PackedInt32Array([1, 2, 3, 4, 5, 6]))

func _setup_node_buttons() -> void:
	start_button.text = "⚔ 일반 전투"
	start_button.tooltip_text = start_node_data.description
	reward_button.text = "💰 전투 골드 보상"
	reward_button.tooltip_text = "전투 또는 엘리트 처치 후 무작위 골드를 자동으로 획득합니다."
	event_button.text = "🎲 랜덤 이벤트 ①"
	event_button.tooltip_text = event_node_data.description
	shop_button.text = "🎲 랜덤 이벤트 ②"
	shop_button.tooltip_text = "엘리트 처치 후 두 번째 랜덤 이벤트를 진행합니다."
	elite_button.text = "♛ 엘리트"
	elite_button.tooltip_text = elite_node_data.description
	boss_button.text = "☠ 보스"
	boss_button.tooltip_text = boss_node_data.description
	reward_button.hide()
	start_button.hide()
	event_button.hide()
	shop_button.hide()
	elite_button.hide()
	boss_button.hide()
	for child: Node in $MarginContainer/Content/Map.get_children():
		if child is Control:
			(child as Control).hide()
	new_run_button.hide()

func _make_route_button(text: String, subtitle: String) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(220, 78)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "%s\n%s" % [text, subtitle]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 16)
	return button

func _make_route_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return row

func _make_route_arrow(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.custom_minimum_size = Vector2(0, 28)
	return label

func _build_branching_route_map() -> void:
	var map: VBoxContainer = $MarginContainer/Content/Map
	if route_map != null and is_instance_valid(route_map):
		route_map.queue_free()
	route_stage_one_buttons.clear()
	route_stage_two_buttons.clear()

	route_map = VBoxContainer.new()
	route_map.name = "BranchingRouteMap"
	route_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_map.add_theme_constant_override("separation", 8)
	map.add_child(route_map)

	var start_row: HBoxContainer = _make_route_row()
	route_start_button = _make_route_button("⚔ 일반 전투", "시작 전투")
	route_start_button.custom_minimum_size = Vector2(250, 78)
	route_start_button.pressed.connect(_on_start_battle_button_pressed)
	start_row.add_child(route_start_button)
	route_map.add_child(start_row)

	route_map.add_child(_make_route_arrow("↙                         ↘"))

	var first_row: HBoxContainer = _make_route_row()
	var route_one: Array[String] = RunState.route_event_stage_one
	for index: int in 2:
		var branch_id: String = route_one[index] if index < route_one.size() else "event_%d" % index
		var button: Button = _make_route_button("🎲 랜덤 이벤트 %s" % ["①", "②"][index], "분기 경로 %s" % branch_id.to_upper())
		button.pressed.connect(func() -> void: _on_route_event_pressed(1, index))
		route_stage_one_buttons.append(button)
		first_row.add_child(button)
	route_map.add_child(first_row)

	route_map.add_child(_make_route_arrow("↘                         ↙"))

	var elite_row: HBoxContainer = _make_route_row()
	route_elite_button = _make_route_button("♛ 엘리트 전투", "두 경로가 여기서 합류")
	route_elite_button.custom_minimum_size = Vector2(250, 78)
	route_elite_button.pressed.connect(_on_elite_button_pressed)
	elite_row.add_child(route_elite_button)
	route_map.add_child(elite_row)

	route_map.add_child(_make_route_arrow("↙                         ↘"))

	var second_row: HBoxContainer = _make_route_row()
	var route_two: Array[String] = RunState.route_event_stage_two
	for index: int in 2:
		var branch_id: String = route_two[index] if index < route_two.size() else "event_%d" % (index + 2)
		var button: Button = _make_route_button("🎲 랜덤 이벤트 %s" % ["③", "④"][index], "분기 경로 %s" % branch_id.to_upper())
		button.pressed.connect(func() -> void: _on_route_event_pressed(2, index))
		route_stage_two_buttons.append(button)
		second_row.add_child(button)
	route_map.add_child(second_row)

	route_map.add_child(_make_route_arrow("↘                         ↙"))

	var boss_row: HBoxContainer = _make_route_row()
	route_boss_button = _make_route_button("☠ 보스 전투", "두 경로가 최종 합류")
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
	run_status_label.text = "%s\n%s" % [_format_run_status(), ProgressionState.get_unlock_summary()]
	if RunState.boss_cleared:
		_disable_all_nodes()
		new_run_button.show()
		status_label.text = "👑 보스 처치 완료! 특수 보상과 신성 심볼을 획득했습니다."
	elif RunState.event_stage == 2 and RunState.event_resolved:
		_disable_all_nodes()
		route_boss_button.disabled = false
		status_label.text = "두 번째 랜덤 이벤트가 끝났습니다. 두 갈래가 보스로 합류합니다."
	elif RunState.elite_cleared:
		_disable_all_nodes()
		for button: Button in route_stage_two_buttons:
			button.disabled = false
		status_label.text = "♛ 엘리트를 돌파했습니다. 두 번째 분기에서 경로를 선택하세요."
	elif RunState.event_stage == 1 and RunState.event_resolved:
		_disable_all_nodes()
		route_elite_button.disabled = false
		status_label.text = "첫 번째 랜덤 이벤트가 끝났습니다. 두 갈래가 엘리트에서 합류합니다."
	elif RunState.reward_claimed:
		_disable_all_nodes()
		for button: Button in route_stage_one_buttons:
			button.disabled = false
		status_label.text = "💰 전투 골드를 획득했습니다. 두 갈래 중 하나의 랜덤 이벤트를 선택하세요."
	else:
		_disable_all_nodes()
		route_start_button.disabled = false
		status_label.text = "일반 전투부터 시작하세요. 전투 후 두 갈래 이벤트 중 하나를 선택할 수 있습니다."

func _disable_all_nodes() -> void:
	route_start_button.disabled = true
	route_elite_button.disabled = true
	route_boss_button.disabled = true
	for button: Button in route_stage_one_buttons:
		button.disabled = true
	for button: Button in route_stage_two_buttons:
		button.disabled = true

func _on_start_battle_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/run_battle.tscn")

func _on_reward_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeon/reward.tscn")

func _on_event_button_pressed() -> void:
	_on_route_event_pressed(1, 0)

func _on_shop_button_pressed() -> void:
	_on_route_event_pressed(2, 0)

func _on_route_event_pressed(stage: int, branch_index: int) -> void:
	if stage == 1 and (RunState.event_stage != 0 or not RunState.reward_claimed):
		return
	if stage == 2 and (not RunState.elite_cleared or RunState.event_stage != 0):
		return
	if not RunState.select_route_event(stage, branch_index):
		return
	RunState.begin_event(stage)
	get_tree().change_scene_to_file("res://scenes/dungeon/event.tscn")

func _on_elite_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/elite_run_battle.tscn")

func _on_boss_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/boss_run_battle.tscn")

func _on_new_run_button_pressed() -> void:
	RunState.start_new_run()
	_initialize_run_dice()
	BossRewardSystem.sync_owned_special_dice(RunState)
	_build_branching_route_map()
	status_label.text = "새 런의 랜덤 경로를 생성했습니다."
	_update_progress()
