class_name LegacySystem
extends RefCounted

## 환생은 전투력을 그대로 가져오지 않고, 다음 런의 선택지를 늘리는 메타 시스템입니다.
const LEGACIES: Dictionary = {
	"flame_memory": {"name": "화염의 기억", "description": "대장간에서 1회 무료 화염 심볼 개조 선택", "source": "flame_god", "effect": "flame_event_choice"},
	"frost_memory": {"name": "빙결의 기억", "description": "빙결 보스의 다음 행동을 한 턴 앞까지 확인", "source": "frost_god", "effect": "boss_preview"},
	"plague_memory": {"name": "역병의 기억", "description": "이벤트의 위험도와 기본 보상을 미리 확인", "source": "plague_god", "effect": "event_preview"},
	"blood_memory": {"name": "혈왕의 기억", "description": "HP 소비 이벤트에서 안전한 대체 선택지를 확인", "source": "blood_god", "effect": "hp_trade_choice"},
	"storm_memory": {"name": "폭풍의 기억", "description": "첫 전투에서 추가 리롤 선택지를 확인", "source": "storm_god", "effect": "reroll_preview"},
	"stone_memory": {"name": "거암의 기억", "description": "대장간에서 방어형 심볼 개조 선택지를 추가", "source": "stone_god", "effect": "defensive_forge"},
	"fate_memory": {"name": "운명의 기억", "description": "도박과 위험 이벤트의 성공 확률을 공개", "source": "fate_god", "effect": "event_odds"},
	"void_memory": {"name": "공허의 기억", "description": "상점에 특수 주사위 후보를 추가", "source": "void_god", "effect": "special_shop_choice"}
}

static func get_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for legacy_id in LEGACIES.keys():
		var entry: Dictionary = LEGACIES[legacy_id].duplicate(true)
		entry["id"] = str(legacy_id)
		result.append(entry)
	return result

static func get_legacy(legacy_id: String) -> Dictionary:
	var entry: Dictionary = LEGACIES.get(legacy_id, {}).duplicate(true)
	if not entry.is_empty(): entry["id"] = legacy_id
	return entry

static func unlock_for_boss(boss_id: String) -> bool:
	var found: bool = false
	var newly_unlocked_count: int = 0
	for legacy_id in LEGACIES.keys():
		var entry: Dictionary = LEGACIES[legacy_id]
		if str(entry.get("source", "")) == boss_id:
			found = true
			if ProgressionState.unlock_legacy_option(str(legacy_id)):
				newly_unlocked_count += 1
	# 보스 진행에 따라 새로운 유산이 해금될 때마다 슬롯을 하나씩 늘립니다.
	# (docs/progression_design.md: 슬롯 수가 많아질수록 조합의 폭이 넓어짐)
	if newly_unlocked_count > 0:
		ProgressionState.increase_legacy_slots(newly_unlocked_count)
	return found

static func get_unlocked() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for legacy_id in ProgressionState.unlocked_legacy_options:
		var entry: Dictionary = get_legacy(str(legacy_id))
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
		var entry: Dictionary = get_legacy(str(legacy_id))
		if str(entry.get("effect", "")) == effect: return true
	return false

static func get_effects(selected: Array[String]) -> Array[String]:
	var effects: Array[String] = []
	for legacy_id in selected:
		var entry: Dictionary = get_legacy(str(legacy_id))
		var effect: String = str(entry.get("effect", ""))
		if not effect.is_empty() and not effects.has(effect): effects.append(effect)
	return effects

static func has_any_effect(selected: Array[String], effects: Array[String]) -> bool:
	for effect: String in effects:
		if has_effect(selected, effect): return true
	return false

static func get_event_preview(selected: Array[String], event_type: String, base_description: String) -> String:
	var result: String = base_description
	if has_any_effect(selected, ["event_preview", "event_odds"]):
		result += "\n위험도: %s" % RoguelikeEventSystem.get_event_risk(event_type)
	if has_effect(selected, "event_odds") and event_type == "gamble":
		result += "\n성공 확률: 66.7% 이상(주사위 3~6)"
	return result

static func get_forge_options(selected: Array[String]) -> Array[int]:
	var result: Array[int] = ForgeSystem.get_symbol_ids()
	if has_effect(selected, "defensive_forge") and not result.has(5):
		result.append(5)
	if has_effect(selected, "flame_event_choice") and not result.has(1):
		result.append(1)
	return result
