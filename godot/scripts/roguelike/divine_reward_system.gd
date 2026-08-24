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
	if not run_state.record_divine_imprint(die_index, face_index, symbol_id):
		return {"success": false, "message": "선택한 면에 각인할 수 없습니다."}
	return {"success": true, "symbol": symbol_id, "display": reward.get("display", ""), "description": reward.get("description", "")}
