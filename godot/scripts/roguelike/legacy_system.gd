class_name LegacySystem
extends RefCounted

## 환생은 전투력을 그대로 가져오지 않고, 다음 런의 선택지를 늘리는 메타 시스템입니다.
const LEGACIES: Dictionary = {
	"flame_memory": {"name": "화염의 기억", "description": "화염 이벤트가 등장할 때 대장간 무료 선택지를 1회 제안", "source": "flame_god", "effect": "flame_event_choice"},
	"frost_memory": {"name": "빙결의 기억", "description": "빙결 보스가 등장하면 첫 행동을 미리 확인할 수 있음", "source": "frost_god", "effect": "boss_preview"},
	"plague_memory": {"name": "역병의 기억", "description": "역병 이벤트에서 위험/보상 수치를 추가로 공개", "source": "plague_god", "effect": "event_preview"},
	"blood_memory": {"name": "혈왕의 기억", "description": "HP를 소비하는 이벤트의 대체 선택지를 해금", "source": "blood_god", "effect": "hp_trade_choice"},
	"storm_memory": {"name": "폭풍의 기억", "description": "첫 전투에서 리롤 선택지를 하나 더 확인", "source": "storm_god", "effect": "reroll_preview"},
	"stone_memory": {"name": "거암의 기억", "description": "대장간에서 방어형 개조 선택지를 추가", "source": "stone_god", "effect": "defensive_forge"},
	"fate_memory": {"name": "운명의 기억", "description": "이벤트 선택 결과의 성공 확률을 미리 확인", "source": "fate_god", "effect": "event_odds"},
	"void_memory": {"name": "공허의 기억", "description": "상점에서 특수 주사위 후보를 하나 더 확인", "source": "void_god", "effect": "special_shop_choice"}
}

static func get_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for legacy_id in LEGACIES.keys():
		var entry: Dictionary = LEGACIES[legacy_id].duplicate(true)
		entry["id"] = str(legacy_id)
		result.append(entry)
	return result

static func get(legacy_id: String) -> Dictionary:
	var entry: Dictionary = LEGACIES.get(legacy_id, {}).duplicate(true)
	if not entry.is_empty(): entry["id"] = legacy_id
	return entry

static func unlock_for_boss(boss_id: String) -> bool:
	var found: bool = false
	for legacy_id in LEGACIES.keys():
		var entry: Dictionary = LEGACIES[legacy_id]
		if str(entry.get("source", "")) == boss_id:
			found = true
			ProgressionState.unlock_legacy_option(str(legacy_id))
	if found and ProgressionState.legacy_slots <= 0:
		ProgressionState.increase_legacy_slots(1)
	return found

static func get_unlocked() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for legacy_id in ProgressionState.unlocked_legacy_options:
		var entry: Dictionary = get(str(legacy_id))
		if not entry.is_empty(): result.append(entry)
	return result

static func is_unlocked(legacy_id: String) -> bool:
	return ProgressionState.unlocked_legacy_options.has(legacy_id)

static func can_select(legacy_id: String, selected: Array[String]) -> bool:
	if not is_unlocked(legacy_id) or selected.has(legacy_id): return false
	return selected.size() < maxi(0, ProgressionState.legacy_slots)

static func select(legacy_id: String, selected: Array[String]) -> bool:
	if not can_select(legacy_id, selected): return false
	selected.append(legacy_id)
	return true

static func has_effect(selected: Array[String], effect: String) -> bool:
	for legacy_id in selected:
		var entry: Dictionary = get(str(legacy_id))
		if str(entry.get("effect", "")) == effect: return true
	return false
