class_name CombatRewardSystem
extends RefCounted

## 전투 승리 보상. 런 중에만 적용되며 영구 해금과 분리합니다.
const SYMBOL_REWARDS: Array[int] = [1, 2, 3, 4, 5, 6]
const GOLD_REWARDS: Array[int] = [15, 20, 25]

static func get_reward_choices(rng: RandomNumberGenerator, count: int = 3) -> Array:
	var choices: Array = []
	var pool: Array = SYMBOL_REWARDS.duplicate()
	pool.shuffle()
	for i in mini(count, pool.size()):
		var symbol_id: int = int(pool[i])
		choices.append({"type": "symbol", "symbol_id": symbol_id, "amount": 1, "name": "%s 면 추가" % DiceData.name_for(symbol_id)})
	choices.append({"type": "gold", "amount": GOLD_REWARDS[rng.randi_range(0, GOLD_REWARDS.size() - 1)], "name": "골드 보상"})
	return choices

static func apply_reward(run_state: RunStateManager, reward: Dictionary) -> Dictionary:
	if run_state == null or reward.is_empty():
		return {"success": false, "message": "보상을 적용할 수 없습니다."}
	var reward_type: String = str(reward.get("type", ""))
	match reward_type:
		"gold":
			var amount: int = int(reward.get("amount", 0))
			run_state.gold += amount
			return {"success": true, "message": "%dG 획득" % amount}
		"symbol":
			var symbol_id: int = int(reward.get("symbol_id", 0))
			if symbol_id <= 0:
				return {"success": false, "message": "잘못된 심볼 보상입니다."}
			# 기존 6개 주사위를 유지하면서 랜덤 면 하나를 보상 심볼로 변경합니다.
			if run_state.run_dice_faces.is_empty():
				if run_state.has_method("start_new_run"):
					run_state.start_new_run()
			if run_state.run_dice_faces.is_empty():
				return {"success": false, "message": "보유 주사위가 없습니다."}
			var die_index: int = run_state.rng.randi_range(0, run_state.run_dice_faces.size() - 1)
			var faces: Array = run_state.get_die_faces(die_index)
			if faces.is_empty():
				return {"success": false, "message": "주사위 면을 읽을 수 없습니다."}
			var face_index: int = run_state.rng.randi_range(0, faces.size() - 1)
			run_state.set_die_face(die_index, face_index, symbol_id)
			return {"success": true, "message": "주사위 %d의 면이 %s로 변경되었습니다." % [die_index + 1, DiceData.name_for(symbol_id)]}
	return {"success": false, "message": "알 수 없는 보상입니다."}
