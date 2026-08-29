class_name CombatRewardSystem
extends RefCounted

## 전투 승리 보상은 런 중 성장만 담당합니다.
## 골드/회복/주사위 면 개조를 하나의 데이터 흐름으로 만들어
## 보상 UI와 실제 RunState 변경이 서로 다른 규칙을 사용하지 않도록 합니다.
const SYMBOL_REWARDS: Array[int] = [1, 2, 3, 4, 5, 6]
const GOLD_REWARDS: Array[int] = [30, 40, 50]
const ELITE_GOLD_REWARDS: Array[int] = [70, 90, 120]
const NORMAL_HEAL: int = 1
const ELITE_HEAL: int = 2

static func get_reward_choices(rng: RandomNumberGenerator, run_state: RunStateManager, elite: bool = false) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var gold_pool: Array[int] = ELITE_GOLD_REWARDS if elite else GOLD_REWARDS
	var gold_amount: int = gold_pool[rng.randi_range(0, gold_pool.size() - 1)]
	choices.append({"type":"gold", "amount":gold_amount, "name":"골드 +%dG" % gold_amount, "description":"상점과 대장간에서 사용할 런 전용 재화입니다."})
	var heal_amount: int = ELITE_HEAL if elite else NORMAL_HEAL
	choices.append({"type":"heal", "amount":heal_amount, "name":"HP +%d" % heal_amount, "description":"현재 런의 HP를 회복합니다."})
	if run_state != null and not run_state.run_dice_faces.is_empty():
		var die_index: int = rng.randi_range(0, run_state.run_dice_faces.size() - 1)
		var face_index: int = rng.randi_range(0, RunStateManager.DICE_FACE_COUNT - 1)
		var current_symbol: int = int(run_state.run_dice_faces[die_index][face_index])
		var symbol_id: int = SYMBOL_REWARDS[rng.randi_range(0, SYMBOL_REWARDS.size() - 1)]
		while symbol_id == current_symbol and SYMBOL_REWARDS.size() > 1:
			symbol_id = SYMBOL_REWARDS[rng.randi_range(0, SYMBOL_REWARDS.size() - 1)]
		choices.append({"type":"dice", "die_index":die_index, "face_index":face_index, "symbol_id":symbol_id, "name":"주사위 개조", "description":"주사위 %d의 %d번 면을 %s로 변경" % [die_index + 1, face_index + 1, DiceData.name_for(symbol_id)]})
	return choices

static func apply_reward(run_state: RunStateManager, reward: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	if run_state == null or reward.is_empty(): return {"success":false,"message":"보상을 적용할 수 없습니다."}
	match str(reward.get("type", "")):
		"gold":
			var amount: int = maxi(0, int(reward.get("amount", 0)))
			run_state.add_gold(amount)
			return {"success":true,"message":"%dG 획득" % amount}
		"heal":
			var heal_amount: int = maxi(0, int(reward.get("amount", 0)))
			var healed: int = run_state.heal(heal_amount)
			return {"success":true,"message":"HP +%d 회복" % healed}
		"dice":
			return _apply_dice_reward(run_state, reward)
	return {"success":false,"message":"알 수 없는 보상입니다."}

static func _apply_dice_reward(run_state: RunStateManager, reward: Dictionary) -> Dictionary:
	if run_state.run_dice_faces.is_empty(): return {"success":false,"message":"보유 주사위가 없습니다."}
	var die_index: int = int(reward.get("die_index", -1))
	var face_index: int = int(reward.get("face_index", -1))
	var symbol_id: int = int(reward.get("symbol_id", 0))
	if die_index < 0 or die_index >= run_state.run_dice_faces.size(): return {"success":false,"message":"잘못된 주사위 대상입니다."}
	if face_index < 0 or face_index >= RunStateManager.DICE_FACE_COUNT: return {"success":false,"message":"잘못된 주사위 면입니다."}
	if not DiceData.is_base_symbol(symbol_id): return {"success":false,"message":"잘못된 심볼 보상입니다."}
	var old_symbol: int = int(run_state.run_dice_faces[die_index][face_index])
	run_state.run_dice_faces[die_index][face_index] = symbol_id
	return {"success":true,"message":"주사위 %d의 %d번 면: %s → %s" % [die_index + 1, face_index + 1, DiceData.name_for(old_symbol), DiceData.name_for(symbol_id)]}
