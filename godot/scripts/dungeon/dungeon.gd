class_name Dungeon
extends Control

@export var start_node_data: DungeonNodeData
@export var reward_node_data: DungeonNodeData
@export var event_node_data: DungeonNodeData

@onready var start_button: Button = $MarginContainer/Content/Map/StartBattleButton
@onready var reward_button: Button = $MarginContainer/Content/Map/RewardButton
@onready var event_button: Button = $MarginContainer/Content/Map/EventButton
@onready var new_run_button: Button = $MarginContainer/Content/NewRunButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

func _ready() -> void:
	_setup_node_buttons()
	_update_progress()

func _setup_node_buttons() -> void:
	start_button.text = "⚔ 일반 전투\n%s" % start_node_data.description
	reward_button.text = "★ 보상\n%s" % reward_node_data.description
	event_button.text = "? 이벤트\n%s" % event_node_data.description
	new_run_button.hide()
	status_label.text = "현재 위치에서 진행할 노드를 선택하세요."

func _update_progress() -> void:
	var battle_cleared: bool = get_tree().has_meta("dungeon_battle_cleared") and get_tree().get_meta("dungeon_battle_cleared") == true
	var reward_claimed: bool = get_tree().has_meta("dungeon_reward_claimed") and get_tree().get_meta("dungeon_reward_claimed") == true
	var event_resolved: bool = get_tree().has_meta("dungeon_event_resolved") and get_tree().get_meta("dungeon_event_resolved") == true

	if event_resolved:
		start_button.disabled = true
		reward_button.disabled = true
		event_button.disabled = true
		new_run_button.show()
		status_label.text = "던전 완료! 이벤트까지 해결했습니다."
	elif reward_claimed:
		start_button.disabled = true
		reward_button.disabled = true
		event_button.disabled = false
		new_run_button.hide()
		status_label.text = "보상을 획득했습니다. 다음은 이벤트 노드입니다."
	elif battle_cleared:
		start_button.disabled = true
		reward_button.disabled = false
		event_button.disabled = true
		new_run_button.hide()
		status_label.text = "전투를 완료했습니다. 보상 노드를 선택하세요."
	else:
		start_button.disabled = false
		reward_button.disabled = true
		event_button.disabled = true
		new_run_button.hide()
		status_label.text = "일반 전투부터 시작하세요."

func _on_start_battle_button_pressed() -> void:
	status_label.text = "전투로 이동합니다."
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func _on_reward_button_pressed() -> void:
	status_label.text = "보상으로 이동합니다."
	get_tree().change_scene_to_file("res://scenes/dungeon/reward.tscn")

func _on_event_button_pressed() -> void:
	status_label.text = "이벤트로 이동합니다."
	get_tree().change_scene_to_file("res://scenes/dungeon/event.tscn")

func _on_new_run_button_pressed() -> void:
	get_tree().set_meta("dungeon_battle_cleared", false)
	get_tree().set_meta("dungeon_reward_claimed", false)
	get_tree().set_meta("dungeon_reward_id", "")
	get_tree().set_meta("dungeon_event_resolved", false)
	get_tree().set_meta("dungeon_event_id", "")
	status_label.text = "새 던전을 시작합니다. 이벤트 보너스가 있다면 다음 전투에 적용됩니다."
	_update_progress()
