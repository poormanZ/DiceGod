class_name CombatRewardSystem
extends RefCounted

## 전투 승리 보상 데이터. 실제 런 주사위는 RunStateManager가 소유합니다.
const SYMBOL_REWARDS: Array[int] = [1, 2, 3, 4, 5, 6]
const GOLD_REWARDS: Array[int] = [15, 20, 25]

static func get_reward_choices(rng: RandomNumberGenerator, count: int = 3) -> Array:
	var choices: Array = []
	var pool: Array[int] = SYMBOL_REWARDS.duplicate()
	pool.shuffle()
	var choice_count: int = mini(count, pool.size())
	for i in choice_count:
		var symbol_id: int = pool[i]
		choices.append({"type": "symbol", "symbol_id": symbol_id, "amount": 1, "name": "%s 면 변경권" % DiceData.name_for(symbol_id)})
	for i in choice_count:
		choices.append({"type": "gold", "amount": GOLD_REWARDS[rng.randi_range(0, GOLD_REWARDS.size() - 1)], "name": "골드 보상"})
	return choices

static func apply_reward(run_state: RunStateManager, reward: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	if run_state == null or reward.is_empty():
		return {"success": false, "message": "보상을 적용할 수 없습니다."}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var reward_type: String = str(reward.get("type", ""))
	match reward_type:
		"gold":
			var amount: int = maxi(0, int(reward.get("amount", 0)))
			run_state.add_gold(amount)
			return {"success": true, "message": "%dG 획득" % amount}
		"symbol":
			var symbol_id: int = int(reward.get("symbol_id", 0))
			if not DiceData.is_base_symbol(symbol_id):
				return {"success": false, "message": "잘못된 심볼 보상입니다."}
			if run_state.run_dice_faces.is_empty():
				return {"success": false, "message": "보유 주사위가 없습니다."}
			var die_index: int = rng.randi_range(0, run_state.run_dice_faces.size() - 1)
			var faces: Array = run_state.get_die_faces(die_index)
			if faces.size() != RunStateManager.DICE_FACE_COUNT:
				return {"success": false, "message": "주사위 면 데이터가 올바르지 않습니다."}
			var face_index: int = rng.randi_range(0, RunStateManager.DICE_FACE_COUNT - 1)
			run_state.run_dice_faces[die_index][face_index] = symbol_id
			return {"success": true, "message": "주사위 %d의 면 %d이(가) %s로 변경되었습니다." % [die_index + 1, face_index + 1, DiceData.name_for(symbol_id)]}
	return {"success": false, "message": "알 수 없는 보상입니다."}
