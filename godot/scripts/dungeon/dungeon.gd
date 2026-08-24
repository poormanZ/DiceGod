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
	_setup_node_buttons()
	_update_progress()

func _setup_node_buttons() -> void:
	start_button.text = "⚔ 일반 전투\n%s" % start_node_data.description
	reward_button.text = "💰 골드 보상\n%s" % reward_node_data.description
	event_button.text = "🎲 랜덤 이벤트 (선택)\n%s" % event_node_data.description
	shop_button.text = "🏪 상점 이벤트\n이벤트에서 선택하면 입장합니다."
	elite_button.text = "♛ 엘리트\n%s" % elite_node_data.description
	boss_button.text = "☠ 보스\n%s" % boss_node_data.description
	new_run_button.hide()

func _update_progress() -> void:
	run_status_label.text = "%s\n%s" % [RunState.get_run_summary(), ProgressionState.get_unlock_summary()]
	if RunState.boss_cleared:
		_disable_all_nodes()
		new_run_button.show()
		status_label.text = "보스를 쓰러뜨렸습니다! 런 클리어! 영구 해금이 저장되었습니다."
	elif RunState.elite_cleared:
		_disable_all_nodes()
		# 엘리트 후에는 두 번째 랜덤 이벤트를 선택할 수 있다.
		event_button.disabled = false
		status_label.text = "엘리트를 돌파했습니다. 두 번째 랜덤 이벤트를 선택하거나 스킵하세요."
	elif RunState.event_stage == 2 and RunState.event_resolved:
		_disable_all_nodes()
		boss_button.disabled = false
		status_label.text = "두 번째 이벤트가 끝났습니다. 마지막 보스에 도전하세요."
	elif RunState.event_stage == 1 and RunState.event_resolved:
		_disable_all_nodes()
		elite_button.disabled = false
		status_label.text = "첫 번째 이벤트가 끝났습니다. 다음은 엘리트 몬스터입니다."
	elif RunState.reward_claimed:
		_disable_all_nodes()
		event_button.disabled = false
		status_label.text = "💰 골드를 획득했습니다. 랜덤 이벤트를 선택하거나 스킵하세요."
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
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func _on_reward_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeon/reward.tscn")

func _on_event_button_pressed() -> void:
	var next_stage: int = 1
	if RunState.elite_cleared:
		next_stage = 2
	RunState.begin_event(next_stage)
	get_tree().change_scene_to_file("res://scenes/dungeon/event.tscn")

func _on_shop_button_pressed() -> void:
	# 상점은 이제 독립적인 필수 노드가 아니라 랜덤 이벤트에서 선택되는 이벤트다.
	RunState.begin_event(1 if not RunState.elite_cleared else 2)
	get_tree().change_scene_to_file("res://scenes/dungeon/shop.tscn")

func _on_elite_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/elite_battle.tscn")

func _on_boss_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/boss_battle.tscn")

func _on_new_run_button_pressed() -> void:
	RunState.start_new_run()
	status_label.text = "새 런을 시작합니다."
	_update_progress()
