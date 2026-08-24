class_name Player
extends RefCounted

var player_data: PlayerData
var current_hp: int
var current_shield: int = 0

func _init(initial_player_data: PlayerData) -> void:
	player_data = initial_player_data
	current_hp = player_data.max_hp
	current_shield = 0

func take_damage(damage: int) -> void:
	var incoming := maxi(0, damage)
	var absorbed := mini(current_shield, incoming)
	current_shield -= absorbed
	current_hp = maxi(0, current_hp - (incoming - absorbed))

func heal(amount: int) -> int:
	var requested := maxi(0, amount)
	var before_hp := current_hp
	current_hp = mini(player_data.max_hp, current_hp + requested)
	return current_hp - before_hp

func add_shield(amount: int) -> int:
	var added := maxi(0, amount)
	current_shield += added
	return added

func get_total_survivability() -> int:
	return current_hp + current_shield
