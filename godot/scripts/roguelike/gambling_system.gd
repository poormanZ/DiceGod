class_name GamblingSystem
extends RefCounted

const MIN_WAGER: int = 20
const MAX_WAGER: int = 200

static func play(run_state: RunStateManager, wager: int, die_indices: Array[int], rng: RandomNumberGenerator) -> Dictionary:
	if wager < MIN_WAGER or wager > MAX_WAGER:
		return {"success": false, "message": "베팅 금액은 20G~200G입니다."}
	if die_indices.size() != 3:
		return {"success": false, "message": "주사위 3개를 선택하세요."}
	if not run_state.spend_gold(wager):
		return {"success": false, "message": "골드가 부족합니다."}
	var rolls: Array[int] = []
	for die_index in die_indices:
		var faces: Array = run_state.get_die_faces(die_index)
		if faces.is_empty():
			run_state.add_gold(wager)
			return {"success": false, "message": "잘못된 주사위입니다."}
		rolls.append(int(faces[rng.randi_range(0, faces.size() - 1)]))
	var same: bool = rolls[0] == rolls[1] and rolls[1] == rolls[2]
	var total: int = rolls[0] + rolls[1] + rolls[2]
	var payout: int = 0
	var result_text: String = "꽝"
	if same:
		payout = wager * 6
		result_text = "신의 잭팟"
	elif total >= 14:
		payout = wager * 3
		result_text = "대박"
	elif total >= 10:
		payout = wager * 2
		result_text = "성공"
	if payout > 0:
		run_state.add_gold(payout)
	return {"success": true, "rolls": rolls, "total": total, "payout": payout, "result": result_text}
