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

func _ready() -> void:
	if not RunState.active_run:
		RunState.start_new_run()
	_initialize_run_dice()
	BossRewardSystem.sync_owned_special_dice(RunState)
	_add_codex_button()
	_setup_node_buttons()
	_update_progress()

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

func _initialize_run_dice() -> void:
	if not RunState.run_dice_faces.is_empty():
		return
	var basic_dice: DiceData = load("res://resources/dice/basic_dice.tres") as DiceData
	if basic_dice != null:
		RunState.initialize_run_dice(basic_dice.face_values)
	else:
		RunState.initialize_run_dice(PackedInt32Array([1, 2, 3, 4, 5, 6]))

func _setup_node_buttons() -> void:
	# 버튼에는 짧은 제목만 표시하고 상세 설명은 툴팁으로 분리해
	# 1280x720에서도 텍스트가 버튼 폭을 강제로 늘리지 않도록 한다.
	start_button.text = "⚔ 일반 전투"
	start_button.tooltip_text = start_node_data.description
	reward_button.text = "💰 골드 보상"
	reward_button.tooltip_text = reward_node_data.description
	event_button.text = "🎲 랜덤 이벤트 ①"
	event_button.tooltip_text = event_node_data.description
	shop_button.text = "🎲 랜덤 이벤트 ②"
	shop_button.tooltip_text = "엘리트 처치 후 두 번째 랜덤 이벤트를 선택합니다."
	elite_button.text = "♛ 엘리트"
	elite_button.tooltip_text = elite_node_data.description
	boss_button.text = "☠ 보스"
	boss_button.tooltip_text = boss_node_data.description
	new_run_button.hide()

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
		boss_button.disabled = false
		status_label.text = "두 번째 이벤트가 끝났습니다. 마지막 보스에 도전하세요."
	elif RunState.elite_cleared:
		_disable_all_nodes()
		shop_button.disabled = false
		status_label.text = "♛ 엘리트를 돌파했습니다. 두 번째 랜덤 이벤트를 선택하세요."
	elif RunState.event_stage == 1 and RunState.event_resolved:
		_disable_all_nodes()
		elite_button.disabled = false
		status_label.text = "첫 번째 이벤트가 끝났습니다. 다음은 엘리트 몬스터입니다."
	elif RunState.reward_claimed:
		_disable_all_nodes()
		event_button.disabled = false
		status_label.text = "💰 골드를 획득했습니다. 랜덤 이벤트를 선택하세요."
	else:
		_disable_all_nodes()
		start_button.disabled = false
		status_label.text = "일반 전투부터 시작하세요."

func _disable_all_nodes() -> void:
	start_button.disabled = true
	reward_button.disabled = true
	event_button.disabled = true
	shop_button.disabled = true
	elite_button.disabled = true
	boss_button.disabled = true

func _on_start_battle_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/run_battle.tscn")

func _on_reward_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeon/reward.tscn")

func _on_event_button_pressed() -> void:
	RunState.begin_event(1)
	get_tree().change_scene_to_file("res://scenes/dungeon/event.tscn")

func _on_shop_button_pressed() -> void:
	RunState.begin_event(2)
	get_tree().change_scene_to_file("res://scenes/dungeon/event.tscn")

func _on_elite_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/elite_run_battle.tscn")

func _on_boss_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/boss_run_battle.tscn")

func _on_new_run_button_pressed() -> void:
	RunState.start_new_run()
	_initialize_run_dice()
	BossRewardSystem.sync_owned_special_dice(RunState)
	status_label.text = "새 런을 시작합니다."
	_update_progress()
