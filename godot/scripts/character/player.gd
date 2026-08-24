class_name Player
extends RefCounted

var player_data: PlayerData
var current_hp: int
var current_shield: int = 0

func _init(initial_player_data: PlayerData) -> void:
	player_data = initial_player_data
	current_hp = player_data.max_hp

func take_damage(damage: int) -> void:
	var incoming: int = maxi(0, damage)
	var absorbed: int = mini(current_shield, incoming)
	current_shield -= absorbed
	current_hp = maxi(0, current_hp - (incoming - absorbed))

func heal(amount: int) -> int:
	var requested: int = maxi(0, amount)
	var before_hp: int = current_hp
	current_hp = mini(player_data.max_hp, current_hp + requested)
	var healed: int = current_hp - before_hp
	var overheal: int = requested - healed
	if overheal > 0:
		add_shield(overheal)
	return healed

func add_shield(amount: int) -> int:
	var added: int = maxi(0, amount)
	current_shield += added
	return added

func get_total_survivability() -> int:
	return current_hp + current_shield
