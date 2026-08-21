class_name Equipment
extends RefCounted

var equipment_data: EquipmentData


func _init(initial_equipment_data: EquipmentData) -> void:
	equipment_data = initial_equipment_data


func can_evade(dice_states: Array[DiceRuntimeState]) -> bool:
	if equipment_data == null:
		return false
	if not equipment_data.evades_straight_attacks or dice_states.size() != 3:
		return false

	var values: Array[int] = []
	for dice_state in dice_states:
		if not dice_state.has_result():
			return false
		values.append(dice_state.result)
	values.sort()
	return values == [1, 2, 3] or values == [2, 3, 4] or values == [3, 4, 5]
