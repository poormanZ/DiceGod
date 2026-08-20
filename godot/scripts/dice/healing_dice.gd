class_name HealingDice
extends RefCounted

var dice_data: HealingDiceData
var runtime_state: DiceRuntimeState
var dice_roller := DiceRoller.new()


func _init(initial_dice_data: HealingDiceData) -> void:
	dice_data = initial_dice_data
	runtime_state = DiceRuntimeState.new(dice_data)


func roll() -> bool:
	dice_roller.reset_turn_state()
	return dice_roller.roll(runtime_state)


func get_healing_amount() -> int:
	if not dice_data.heals_player or not runtime_state.has_result():
		return 0
	return runtime_state.result
