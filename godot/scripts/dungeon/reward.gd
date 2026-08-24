class_name DungeonReward
extends Control

## 일반 전투/엘리트 승리 후 자동 골드 보상 화면
## 보상 선택지 없이 무작위 골드를 즉시 지급합니다.

@onready var reward_buttons: Array[Button] = [
	$MarginContainer/Content/RewardChoices/GoldButton,
	$MarginContainer/Content/RewardChoices/HealButton,
	$MarginContainer/Content/RewardChoices/DiceButton,
]
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var reward_claimed: bool = false
var gold_amount: int = 0
var reward_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	reward_rng.randomize()
	# 일반 전투와 엘리트 전투는 서로 다른 골드 범위를 사용합니다.
	# 일반 전투: 30~70G / 엘리트: 70~140G
	if RunState.elite_cleared:
		gold_amount = reward_rng.randi_range(70, 140)
	else:
		gold_amount = reward_rng.randi_range(30, 70)

	reward_buttons[0].text = "💰 +%dG\n전투 승리 골드" % gold_amount
	reward_buttons[0].disabled = false
	for index: int in range(1, reward_buttons.size()):
		reward_buttons[index].hide()
		reward_buttons[index].disabled = true

	status_label.text = "💰 전투 승리 보상: %dG" % gold_amount
	await get_tree().create_timer(0.35).timeout
	_claim_reward()

func _claim_reward() -> void:
	if reward_claimed:
		return
	reward_claimed = true
	RunState.reward_claimed = true
	RunState.reward_id = "gold_%d" % gold_amount
	RunState.add_gold(gold_amount)
	reward_buttons[0].disabled = true
	status_label.text = "💰 %dG를 획득했습니다!" % gold_amount
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_gold_button_pressed() -> void:
	_claim_reward()

func _on_heal_button_pressed() -> void:
	# 이전 씬 연결 호환용: 현재 골드 보상에서는 사용하지 않습니다.
	_claim_reward()

func _on_dice_button_pressed() -> void:
	# 이전 씬 연결 호환용: 현재 골드 보상에서는 사용하지 않습니다.
	_claim_reward()
