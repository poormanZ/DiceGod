class_name DivineRewardSystem
extends RefCounted

const BOSS_SYMBOLS: Dictionary = {
	"flame_god": {"name": "화염군주", "symbol": "flame", "display": "🔥 화염", "description": "보스의 화염 심볼 효과 강화"},
	"frost_god": {"name": "빙결왕", "symbol": "frost", "display": "❄️ 빙결", "description": "보스의 빙결 심볼 효과 강화"},
	"plague_god": {"name": "역병군주", "symbol": "plague", "display": "☠️ 역병", "description": "보스의 역병 심볼 효과 강화"},
	"blood_god": {"name": "혈왕", "symbol": "blood", "display": "🩸 혈액", "description": "보스의 혈액 심볼 효과 강화"},
	"storm_god": {"name": "폭풍신", "symbol": "storm", "display": "⚡ 폭풍", "description": "보스의 폭풍 심볼 효과 강화"},
	"stone_god": {"name": "거암왕", "symbol": "stone", "display": "🪨 거암", "description": "보스의 거암 심볼 효과 강화"},
	"fate_god": {"name": "운명의 신", "symbol": "fate", "display": "🔮 운명", "description": "보스의 운명 심볼 효과 강화"},
	"void_god": {"name": "공허신", "symbol": "void", "display": "🌑 공허", "description": "보스의 공허 심볼 효과 강화"}
}

const BOSS_FACE_VALUES: Dictionary = {
	"flame": 201,
	"frost": 202,
	"plague": 203,
	"blood": 204,
	"storm": 205,
	"stone": 206,
	"fate": 207,
	"void": 208
}

static func get_boss_reward(boss_id: String) -> Dictionary:
	return BOSS_SYMBOLS.get(boss_id, {})

static func unlock_boss_symbol(run_state: RunStateManager, boss_id: String) -> bool:
	var reward: Dictionary = get_boss_reward(boss_id)
	if reward.is_empty():
		return false
	var symbol_id: String = str(reward.get("symbol", ""))
	run_state.current_boss_id = boss_id
	run_state.unlock_divine_symbol(symbol_id)
	ProgressionState.unlock_divine_symbol(symbol_id)
	ProgressionState.unlock_boss(boss_id)
	return true

static func imprint(run_state: RunStateManager, die_index: int, face_index: int, boss_id: String) -> Dictionary:
	var reward: Dictionary = get_boss_reward(boss_id)
	if reward.is_empty():
		return {"success": false, "message": "알 수 없는 보스입니다."}
	var symbol_id: String = str(reward.get("symbol", ""))
	if not run_state.unlocked_divine_symbols.has(symbol_id):
		return {"success": false, "message": "먼저 보스를 처치해야 합니다."}
	if die_index < 0 or die_index >= run_state.run_dice_faces.size() or face_index < 0 or face_index >= RunStateManager.DICE_FACE_COUNT:
		return {"success": false, "message": "잘못된 주사위 면입니다."}

	# 기존 record_divine_imprint은 일반 신성 심볼(101~108)만 지원하므로
	# 보스 전용 심볼(201~208)은 여기서 동일한 각인 규칙으로 처리합니다.
	for imprint_entry: Dictionary in run_state.divine_symbol_history:
		if int(imprint_entry.get("die_index", -1)) == die_index and int(imprint_entry.get("face_index", -1)) == face_index:
			return {"success": false, "message": "이미 각인된 면입니다."}
	var current_count: int = 0
	for imprint_entry: Dictionary in run_state.divine_symbol_history:
		if int(imprint_entry.get("die_index", -1)) == die_index:
			current_count += 1
	if current_count >= RunStateManager.MAX_DIVINE_FACES:
		return {"success": false, "message": "이 주사위에는 신성 심볼을 최대 2개까지 각인할 수 있습니다."}

	var face_value: int = int(BOSS_FACE_VALUES.get(symbol_id, 0))
	if face_value == 0:
		return {"success": false, "message": "지원하지 않는 보스 심볼입니다."}
	run_state.run_dice_faces[die_index][face_index] = face_value
	run_state.divine_symbol_history.append({"die_index": die_index, "face_index": face_index, "symbol_id": symbol_id})
	return {"success": true, "symbol": symbol_id, "display": reward.get("display", ""), "description": reward.get("description", "")}
