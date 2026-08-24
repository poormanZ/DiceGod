class_name DiceGodBalanceModel
extends RefCounted

const DICE_COUNT: int = 6
const FACES_PER_DIE: int = 6
const BASE_HP: int = 10
const BASE_ENEMY_HP: int = 10

static func expected_symbol_count(symbol_probability: float = 1.0 / 6.0) -> float:
	return float(DICE_COUNT * FACES_PER_DIE) * symbol_probability

static func expected_basic_attack() -> float:
	return expected_symbol_count()

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
		"estimated_turns": turns,
		"target_turns": "2~4",
		"within_target": turns >= 2.0 and turns <= 4.0
	}

static func evaluate_divine_symbol_multiplier(multiplier: float) -> Dictionary:
	var base: float = expected_basic_attack()
	var boosted: float = base * maxf(0.0, multiplier)
	return {"base": base, "boosted": boosted, "multiplier": multiplier}
