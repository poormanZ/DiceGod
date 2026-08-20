class_name Player
extends RefCounted

var player_data: PlayerData
var current_hp: int


func _init(initial_player_data: PlayerData) -> void:
	player_data = initial_player_data
	current_hp = player_data.max_hp


func take_damage(damage: int) -> void:
	current_hp = maxi(0, current_hp - damage)


func heal(amount: int) -> void:
	current_hp = mini(player_data.max_hp, current_hp + maxi(0, amount))
