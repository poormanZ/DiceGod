class_name BossPatternSystem
extends RefCounted

## 보스별 행동 패턴을 한 곳에서 정의합니다.
## UI는 preview()를, 전투는 execute()를 사용해 동일한 패턴 데이터를 공유합니다.

const PATTERNS: Dictionary = {
	"flame_god": [
		{"id": "flame_burst", "name": "화염 폭발", "type": "attack", "damage": 3, "status": "burn", "status_power": 2, "telegraph": "화염이 모입니다. 다음 턴 3 피해 + 화상 2"},
		{"id": "ember", "name": "잔불", "type": "attack", "damage": 2, "status": "burn", "status_power": 1, "telegraph": "약한 화염 공격"}
	],
	"frost_god": [
		{"id": "ice_prison", "name": "빙결 감옥", "type": "attack", "damage": 2, "status": "frost", "status_power": 2, "telegraph": "보호막이 크게 약화됩니다."},
		{"id": "cold_strike", "name": "빙점 강타", "type": "attack", "damage": 3, "status": "frost", "status_power": 1, "telegraph": "보호막을 약화시키는 강타"}
	],
	"plague_god": [
		{"id": "plague_cloud", "name": "역병 구름", "type": "attack", "damage": 2, "status": "plague", "status_power": 2, "telegraph": "역병 표식이 누적됩니다."},
		{"id": "infect", "name": "감염", "type": "attack", "damage": 1, "status": "plague", "status_power": 3, "telegraph": "낮은 피해 대신 강한 지속 피해"}
	],
	"blood_god": [
		{"id": "blood_fang", "name": "혈조", "type": "drain", "damage": 3, "heal": 2, "telegraph": "피해와 동시에 보스가 회복합니다."},
		{"id": "blood_feast", "name": "혈연회", "type": "drain", "damage": 2, "heal": 4, "telegraph": "큰 회복을 동반한 공격"}
	],
	"storm_god": [
		{"id": "chain_lightning", "name": "연쇄 번개", "type": "multi", "damage": 2, "hits": 2, "telegraph": "2회 연속 공격"},
		{"id": "thunder", "name": "천둥", "type": "attack", "damage": 5, "telegraph": "강력한 단일 공격"}
	],
	"stone_god": [
		{"id": "fortify", "name": "철벽", "type": "buff", "armor": 2, "telegraph": "다음 공격 전 방어력 +2"},
		{"id": "stone_crush", "name": "거암 분쇄", "type": "attack", "damage": 4, "telegraph": "느리지만 강력한 공격"}
	],
	"fate_god": [
		{"id": "doom", "name": "운명 고정", "type": "debuff", "damage": 2, "reduce_damage": 2, "telegraph": "플레이어의 다음 공격 피해 -2"},
		{"id": "fateful_strike", "name": "숙명의 일격", "type": "attack", "damage": 4, "telegraph": "피할 수 없는 강타"}
	],
	"void_god": [
		{"id": "void_rend", "name": "공허 절단", "type": "pierce", "damage": 3, "shield_ignore": 2, "telegraph": "보호막 2를 무시합니다."},
		{"id": "null", "name": "무효화", "type": "pierce", "damage": 2, "shield_ignore": 4, "telegraph": "보호막 대부분을 무시합니다."}
	]
}

static func get_patterns(boss_id: String) -> Array:
	return PATTERNS.get(boss_id, []).duplicate(true)

static func get_pattern(boss_id: String, turn: int) -> Dictionary:
	var patterns: Array = get_patterns(boss_id)
	if patterns.is_empty():
		return {}
	return patterns[turn % patterns.size()].duplicate(true)

static func preview(boss_id: String, turn: int) -> Dictionary:
	var pattern: Dictionary = get_pattern(boss_id, turn)
	if pattern.is_empty():
		return {"name": "기본 공격", "telegraph": "보스가 공격합니다."}
	return pattern

static func execute(boss_id: String, turn: int, player_hp: int, player_shield: int) -> Dictionary:
	var pattern: Dictionary = get_pattern(boss_id, turn)
	if pattern.is_empty():
		return {"damage": 1, "shield_damage": min(player_shield, 1), "hp_damage": max(0, 1 - player_shield), "heal": 0, "status": ""}
	var damage: int = int(pattern.get("damage", 0))
	var shield_ignore: int = int(pattern.get("shield_ignore", 0))
	var shield_damage: int = min(player_shield, max(0, damage - shield_ignore))
	var hp_damage: int = max(0, damage - shield_damage)
	if shield_ignore > 0:
		var ignored: int = min(shield_ignore, damage)
		hp_damage += ignored
		shield_damage = min(player_shield, damage - ignored)
	if pattern.get("type", "") == "multi":
		var hits: int = int(pattern.get("hits", 1))
		damage *= hits
		shield_damage = min(player_shield, damage)
		hp_damage = max(0, damage - shield_damage)
	return {"damage": damage, "shield_damage": shield_damage, "hp_damage": hp_damage, "heal": int(pattern.get("heal", 0)), "status": str(pattern.get("status", "")), "status_power": int(pattern.get("status_power", 0)), "reduce_damage": int(pattern.get("reduce_damage", 0)), "armor": int(pattern.get("armor", 0)), "pattern_id": str(pattern.get("id", ""))}
