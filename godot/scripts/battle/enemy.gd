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
	_update_intent_display()

func get_attack_intent() -> int:
	return planned_attack_damage

func _update_intent_display() -> void:
	# 별도의 씬 수정 없이 기존 EnemyHint 라벨을 적 공격 의도 표시로 사용합니다.
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return
	var tree := main_loop as SceneTree
	var current_scene := tree.current_scene
	if current_scene == null:
		return
	var intent_label := current_scene.get_node_or_null("MarginContainer/Content/EnemyArea/EnemyHint") as Label
	if intent_label == null:
		return
	if planned_attack_damage > 0:
		intent_label.text = "⚠️ 다음 공격: ⚔️ %d 피해" % planned_attack_damage
		intent_label.modulate = Color(1.0, 0.55, 0.45, 1.0)
	else:
		intent_label.text = "⚠️ 다음 공격: 0 피해"
		intent_label.modulate = Color(0.65, 0.65, 0.7, 1.0)

func roll_attack_damage() -> int:
	# 표시된 공격 의도를 실제 공격으로 확정합니다.
	var damage: int = planned_attack_damage
	_refresh_attack_intent()
	return damage

func consume_planned_attack() -> int:
	# 전투에서 표시된 적 공격 의도를 실제 피해량으로 소비합니다.
	var damage: int = planned_attack_damage
	_refresh_attack_intent()
	return damage
