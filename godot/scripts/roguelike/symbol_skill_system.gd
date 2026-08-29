class_name SymbolSkillSystem
extends RefCounted

## 심볼 시너지의 단일 규칙 집합입니다.
## - 기본 심볼 효과는 항상 적용됩니다.
## - 2개 시너지는 요구 수량을 만족하면 각각 1회 적용됩니다.
## - 3개 시너지는 한 굴림에서 최대 2개까지만 적용됩니다.
## - 단일 심볼 시너지는 해당 심볼 장비 태그, 혼합 시너지는 구성 심볼 중 하나의 장비 태그가 필요합니다.
## - 동일 시너지는 요구 조건을 만족해도 중복 발동하지 않습니다.

const BASE_SYMBOLS: Dictionary = {
	1: {"attack": 1}, 2: {"attack": 1, "penetration": 1}, 3: {"attack": 1, "status": 1},
	4: {"attack": 1, "hits": 1}, 5: {"block": 1}, 6: {"heal": 1},
}

const PAIR_SYNERGIES: Array[Dictionary] = [
	{"id":"sword_pair","name":"검의 강타","requires":{1:2},"gear":"sword","attack":2,"description":"검 2개: 추가 피해 +2"},
	{"id":"bow_pair","name":"관통 사격","requires":{2:2},"gear":"bow","penetration":2,"description":"활 2개: 관통 +2"},
	{"id":"staff_pair","name":"화염 주문","requires":{3:2},"gear":"staff","status":2,"description":"지팡이 2개: 상태 효과 +2"},
	{"id":"shuriken_pair","name":"연속 표창","requires":{4:2},"gear":"shuriken","hits":1,"description":"표창 2개: 추가 타격 +1"},
	{"id":"shield_pair","name":"수호 반격","requires":{5:2},"gear":"shield","attack":1,"block":1,"description":"방패 2개: 보호 +1, 반격 +1"},
	{"id":"heal_pair","name":"성스러운 치유","requires":{6:2},"gear":"heal","heal":1,"block":1,"description":"힐 2개: 회복 +1, 보호 +1"},
	{"id":"blade_wall","name":"검벽","requires":{1:1,5:2},"gear_tags":["sword","shield"],"attack":2,"block":2,"description":"검+방패: 공격과 보호"},
	{"id":"shadow_ambush","name":"그림자 습격","requires":{2:1,4:2},"gear_tags":["bow","shuriken"],"attack":2,"hits":1,"description":"활+표창: 관통 연타"},
	{"id":"arcane_life","name":"생명 연성","requires":{3:1,6:2},"gear_tags":["staff","heal"],"heal":2,"status":1,"description":"지팡이+힐: 마법 회복"},
	{"id":"holy_guard","name":"성역","requires":{5:1,6:1},"gear_tags":["shield","heal"],"block":1,"heal":1,"description":"방패+힐: 보호와 회복"},
	{"id":"blade_storm","name":"칼날 폭풍","requires":{1:1,4:1},"gear_tags":["sword","shuriken"],"attack":1,"hits":1,"description":"검+표창: 공격과 연타"},
	{"id":"arcane_arrow","name":"마력 화살","requires":{2:1,3:1},"gear_tags":["bow","staff"],"attack":1,"penetration":1,"status":1,"description":"활+지팡이: 관통과 상태"}
]

const TRIPLE_SYNERGIES: Array[Dictionary] = [
	{"id":"sword_trinity","name":"검의 군세","requires":{1:3},"gear":"sword","attack":3,"hits":1,"description":"검 3개: 피해 +3, 연타 +1"},
	{"id":"bow_trinity","name":"천공의 사격","requires":{2:3},"gear":"bow","attack":2,"penetration":3,"description":"활 3개: 피해 +2, 관통 +3"},
	{"id":"staff_trinity","name":"대마법진","requires":{3:3},"gear":"staff","attack":1,"status":4,"description":"지팡이 3개: 상태 효과 +4"},
	{"id":"shuriken_trinity","name":"수리검 폭우","requires":{4:3},"gear":"shuriken","attack":1,"hits":3,"description":"표창 3개: 피해 +1, 연타 +3"},
	{"id":"shield_trinity","name":"철벽 진형","requires":{5:3},"gear":"shield","attack":1,"block":3,"description":"방패 3개: 보호 +3, 반격 +1"},
	{"id":"heal_trinity","name":"성자의 기도","requires":{6:3},"gear":"heal","heal":3,"block":1,"description":"힐 3개: 회복 +3, 보호 +1"},
	{"id":"warrior_triangle","name":"전쟁의 삼각형","requires":{1:2,5:1},"gear_tags":["sword","shield"],"attack":2,"block":1,"description":"검 2+방패: 공격형 생존"},
	{"id":"spell_guard","name":"마도 수호","requires":{3:2,6:1},"gear_tags":["staff","heal"],"status":2,"heal":1,"description":"지팡이 2+힐: 지속전"},
	{"id":"assassin_triangle","name":"암살자의 삼각형","requires":{2:2,4:1},"gear_tags":["bow","shuriken"],"penetration":2,"hits":2,"description":"활 2+표창: 관통 연타"}
]

static func evaluate(results: Array[DiceRuntimeState], run_state: RunStateManager = null) -> Dictionary:
	var counts: Dictionary = _count_results(results)
	var total: Dictionary = _new_total(counts)
	_apply_base_effects(total, counts)
	if run_state == null:
		return total
	_apply_equipped_synergies(total, counts, run_state)
	return total

