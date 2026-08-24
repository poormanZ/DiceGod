class_name DiceRuntimeState
extends RefCounted

## 전투 중 변하는 개별 심볼 주사위의 상태입니다.
var dice_data: DiceData
var result: int = 0
var is_locked: bool = false

func _init(initial_dice_data: DiceData) -> void:
	dice_data = initial_dice_data

func has_result() -> bool:
	return result != 0

func get_symbol() -> String:
	return DiceData.symbol_for(result)

func get_name() -> String:
	return DiceData.name_for(result)

func toggle_lock() -> void:
	if has_result():
		is_locked = not is_locked
