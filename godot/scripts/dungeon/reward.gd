class_name DungeonReward
extends Control

@onready var reward_buttons: Array[Button] = [
	$MarginContainer/Content/RewardChoices/GoldButton,
	$MarginContainer/Content/RewardChoices/HealButton,
	$MarginContainer/Content/RewardChoices/DiceButton,
]
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var reward_claimed: bool = false
var reward_options: Array[String] = []
const REWARDS := {
	"gold": {"label": "골드 +50", "description": "런 골드를 50 획득합니다.", "value": 50},
	"heal": {"label": "HP +20", "description": "현재 HP를 20 회복합니다.", "value": 20},
	"dice": {"label": "주사위 강화", "description": "런 동안 주사위 슬롯 보너스 +1.", "value": 1},
	"attack": {"label": "공격력 +3", "description": "런 동안 기본 공격력 +3.", "value": 3},
	"flame": {"label": "화염의 축복", "description": "공격력 +5. 다음 전투가 불타오릅니다.", "value": 5},
	"fortune": {"label": "행운의 축복", "description": "주사위 강화 +2.", "value": 2},
}

func _ready() -> void:
	var available_rewards: Array[String] = []
	for reward_key in REWARDS.keys():
		available_rewards.append(str(reward_key))
	available_rewards.shuffle()
	reward_options = available_rewards.slice(0, reward_buttons.size())
	for index in reward_buttons.size():
		var reward_id: String = reward_options[index]
		var reward_data: Dictionary = REWARDS[reward_id]
		reward_buttons[index].text = "%s\n%s" % [reward_data["label"], reward_data["description"]]
		reward_buttons[index].disabled = false
	status_label.text = "무작위 보상 3개 중 하나를 선택하세요."

func _claim_reward(reward_id: String) -> void:
	if reward_claimed or not REWARDS.has(reward_id):
		return
	reward_claimed = true
	RunState.reward_claimed = true
	RunState.reward_id = reward_id
	var reward: Dictionary = REWARDS[reward_id]
	match reward_id:
		"gold":
			RunState.add_gold(int(reward["value"]))
		"heal":
			RunState.heal(int(reward["value"]))
		"dice", "fortune":
			RunState.unlocked_dice_bonus += int(reward["value"])
		"attack", "flame":
			RunState.attack_bonus += int(reward["value"])
	for button in reward_buttons:
		button.disabled = true
	status_label.text = "%s 보상을 획득했습니다!\n%s" % [reward["label"], RunState.get_run_summary()]
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_gold_button_pressed() -> void:
	_claim_reward(reward_options[0])

func _on_heal_button_pressed() -> void:
	_claim_reward(reward_options[1])

func _on_dice_button_pressed() -> void:
	_claim_reward(reward_options[2])
