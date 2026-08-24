class_name Equipment
extends RefCounted

var equipment_data: EquipmentData

func _init(initial_equipment_data: EquipmentData) -> void:
	equipment_data = initial_equipment_data

## 기존 스트레이트 회피 효과의 호환성을 유지하되,
## 심볼 주사위에서는 방패 3개를 완성한 경우로 재정의합니다.
func can_evade(dice_states: Array[DiceRuntimeState]) -> bool:
	if equipment_data == null or not equipment_data.evades_straight_attacks:
		return false
	if dice_states.size() != 3:
		return false
	for dice_state in dice_states:
		if not dice_state.has_result() or not DiceData.is_defense(dice_state.result):
			return false
	return true
