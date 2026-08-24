class_name DiceRoller
extends RefCounted

var random_number_generator := RandomNumberGenerator.new()
var has_rerolled: bool = false
var is_result_confirmed: bool = false

func _init() -> void:
	random_number_generator.randomize()

func roll(dice_state: DiceRuntimeState) -> bool:
	if is_result_confirmed or dice_state == null or dice_state.dice_data == null:
		return false
	if not dice_state.dice_data.is_valid():
		return false

	var face_values: PackedInt32Array = dice_state.dice_data.face_values
	if face_values.is_empty():
		return false

	var face_index: int = random_number_generator.randi_range(0, face_values.size() - 1)
	dice_state.result = face_values[face_index]
	return true

func roll_all(dice_states: Array[DiceRuntimeState]) -> bool:
	if is_result_confirmed or dice_states.is_empty():
		return false

	var rolled_any: bool = false
	for dice_state: DiceRuntimeState in dice_states:
		if dice_state == null or dice_state.is_locked:
			continue
		rolled_any = roll(dice_state) or rolled_any
	return rolled_any

func reroll(dice_states: Array[DiceRuntimeState]) -> bool:
	if has_rerolled or is_result_confirmed or dice_states.is_empty():
		return false

	var rerolled_any: bool = false
	for dice_state: DiceRuntimeState in dice_states:
		if dice_state == null or dice_state.is_locked or not dice_state.has_result():
			continue
		rerolled_any = roll(dice_state) or rerolled_any

	if not rerolled_any:
		return false
	has_rerolled = true
	return true

func confirm_results(dice_states: Array[DiceRuntimeState]) -> bool:
	if is_result_confirmed or dice_states.is_empty():
		return false

	for dice_state: DiceRuntimeState in dice_states:
		if dice_state == null or not dice_state.has_result():
			return false

	is_result_confirmed = true
	return true

func reset_turn_state() -> void:
	has_rerolled = false
	is_result_confirmed = false
