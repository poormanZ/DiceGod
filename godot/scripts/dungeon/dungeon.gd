class_name Dungeon
extends Control

@export var start_node_data: DungeonNodeData
@export var reward_node_data: DungeonNodeData

@onready var start_button: Button = $MarginContainer/Content/StartBattleButton
@onready var reward_button: Button = $MarginContainer/Content/RewardButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

func _ready() -> void:
	_setup_node_buttons()
	_update_progress()

func _setup_node_buttons() -> void:
	start_button.text = "⚔ 일반 전투\n%s" % start_node_data.description
	reward_button.text = "★ 보상\n%s" % reward_node_data.description
	reward_button.disabled = true
	status_label.text = "현재 위치에서 진행할 노드를 선택하세요."

func _update_progress() -> void:
	var battle_cleared: bool = get_tree().has_meta("dungeon_battle_cleared") and get_tree().get_meta("dungeon_battle_cleared") == true
	if battle_cleared:
		start_button.disabled = true
		reward_button.disabled = false
		status_label.text = "전투를 완료했습니다. 보상 노드를 선택하세요."
	else:
		start_button.disabled = false
		reward_button.disabled = true

func _on_start_battle_button_pressed() -> void:
	status_label.text = "전투로 이동합니다."
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func _on_reward_button_pressed() -> void:
	status_label.text = "보상 시스템은 다음 단계에서 구현합니다."
