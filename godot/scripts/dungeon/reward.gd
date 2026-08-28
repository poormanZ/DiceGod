class_name DungeonReward
extends Control

## 일반/엘리트 전투 승리 후 보상 선택 화면.
## 보상은 런 중 주사위 빌드와 직접 연결되며 영구 성장과 분리됩니다.

@onready var reward_buttons: Array[Button] = [
	$MarginContainer/Content/RewardChoices/GoldButton,
	$MarginContainer/Content/RewardChoices/HealButton,
	$MarginContainer/Content/RewardChoices/DiceButton,
]
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var reward_claimed: bool = false
var gold_amount: int = 0
var heal_amount: int = 0
var reward_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	reward_rng.randomize()
	_ensure_run_dice()
	if RunState.elite_cleared:
		gold_amount = reward_rng.randi_range(70, 140)
		heal_amount = 2
	else:
		gold_amount = reward_rng.randi_range(30, 70)
		heal_amount = 1
	reward_buttons[0].text = "+%dG\n전투 승리 골드" % gold_amount
	reward_buttons[1].text = "HP +%d\n회복" % heal_amount
	reward_buttons[2].text = "주사위 개조\n무작위 면 1개 변경"
	for button: Button in reward_buttons:
		button.disabled = false
	status_label.text = "전투 승리! 보상 하나를 선택하세요."

func _ensure_run_dice() -> void:
	if not RunState.run_dice_faces.is_empty():
		return
	var basic_dice: DiceData = load("res://resources/dice/basic_dice.tres") as DiceData
	if basic_dice != null:
		RunState.initialize_run_dice(basic_dice.face_values)

func _claim_reward(reward_type: String) -> void:
	if reward_claimed:
		return
	_ensure_run_dice()
	var message: String = ""
	match reward_type:
		"gold":
			RunState.add_gold(gold_amount)
			RunState.reward_id = "gold_%d" % gold_amount
			message = "+%dG 획득" % gold_amount
		"heal":
			var healed: int = RunState.heal(heal_amount)
			RunState.reward_id = "heal_%d" % healed
			message = "HP +%d 회복" % healed
		"dice":
			var result: Dictionary = _modify_random_die_face()
			if not bool(result.get("success", false)):
				status_label.text = str(result.get("message", "주사위 개조에 실패했습니다."))
				return
			RunState.reward_id = "dice_modify"
			message = str(result.get("message", "주사위를 개조했습니다."))
		_:
			return
	reward_claimed = true
	RunState.reward_claimed = true
	for button: Button in reward_buttons:
		button.disabled = true
	status_label.text = message
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _modify_random_die_face() -> Dictionary:
	if RunState.run_dice_faces.is_empty():
		return {"success": false, "message": "보유 주사위가 없습니다."}
	var die_index: int = reward_rng.randi_range(0, RunState.run_dice_faces.size() - 1)
	var faces: Array = RunState.get_die_faces(die_index)
	if faces.size() != RunStateManager.DICE_FACE_COUNT:
		return {"success": false, "message": "주사위 면 데이터가 올바르지 않습니다."}
	var face_index: int = reward_rng.randi_range(0, RunStateManager.DICE_FACE_COUNT - 1)
	var symbols: Array[int] = [DiceData.SWORD, DiceData.BOW, DiceData.STAFF, DiceData.SHURIKEN, DiceData.SHIELD, DiceData.HEAL]
	var symbol_id: int = symbols[reward_rng.randi_range(0, symbols.size() - 1)]
	RunState.run_dice_faces[die_index][face_index] = symbol_id
	return {"success": true, "message": "주사위 %d의 %d번 면 → %s" % [die_index + 1, face_index + 1, DiceData.name_for(symbol_id)]}

func _on_gold_button_pressed() -> void:
	_claim_reward("gold")

func _on_heal_button_pressed() -> void:
	_claim_reward("heal")

func _on_dice_button_pressed() -> void:
	_claim_reward("dice")
