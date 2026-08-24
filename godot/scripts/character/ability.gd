class_name Ability
extends RefCounted

var ability_data: AbilityData

func _init(initial_ability_data: AbilityData) -> void:
	ability_data = initial_ability_data

func can_use(dice_states: Array[DiceRuntimeState]) -> bool:
	return calculate_bonus(dice_states) > 0

func calculate_bonus(dice_states: Array[DiceRuntimeState]) -> int:
	if ability_data == null:
		return 0

	var result_counts: Dictionary = {}
	for dice_state in dice_states:
		if not dice_state.has_result() or not DiceData.is_attack(dice_state.result):
			continue
		result_counts[dice_state.result] = result_counts.get(dice_state.result, 0) + 1

	var highest_match_count := 0
	for result_count in result_counts.values():
		highest_match_count = maxi(highest_match_count, int(result_count))

	if highest_match_count >= 3:
		return ability_data.matching_triple_bonus
	if highest_match_count >= 2:
		return ability_data.matching_pair_bonus
	return 0
