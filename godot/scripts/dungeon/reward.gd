class_name DungeonReward
extends Control

## 일반/엘리트 전투 승리 후 보상 선택 화면.
## 보상 생성/적용은 CombatRewardSystem이 담당하고 실제 런 데이터는 RunState가 소유합니다.

@onready var reward_buttons: Array[Button] = [
	$MarginContainer/Content/RewardChoices/GoldButton,
	$MarginContainer/Content/RewardChoices/HealButton,
	$MarginContainer/Content/RewardChoices/DiceButton,
]
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var reward_claimed: bool = false
var rewards: Array[Dictionary] = []
var reward_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	reward_rng.randomize()
	_ensure_run_dice()
	_generate_rewards()
	_refresh_buttons()
	status_label.text = "전투 승리! 보상 하나를 선택하세요."

func _ensure_run_dice() -> void:
	if not RunState.run_dice_faces.is_empty(): return
	var basic_dice: DiceData = load("res://resources/dice/basic_dice.tres") as DiceData
	if basic_dice != null: RunState.initialize_run_dice(basic_dice.face_values)

func _generate_rewards() -> void:
	rewards = CombatRewardSystem.get_reward_choices(reward_rng, RunState, RunState.elite_cleared)

func _refresh_buttons() -> void:
	for index: int in reward_buttons.size():
		var button: Button = reward_buttons[index]
		button.disabled = false
		if index >= rewards.size():
			button.visible = false
			continue
		button.visible = true
		var reward: Dictionary = rewards[index]
		button.text = "%s\n%s" % [str(reward.get("name", "보상")), str(reward.get("description", ""))]

func _claim_reward(index: int) -> void:
	if reward_claimed or index < 0 or index >= rewards.size(): return
	var reward: Dictionary = rewards[index]
	var result: Dictionary = CombatRewardSystem.apply_reward(RunState, reward, reward_rng)
	if not bool(result.get("success", false)):
		status_label.text = str(result.get("message", "보상 적용에 실패했습니다."))
		return
	reward_claimed = true
	RunState.reward_claimed = true
	RunState.reward_id = "%s_%s" % [str(reward.get("type", "reward")), str(reward.get("amount", reward.get("symbol_id", "")))]
	for button: Button in reward_buttons: button.disabled = true
	status_label.text = str(result.get("message", "보상을 획득했습니다."))
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_gold_button_pressed() -> void: _claim_reward(0)
func _on_heal_button_pressed() -> void: _claim_reward(1)
func _on_dice_button_pressed() -> void: _claim_reward(2)
