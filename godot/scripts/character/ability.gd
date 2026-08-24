class_name Ability
extends RefCounted

## 현재 프로토타입에서 사용하는 심볼 조합 스킬 계산기입니다.
var ability_data: AbilityData

func _init(initial_ability_data: AbilityData) -> void:
	ability_data = initial_ability_data if initial_ability_data != null else AbilityData.new()

func can_use(dice_states: Array[DiceRuntimeState]) -> bool:
	return calculate_bonus(dice_states) > 0

func calculate_bonus(dice_states: Array[DiceRuntimeState]) -> int:
	if ability_data == null:
		return 0

	var result_counts: Dictionary = {}
	for dice_state: DiceRuntimeState in dice_states:
		if dice_state == null or not dice_state.has_result() or not DiceData.is_attack(dice_state.result):
			continue
		result_counts[dice_state.result] = int(result_counts.get(dice_state.result, 0)) + 1

	var highest_match_count: int = 0
	for result_count: Variant in result_counts.values():
		highest_match_count = maxi(highest_match_count, int(result_count))

	if highest_match_count >= 3:
		return ability_data.matching_triple_bonus
	if highest_match_count >= 2:
		return ability_data.matching_pair_bonus
	return 0

func get_symbol_counts(dice_states: Array[DiceRuntimeState]) -> Dictionary:
	var counts: Dictionary = {}
	for dice_state: DiceRuntimeState in dice_states:
		if dice_state == null or not dice_state.has_result():
			continue
		counts[dice_state.result] = int(counts.get(dice_state.result, 0)) + 1
	return counts

func get_symbol_count(dice_states: Array[DiceRuntimeState], symbol: int) -> int:
	return int(get_symbol_counts(dice_states).get(symbol, 0))

func get_attack_symbol_count(dice_states: Array[DiceRuntimeState], symbol: int) -> int:
	if not DiceData.is_attack(symbol):
		return 0
	return get_symbol_count(dice_states, symbol)