## 밸런스 검증용 평가기입니다. 실제 전투의 장비 객체를 만들지 않고
## 활성 synergy_tag만 주입하여 동일한 시너지 규칙을 평가합니다.
static func evaluate_counts(counts: Dictionary, active_tags: Array[String]) -> Dictionary:
	var total: Dictionary = _new_total(counts)
	_apply_base_effects(total, counts)
	for synergy: Dictionary in PAIR_SYNERGIES:
		if _matches(counts, synergy.get("requires", {})) and _has_required_tag(active_tags, synergy):
			_apply_effect(total, synergy)
			total["skills"].append(str(synergy.get("name", "시너지")))
			total["synergies"].append({"tier":2,"id":synergy.get("id",""),"name":synergy.get("name",""),"description":synergy.get("description","")})
			total["synergy_tier"] = maxi(int(total["synergy_tier"]), 2)
	var triple_count: int = 0
	for synergy: Dictionary in TRIPLE_SYNERGIES:
		if triple_count >= 2: break
		if _matches(counts, synergy.get("requires", {})) and _has_required_tag(active_tags, synergy):
			_apply_effect(total, synergy)
			total["skills"].append(str(synergy.get("name", "시너지")))
			total["synergies"].append({"tier":3,"id":synergy.get("id",""),"name":synergy.get("name",""),"description":synergy.get("description","")})
			total["synergy_tier"] = 3
			triple_count += 1
	return total

static func get_synergy_preview(counts: Dictionary, run_state: RunStateManager = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for synergy: Dictionary in PAIR_SYNERGIES:
		if _can_activate(synergy, counts, run_state): result.append({"tier":2,"name":synergy.get("name",""),"description":synergy.get("description","")})
	for synergy: Dictionary in TRIPLE_SYNERGIES:
		if _can_activate(synergy, counts, run_state): result.append({"tier":3,"name":synergy.get("name",""),"description":synergy.get("description","")})
	return result

static func _new_total(counts: Dictionary) -> Dictionary:
	return {"attack":0,"block":0,"heal":0,"penetration":0,"hits":0,"status":0,"skills":[],"counts":counts,"synergy_tier":0,"synergies":[]}

static func _apply_base_effects(total: Dictionary, counts: Dictionary) -> void:
	for symbol: int in BASE_SYMBOLS.keys():
		var count: int = int(counts.get(symbol, 0))
		if count <= 0: continue
		for key: String in BASE_SYMBOLS[symbol].keys(): total[key] = int(total.get(key, 0)) + int(BASE_SYMBOLS[symbol][key]) * count

static func _apply_equipped_synergies(total: Dictionary, counts: Dictionary, run_state: RunStateManager) -> void:
	for synergy: Dictionary in PAIR_SYNERGIES:
		if _can_activate(synergy, counts, run_state):
			_apply_effect(total, synergy)
			total["skills"].append(str(synergy.get("name", "시너지")))
			total["synergies"].append({"tier":2,"id":synergy.get("id",""),"name":synergy.get("name",""),"description":synergy.get("description","")})
			total["synergy_tier"] = maxi(int(total["synergy_tier"]), 2)
	var triple_count: int = 0
	for synergy: Dictionary in TRIPLE_SYNERGIES:
		if triple_count >= 2: break
		if _can_activate(synergy, counts, run_state):
			_apply_effect(total, synergy)
			total["skills"].append(str(synergy.get("name", "시너지")))
			total["synergies"].append({"tier":3,"id":synergy.get("id",""),"name":synergy.get("name",""),"description":synergy.get("description","")})
			total["synergy_tier"] = 3
			triple_count += 1

static func _can_activate(synergy: Dictionary, counts: Dictionary, run_state: RunStateManager) -> bool:
	if not _matches(counts, synergy.get("requires", {})): return false
	if run_state == null: return false
	var active_tags: Array[String] = []
	for gear_id: String in run_state.equipped_by_slot.values():
		var gear: Dictionary = RoguelikeEquipmentSystem.get_gear(gear_id)
		var tag: String = str(gear.get("synergy_tag", ""))
		if not tag.is_empty() and not active_tags.has(tag): active_tags.append(tag)
	return _has_required_tag(active_tags, synergy)

static func _has_required_tag(active_tags: Array[String], synergy: Dictionary) -> bool:
	var gear_tag: String = str(synergy.get("gear", ""))
	if not gear_tag.is_empty(): return active_tags.has(gear_tag)
	var gear_tags: Array = synergy.get("gear_tags", [])
	for tag: String in gear_tags:
		if active_tags.has(tag): return true
	return false

static func _count_results(results: Array[DiceRuntimeState]) -> Dictionary:
	var counts: Dictionary = {}
	for state: DiceRuntimeState in results:
		if state == null or not state.has_result(): continue
		counts[state.result] = int(counts.get(state.result, 0)) + 1
	return counts

static func _apply_effect(total: Dictionary, effect: Dictionary) -> void:
	for key: String in ["attack","block","heal","penetration","hits","status"]:
		if effect.has(key): total[key] = int(total.get(key, 0)) + int(effect.get(key, 0))

static func _matches(counts: Dictionary, requirements: Dictionary) -> bool:
	for symbol in requirements.keys():
		if int(counts.get(symbol, 0)) < int(requirements[symbol]): return false
	return true
