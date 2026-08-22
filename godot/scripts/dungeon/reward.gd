class_name DungeonReward
extends Control

@onready var reward_buttons: Array[Button] = [
	$MarginContainer/Content/RewardChoices/GoldButton,
	$MarginContainer/Content/RewardChoices/HealButton,
	$MarginContainer/Content/RewardChoices/DiceButton,
]
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var reward_claimed: bool = false

func _ready() -> void:
	if not get_tree().has_meta("dungeon_gold"):
		get_tree().set_meta("dungeon_gold", 100)
	for button in reward_buttons:
		button.disabled = false
	status_label.text = "보상 하나를 선택하세요."

func _claim_reward(reward_id: String, reward_text: String) -> void:
	if reward_claimed:
		return
	reward_claimed = true
	get_tree().set_meta("dungeon_reward_claimed", true)
	get_tree().set_meta("dungeon_reward_id", reward_id)
	if reward_id == "gold":
		var gold: int = int(get_tree().get_meta("dungeon_gold", 100))
		get_tree().set_meta("dungeon_gold", gold + 50)
	for button in reward_buttons:
		button.disabled = true
	status_label.text = "%s 보상을 획득했습니다!\n다음은 이벤트 노드입니다." % reward_text
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_gold_button_pressed() -> void:
	_claim_reward("gold", "골드 +50")

func _on_heal_button_pressed() -> void:
	_claim_reward("heal", "HP +20")

func _on_dice_button_pressed() -> void:
	_claim_reward("dice", "주사위 강화")
