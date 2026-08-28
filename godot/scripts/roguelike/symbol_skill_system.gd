class_name SymbolSkillSystem
extends RefCounted

# 기본 심볼 역할
# 1 검: 순수 공격력
# 2 활: 공격 + 방어 관통
# 3 지팡이: 공격 + 화상 누적
# 4 표창: 공격 + 다단 히트
# 5 방패: 보호막
# 6 힐: 회복
const BASE_SYMBOLS: Dictionary = {
	1: {"attack": 1},
	2: {"attack": 1, "penetration": 1},
	3: {"attack": 1, "status": 1},
	4: {"attack": 1, "hits": 1},
	5: {"block": 1},
	6: {"heal": 1},
}

const SKILLS: Array[Dictionary] = [
	{"id": "sword_barrage", "name": "검의 강타", "requires": {1: 2}, "attack": 2, "description": "검 2개 이상이면 추가 피해 +2"},
	{"id": "bow_pierce", "name": "관통 사격", "requires": {2: 2}, "penetration": 2, "description": "활 2개 이상이면 추가 관통 +2"},
	{"id": "staff_burn", "name": "화염 주문", "requires": {3: 2}, "status": 2, "description": "지팡이 2개 이상이면 화상 +2"},
	{"id": "shuriken_combo", "name": "연속 표창", "requires": {4: 2}, "hits": 1, "description": "표창 2개 이상이면 추가 타격 +1"},
	{"id": "shield_counter", "name": "수호 반격", "requires": {5: 2}, "attack": 1, "block": 1, "description": "방패 2개 이상이면 보호 +1, 반격 +1"},
	{"id": "holy_burst", "name": "성스러운 치유", "requires": {6: 2}, "heal": 1, "shield": 1, "description": "힐 2개 이상이면 회복 +1, 보호 +1"},
	{"id": "blade_wall", "name": "검벽", "requires": {1: 1, 5: 2}, "attack": 2, "block": 2, "description": "검+방패 조합"},
	{"id": "shadow_ambush", "name": "그림자 습격", "requires": {2: 1, 4: 2}, "attack": 2, "hits": 1, "description": "활+표창 조합"},
	{"id": "arcane_life", "name": "생명 연성", "requires": {3: 1, 6: 2}, "heal": 2, "status": 1, "description": "지팡이+힐 조합"}
]

static func evaluate(results: Array[DiceRuntimeState]) -> Dictionary:
	var counts: Dictionary = {}
	for state in results:
		if state == null or not state.has_result():
			continue
		var symbol: int = state.result
		counts[symbol] = int(counts.get(symbol, 0)) + 1

	var total: Dictionary = {"attack": 0, "block": 0, "heal": 0, "penetration": 0, "hits": 0, "status": 0, "skills": [], "counts": counts}
	for symbol: int in BASE_SYMBOLS.keys():
		var count: int = int(counts.get(symbol, 0))
		if count <= 0:
			continue
		var effect: Dictionary = BASE_SYMBOLS[symbol]
		for key: String in effect.keys():
			total[key] = int(total.get(key, 0)) + int(effect[key]) * count

	for skill: Dictionary in SKILLS:
		if _matches(counts, skill.get("requires", {})):
			total["attack"] = int(total["attack"]) + int(skill.get("attack", 0))
			total["block"] = int(total["block"]) + int(skill.get("block", 0))
			total["heal"] = int(total["heal"]) + int(skill.get("heal", 0))
			total["penetration"] = int(total["penetration"]) + int(skill.get("penetration", 0))
			total["hits"] = int(total["hits"]) + int(skill.get("hits", 0))
			total["status"] = int(total["status"]) + int(skill.get("status", 0))
			total["skills"].append(str(skill.get("name", "스킬")))
	return total

static func _matches(counts: Dictionary, requirements: Dictionary) -> bool:
	for symbol in requirements.keys():
		if int(counts.get(symbol, 0)) < int(requirements[symbol]):
			return false
	return true
