class_name DivineRewardSystem
extends RefCounted

const BOSS_SYMBOLS: Dictionary = {
	"gambling_god": {"name": "도박의 신", "symbol": "gold", "display": "💰 황금", "description": "골드 +1"},
	"battle_god": {"name": "전투의 신", "symbol": "critical", "display": "💥 크리티컬", "description": "공격 피해 ×2"},
	"wisdom_god": {"name": "지혜의 신", "symbol": "foresight", "display": "🔮 예지", "description": "주사위 결과 예측 기회 +1"},
	"life_god": {"name": "생명의 신", "symbol": "life", "display": "❤️ 생명", "description": "회복 효과 +50%"},
	"war_god": {"name": "전쟁의 신", "symbol": "berserk", "display": "⚡ 광전", "description": "HP 30% 이하에서 공격 +50%"},
	"guardian_god": {"name": "수호의 신", "symbol": "sanctuary", "display": "🛡️ 성역", "description": "보호막 획득량 +50%"},
	"fate_god": {"name": "운명의 신", "symbol": "fate", "display": "⭐ 운명", "description": "전투당 심볼 1회 변환"},
	"death_god": {"name": "죽음의 신", "symbol": "death", "display": "☠️ 사신", "description": "적 HP 20% 이하에게 마무리 피해 강화"}
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
