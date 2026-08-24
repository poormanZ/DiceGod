class_name CombatContentSystem
extends RefCounted

const ENEMIES: Dictionary = {
	"slime": {"name": "회복 슬라임", "hp": 10, "damage": 1, "weakness": "sword", "trait": "heal_pressure"},
	"golem": {"name": "철갑 골렘", "hp": 14, "damage": 1, "weakness": "wand", "trait": "high_defense"},
	"bat": {"name": "쌍날개 박쥐", "hp": 8, "damage": 2, "weakness": "bow", "trait": "fast"},
	"shade": {"name": "그림자", "hp": 9, "damage": 1, "weakness": "shuriken", "trait": "evasive"}
}

const ELITES: Dictionary = {
	"symbol_hunter": {"name": "심볼 사냥꾼", "hp": 18, "damage": 2, "required": "sword", "trait": "symbol_check"},
	"dice_eater": {"name": "주사위 포식자", "hp": 20, "damage": 2, "required": "shield", "trait": "symbol_check"},
	"arcane_knight": {"name": "비전 기사", "hp": 16, "damage": 3, "required": "wand", "trait": "symbol_check"}
}

# 각 보스는 전용 심볼 하나를 사용합니다. 심볼 효과는 BossSymbolSystem에서 해석합니다.
const BOSSES: Dictionary = {
	"flame_god": {"name": "화염군주", "hp": 28, "damage": 2, "pattern": "burn", "symbol": 101, "gear": "flame_relic"},
	"frost_god": {"name": "빙결왕", "hp": 30, "damage": 2, "pattern": "frost", "symbol": 102, "gear": "frost_relic"},
	"plague_god": {"name": "역병군주", "hp": 29, "damage": 2, "pattern": "plague", "symbol": 103, "gear": "plague_relic"},
	"blood_god": {"name": "혈왕", "hp": 32, "damage": 2, "pattern": "drain", "symbol": 104, "gear": "blood_relic"},
	"storm_god": {"name": "폭풍신", "hp": 31, "damage": 3, "pattern": "storm", "symbol": 105, "gear": "storm_relic"},
	"stone_god": {"name": "거암왕", "hp": 36, "damage": 2, "pattern": "stone", "symbol": 106, "gear": "stone_relic"},
	"fate_god": {"name": "운명의 신", "hp": 30, "damage": 2, "pattern": "fate", "symbol": 107, "gear": "fate_relic"},
	"void_god": {"name": "공허신", "hp": 34, "damage": 3, "pattern": "void", "symbol": 108, "gear": "void_relic"}
}

static func get_normal_enemy(enemy_id: String) -> Dictionary:
	return ENEMIES.get(enemy_id, {})

static func get_elite(elite_id: String) -> Dictionary:
	return ELITES.get(elite_id, {})

static func get_boss(boss_id: String) -> Dictionary:
	return BOSSES.get(boss_id, {})

static func roll_normal_enemy(rng: RandomNumberGenerator) -> Dictionary:
	var ids: Array = ENEMIES.keys()
	return get_normal_enemy(str(ids[rng.randi_range(0, ids.size() - 1)]))

static func roll_elite(rng: RandomNumberGenerator) -> Dictionary:
	var ids: Array = ELITES.keys()
	return get_elite(str(ids[rng.randi_range(0, ids.size() - 1)]))

static func roll_boss(rng: RandomNumberGenerator) -> Dictionary:
	var ids: Array = BOSSES.keys()
	return get_boss(str(ids[rng.randi_range(0, ids.size() - 1)]))
