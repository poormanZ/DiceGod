class_name DiceGodBalanceModel
extends RefCounted

const DICE_COUNT: int = 6
const FACES_PER_DIE: int = 6
const BASE_HP: int = 10
const BASE_ENEMY_HP: int = 10
const ATTACK_SYMBOLS_PER_FACE: int = 4
const DEFENSE_SYMBOLS_PER_FACE: int = 1
const HEAL_SYMBOLS_PER_FACE: int = 1

const NORMAL_GOLD_AVERAGE: float = 40.0
const ELITE_GOLD_AVERAGE: float = 96.6667
const SHOP_DICE_COST: int = 80
const SHOP_GEAR_COSTS: Array[int] = [100, 120, 140]
const FORGE_COST: int = 35

static func expected_symbol_count(symbol_probability: float = 1.0 / 6.0) -> float:
	return float(DICE_COUNT) * symbol_probability

static func expected_basic_attack() -> float:
	return float(DICE_COUNT * ATTACK_SYMBOLS_PER_FACE) / float(FACES_PER_DIE)

static func expected_basic_defense() -> float:
	return float(DICE_COUNT * DEFENSE_SYMBOLS_PER_FACE) / float(FACES_PER_DIE)

static func expected_basic_heal() -> float:
	return float(DICE_COUNT * HEAL_SYMBOLS_PER_FACE) / float(FACES_PER_DIE)

static func estimate_enemy_turns(enemy_hp: int = BASE_ENEMY_HP, damage_per_attack_symbol: float = 1.0) -> float:
	var damage: float = expected_basic_attack() * damage_per_attack_symbol
	if damage <= 0.0:
		return 99.0
	return float(enemy_hp) / damage

static func evaluate() -> Dictionary:
	var turns: float = estimate_enemy_turns()
	return {
		"dice": DICE_COUNT,
		"faces": FACES_PER_DIE,
		"player_hp": BASE_HP,
		"enemy_hp": BASE_ENEMY_HP,
		"expected_attack_symbols": expected_basic_attack(),
		"expected_defense_symbols": expected_basic_defense(),
		"expected_heal_symbols": expected_basic_heal(),
		"estimated_turns": turns,
		"target_turns": "2~4",
		"within_target": turns >= 2.0 and turns <= 4.0
	}

static func evaluate_divine_symbol_multiplier(multiplier: float) -> Dictionary:
	var base: float = expected_basic_attack()
	var boosted: float = base * maxf(0.0, multiplier)
	return {"base": base, "boosted": boosted, "multiplier": multiplier}

static func evaluate_builds() -> Dictionary:
	return {
		"attack": {"attack": expected_basic_attack(), "survival": expected_basic_defense() * BASE_HP},
		"defense": {"attack": expected_basic_attack() * 0.75, "survival": expected_basic_defense() * 1.5 * BASE_HP},
		"heal": {"attack": expected_basic_attack() * 0.75, "survival": (expected_basic_defense() + expected_basic_heal()) * BASE_HP},
		"gold": {"attack": expected_basic_attack(), "survival": expected_basic_defense() * BASE_HP, "economy": 1.0},
		"critical": {"attack": expected_basic_attack() * 1.5, "survival": expected_basic_defense() * BASE_HP},
		"divine_two_faces": {"attack": expected_basic_attack() * 1.35, "survival": expected_basic_defense() * BASE_HP}
	}

## 대표적인 6면 결과를 시뮬레이션해 시너지의 공격/생존 편차를 빠르게 검증합니다.
static func evaluate_synergy_profiles() -> Dictionary:
	var profiles: Dictionary = {
		"balanced": {1:1, 2:1, 3:1, 4:1, 5:1, 6:1},
		"attack": {1:3, 2:1, 4:1, 5:1},
		"defense": {1:1, 5:3, 6:2},
		"heal": {3:1, 5:1, 6:4},
		"crit_chain": {1:1, 2:2, 4:2, 5:1},
		"spell": {2:1, 3:3, 6:2}
	}
	var result: Dictionary = {}
	for profile_name: String in profiles.keys():
		var counts: Dictionary = profiles[profile_name]
		var active_tags: Array[String] = []
		for synergy: Dictionary in SymbolSkillSystem.PAIR_SYNERGIES:
			var requirements: Dictionary = synergy.get("requires", {})
			var matched: bool = true
			for symbol in requirements.keys():
				if int(counts.get(symbol, 0)) < int(requirements[symbol]):
					matched = false
					break
			if matched:
				var tag: String = str(synergy.get("gear", ""))
				if not tag.is_empty() and not active_tags.has(tag): active_tags.append(tag)
		var evaluated: Dictionary = SymbolSkillSystem.evaluate_counts(counts, active_tags)
		result[profile_name] = {
			"attack": int(evaluated.get("attack", 0)),
			"block": int(evaluated.get("block", 0)),
			"heal": int(evaluated.get("heal", 0)),
			"penetration": int(evaluated.get("penetration", 0)),
			"hits": int(evaluated.get("hits", 0)),
			"status": int(evaluated.get("status", 0)),
			"synergy_count": evaluated.get("synergies", []).size()
		}
	return result

## 상점/대장간 가격이 한 런의 보상 흐름을 과도하게 압박하지 않는지 확인합니다.
static func evaluate_economy() -> Dictionary:
	var first_shop_purchase: float = NORMAL_GOLD_AVERAGE * 2.0
	var forge_affordability: float = NORMAL_GOLD_AVERAGE / float(FORGE_COST)
	var gear_cost_average: float = 0.0
	for cost in SHOP_GEAR_COSTS:
		gear_cost_average += float(cost)
	gear_cost_average /= float(SHOP_GEAR_COSTS.size())
	return {
		"normal_gold_average": NORMAL_GOLD_AVERAGE,
		"elite_gold_average": ELITE_GOLD_AVERAGE,
		"two_normal_fights_gold": first_shop_purchase,
		"forge_cost": FORGE_COST,
		"forge_uses_per_two_normal_fights": forge_affordability,
		"shop_dice_cost": SHOP_DICE_COST,
		"shop_gear_average_cost": gear_cost_average,
		"economy_warning": first_shop_purchase < float(SHOP_DICE_COST) or forge_affordability < 1.0
	}

## 보스별 체력/공격 압력 차이를 수치화해 전용 패턴이 의미 있는지 검증합니다.
static func evaluate_boss_profiles() -> Dictionary:
	var result: Dictionary = {}
	for boss_id in CombatContentSystem.BOSSES.keys():
		var boss: Dictionary = CombatContentSystem.BOSSES[boss_id]
		var hp: int = int(boss.get("hp", 0))
		var damage: int = int(boss.get("damage", 0))
		var expected_turns: float = float(hp) / maxf(expected_basic_attack(), 0.1)
		result[str(boss_id)] = {
			"hp": hp,
			"damage": damage,
			"pattern": str(boss.get("pattern", "")),
			"expected_player_attack_turns": expected_turns,
			"pressure": float(damage) + (float(hp) / 10.0)
		}
	return result
