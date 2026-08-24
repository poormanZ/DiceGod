class_name DungeonReward
extends Control

## 일반 전투 승리 후 보상 화면
## 구형 빌드/장비/특수 주사위 시스템을 사용하지 않습니다.

@onready var reward_buttons: Array[Button] = [
	$MarginContainer/Content/RewardChoices/GoldButton,
	$MarginContainer/Content/RewardChoices/HealButton,
	$MarginContainer/Content/RewardChoices/DiceButton,
]
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var reward_claimed: bool = false
var reward_options: Array[int] = [40, 60, 80]

func _ready() -> void:
	reward_options.shuffle()
	for index: int in reward_buttons.size():
		var gold_amount: int = reward_options[index]
		reward_buttons[index].text = "💰 골드 +%d\n전투 보상으로 골드를 획득합니다." % gold_amount
		reward_buttons[index].disabled = false
	status_label.text = "골드 보상 3개 중 하나를 선택하세요."

func _claim_reward(index: int) -> void:
	if reward_claimed or index < 0 or index >= reward_options.size():
		return
	reward_claimed = true
	var gold_amount: int = reward_options[index]
	RunState.reward_claimed = true
	RunState.reward_id = "gold_%d" % gold_amount
	RunState.add_gold(gold_amount)
	for button: Button in reward_buttons:
		button.disabled = true
	status_label.text = "💰 골드 %d를 획득했습니다!" % gold_amount
	await get_tree().create_timer(0.5).timeout
	# 보상 선택 완료 후 던전 맵으로 돌아가면 Dungeon이 현재 런 상태를
	# 기준으로 다음 노드(이벤트 → 엘리트 → 이벤트 → 보스)를 활성화합니다.
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_gold_button_pressed() -> void:
	_claim_reward(0)

func _on_heal_button_pressed() -> void:
	_claim_reward(1)

func _on_dice_button_pressed() -> void:
	_claim_reward(2)
