class_name Enemy
extends RefCounted

var enemy_data: EnemyData
var current_hp: int
var attack_dice_state: DiceRuntimeState
var dice_roller := DiceRoller.new()


func _init(initial_enemy_data: EnemyData) -> void:
	enemy_data = initial_enemy_data
	current_hp = enemy_data.max_hp
	attack_dice_state = DiceRuntimeState.new(enemy_data.attack_dice)


func take_damage(damage: int) -> void:
	current_hp = maxi(0, current_hp - damage)


func roll_attack_damage() -> int:
	dice_roller.reset_turn_state()
	dice_roller.roll(attack_dice_state)
	return attack_dice_state.result
