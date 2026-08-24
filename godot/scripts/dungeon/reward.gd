class_name DungeonReward
extends Control

@onready var reward_buttons: Array[Button] = [
	$MarginContainer/Content/RewardChoices/GoldButton,
	$MarginContainer/Content/RewardChoices/HealButton,
	$MarginContainer/Content/RewardChoices/DiceButton,
]
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var reward_claimed: bool = false
var reward_options: Array[int] = []

func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	reward_options = [40, 60, 80]
	reward_options.shuffle()
	var gold_bonus: int = RoguelikeEquipmentSystem.bonus(RunState, "gold")
	var divine_gold_bonus: int = _count_divine_gold_faces()
	for index in reward_buttons.size():
		var gold_amount: int = reward_options[index] + gold_bonus + divine_gold_bonus
		reward_options[index] = gold_amount
		reward_buttons[index].text = "💰 골드 +%d\n전투 보상으로 골드를 획득합니다." % gold_amount
		reward_buttons[index].disabled = false
	status_label.text = "골드 보상 3개 중 하나를 선택하세요."

func _count_divine_gold_faces() -> int:
	var count: int = 0
	for die in RunState.run_dice_faces:
		for face in die:
			if int(face) == DiceData.DIVINE_GOLD:
				count += 1
	return count

func _claim_reward(index: int) -> void:
	if reward_claimed or index < 0 or index >= reward_options.size():
		return
	reward_claimed = true
	var gold_amount: int = reward_options[index]
	RunState.reward_claimed = true
	RunState.reward_id = "gold_%d" % gold_amount
	RunState.add_gold(gold_amount)
	for button in reward_buttons:
		button.disabled = true
	status_label.text = "💰 골드 %d를 획득했습니다!\n%s" % [gold_amount, RunState.get_run_summary()]
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_gold_button_pressed() -> void:
	_claim_reward(0)

func _on_heal_button_pressed() -> void:
	_claim_reward(1)

func _on_dice_button_pressed() -> void:
	_claim_reward(2)
