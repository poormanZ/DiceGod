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

const BOSSES: Dictionary = {
	"gambling_god": {"name": "도박의 신", "hp": 28, "damage": 2, "pattern": "gold", "gear": "gambling_god_coin", "dice": "golden_die"},
	"battle_god": {"name": "전투의 신", "hp": 32, "damage": 3, "pattern": "critical", "gear": "battle_god_blade", "dice": "critical_die"},
	"wisdom_god": {"name": "지혜의 신", "hp": 26, "damage": 2, "pattern": "foresight", "gear": "oracle_die", "dice": "oracle_die"},
	"life_god": {"name": "생명의 신", "hp": 30, "damage": 2, "pattern": "life", "gear": "life_relic", "dice": "life_die"},
	"war_god": {"name": "전쟁의 신", "hp": 36, "damage": 3, "pattern": "berserk", "gear": "war_relic", "dice": "berserk_die"},
	"guardian_god": {"name": "수호의 신", "hp": 38, "damage": 2, "pattern": "sanctuary", "gear": "guardian_relic", "dice": "sanctuary_die"},
	"fate_god": {"name": "운명의 신", "hp": 30, "damage": 2, "pattern": "fate", "gear": "fate_relic", "dice": "fate_die"},
	"death_god": {"name": "죽음의 신", "hp": 34, "damage": 3, "pattern": "death", "gear": "death_relic", "dice": "death_die"}
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
