class_name Dungeon
extends Control

@export var start_node_data: DungeonNodeData
@export var reward_node_data: DungeonNodeData

@onready var start_button: Button = $MarginContainer/Content/StartBattleButton
@onready var reward_button: Button = $MarginContainer/Content/RewardButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

func _ready() -> void:
	_setup_node_buttons()

func _setup_node_buttons() -> void:
	start_button.text = "⚔ 일반 전투\n%s" % start_node_data.description
	reward_button.text = "★ 보상\n%s" % reward_node_data.description
	reward_button.disabled = true
	status_label.text = "현재 위치에서 진행할 노드를 선택하세요."

func _on_start_battle_button_pressed() -> void:
	status_label.text = "전투로 이동합니다."
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
