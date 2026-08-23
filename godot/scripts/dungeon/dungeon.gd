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
	reward_button.text = "★ 보상\n%s" % reward_node_data.description
	event_button.text = "? 이벤트\n%s" % event_node_data.description
	shop_button.text = "◆ 상점\n%s" % shop_node_data.description
	elite_button.text = "♛ 엘리트\n%s" % elite_node_data.description
	boss_button.text = "☠ 보스\n%s" % boss_node_data.description
	new_run_button.hide()

func _update_progress() -> void:
	run_status_label.text = RunState.get_run_summary()
	if RunState.boss_cleared:
		_disable_all_nodes()
		new_run_button.show()
		status_label.text = "보스를 쓰러뜨렸습니다! 런 클리어!"
	elif RunState.elite_cleared:
		_disable_all_nodes()
		boss_button.disabled = false
		status_label.text = "엘리트를 돌파했습니다. 마지막 보스에 도전하세요."
	elif RunState.shop_resolved:
		_disable_all_nodes()
		elite_button.disabled = false
		status_label.text = "상점을 통과했습니다. 다음은 엘리트 노드입니다."
	elif RunState.event_resolved:
		_disable_all_nodes()
		shop_button.disabled = false
		status_label.text = "이벤트를 해결했습니다. 다음은 상점 노드입니다."
	elif RunState.reward_claimed:
		_disable_all_nodes()
		event_button.disabled = false
		status_label.text = "보상을 획득했습니다. 다음은 이벤트 노드입니다."
	elif RunState.battle_cleared:
		_disable_all_nodes()
		reward_button.disabled = false
		status_label.text = "전투를 완료했습니다. 보상 노드를 선택하세요."
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
	get_tree().change_scene_to_file("res://scenes/dungeon/event.tscn")

func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeon/shop.tscn")

func _on_elite_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/elite_battle.tscn")

func _on_boss_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/boss_battle.tscn")

func _on_new_run_button_pressed() -> void:
	RunState.start_new_run()
	status_label.text = "새 런을 시작합니다."
	_update_progress()
