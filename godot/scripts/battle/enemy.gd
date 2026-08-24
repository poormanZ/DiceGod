class_name Enemy
extends RefCounted

var enemy_data: EnemyData
var current_hp: int
var current_statuses: Dictionary = {}
var attack_dice_state: DiceRuntimeState
var dice_roller := DiceRoller.new()
var planned_attack_damage: int = 0

func _init(initial_enemy_data: EnemyData) -> void:
	enemy_data = initial_enemy_data
	current_hp = enemy_data.max_hp
	attack_dice_state = DiceRuntimeState.new(enemy_data.attack_dice)
	_refresh_attack_intent()

func take_damage(damage: int) -> void:
	current_hp = maxi(0, current_hp - maxi(0, damage))

func take_piercing_damage(damage: int, penetration: int) -> int:
	var effective_armor := maxi(0, enemy_data.armor - maxi(0, penetration))
	var final_damage := maxi(0, damage - effective_armor)
	take_damage(final_damage)
	return final_damage

func apply_status(status_name: String, turns: int, power: int) -> bool:
	if enemy_data.status_resistance >= 100:
		return false
	var duration := maxi(1, turns)
	current_statuses[status_name] = {
		"turns": duration,
		"power": maxi(0, power),
	}
	return true

func has_status(status_name: String) -> bool:
	return current_statuses.has(status_name)

func tick_statuses() -> Dictionary:
	var effects: Dictionary = {}
	for status_name in current_statuses.keys():
		var status: Dictionary = current_statuses[status_name]
		var power := int(status.get("power", 0))
		var turns := int(status.get("turns", 0))
		if status_name == "burn" and power > 0:
			effects[status_name] = power
		turns -= 1
		if turns <= 0:
			current_statuses.erase(status_name)
		else:
			status["turns"] = turns
			current_statuses[status_name] = status
	return effects

func _roll_attack_preview() -> int:
	var preview_state := DiceRuntimeState.new(enemy_data.attack_dice)
	var preview_roller := DiceRoller.new()
	preview_roller.reset_turn_state()
	preview_roller.roll(preview_state)
	return maxi(0, preview_state.result)

func _refresh_attack_intent() -> void:
	planned_attack_damage = _roll_attack_preview()

func get_attack_intent() -> int:
	return planned_attack_damage

func roll_attack_damage() -> int:
	# 표시된 공격 의도를 실제 공격으로 확정하여 플레이어가 예측 가능한 전투를 만듭니다.
	var damage := planned_attack_damage
	_refresh_attack_intent()
	return damage
