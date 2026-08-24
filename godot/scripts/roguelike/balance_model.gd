class_name DiceGodBalanceModel
extends RefCounted

const DICE_COUNT: int = 6
const FACES_PER_DIE: int = 6
const BASE_HP: int = 10
const BASE_ENEMY_HP: int = 10
const ATTACK_SYMBOLS_PER_FACE: int = 4
const DEFENSE_SYMBOLS_PER_FACE: int = 1
const HEAL_SYMBOLS_PER_FACE: int = 1

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
