class_name BossRunBattle
extends RunBattle

var boss_turn: int = 0
var boss_attack_reduction: int = 0

func _ready() -> void:
	boss_turn = 0
	boss_attack_reduction = 0
	super._ready()

func _calculate_actions() -> void:
	super._calculate_actions()
	if boss_attack_reduction > 0:
		var reduction: int = mini(boss_attack_reduction, calculated_attack_damage)
		calculated_attack_damage = maxi(0, calculated_attack_damage - reduction)
		active_synergy_messages.append("운명 고정 -%d" % reduction)
		boss_attack_reduction = 0

func _update_enemy_intent() -> void:
	if enemy == null or enemy_hint_label == null: return
	var pattern: Dictionary = BossPatternSystem.preview(RunState.current_boss_id, boss_turn)
	var damage: int = int(pattern.get("damage", 0))
	var pattern_type: String = str(pattern.get("type", "attack"))
	var intent: String = str(pattern.get("telegraph", "보스가 행동을 준비합니다."))
	if pattern_type == "multi":
		damage *= int(pattern.get("hits", 1))
	enemy_hint_label.text = "%s · %d 피해 | %s" % [str(pattern.get("name", "보스 행동")), damage, intent]
	status_label.text = "보스 예고: %s" % intent

func _on_attack_button_pressed() -> void:
	if is_battle_over or not dice_roller.confirm_results(dice_states): return
	_set_action_buttons(true, true, true, true, true)
	dice_roll_panel.set_dice_interaction_enabled(false)
	_calculate_actions()
	_apply_heal()
	_apply_block()
	var damage: int = calculated_attack_damage
	if calculated_hits > 0: damage += calculated_hits
	if calculated_status > 0: damage += calculated_status
	if damage > 0:
		damage = enemy.take_piercing_damage(damage, calculated_penetration)
	if enemy.current_hp <= 0:
		await _handle_victory()
		return

	var pattern_result: Dictionary = BossPatternSystem.execute(
		RunState.current_boss_id,
		boss_turn,
		player.current_hp,
		player.current_shield
	)
	_apply_boss_pattern_result(pattern_result)
	boss_turn += 1
	RunState.current_hp = player.current_hp
	_update_hp_labels()
	_update_enemy_intent()
	if player.current_hp <= 0:
		await _handle_defeat()
		return
	_start_turn("%s | %d 피해를 주고 보스의 행동을 견뎠습니다." % [str(pattern_result.get("pattern_id", "보스 행동")), damage])
	_update_enemy_intent()

func _apply_boss_pattern_result(result: Dictionary) -> void:
	var shield_damage: int = maxi(0, int(result.get("shield_damage", 0)))
	var hp_damage: int = maxi(0, int(result.get("hp_damage", 0)))
	if shield_damage > 0:
		player.current_shield = maxi(0, player.current_shield - shield_damage)
	if hp_damage > 0:
		player.take_damage(hp_damage)
	var heal_amount: int = maxi(0, int(result.get("heal", 0)))
	if heal_amount > 0:
		enemy.heal(heal_amount)
	var armor: int = maxi(0, int(result.get("armor", 0)))
	if armor > 0:
		enemy.add_temporary_armor(armor)
	boss_attack_reduction = maxi(0, int(result.get("reduce_damage", 0)))
	var status: String = str(result.get("status", ""))
	var status_power: int = maxi(0, int(result.get("status_power", 0)))
	if status != "" and status_power > 0:
		# 현재 런에서는 지속 상태를 즉시 피해로 환산해 단순하고 명확하게 피드백합니다.
		player.take_damage(status_power)
		_show_feedback("보스 상태이상: %s +%d" % [status, status_power])

func _handle_victory() -> void:
	is_battle_over = true
	RunState.current_hp = player.current_hp
	var boss_id: String = BossRewardSystem.boss_id_from_display_name(enemy.enemy_data.display_name)
	if boss_id.is_empty():
		boss_id = RunState.current_boss_id
	if boss_id.is_empty():
		boss_id = "battle_god"
	RunState.current_boss_id = boss_id
	DivineRewardSystem.unlock_boss_symbol(RunState, boss_id)
	RunState.boss_cleared = true
	RunState.persist_completed_run_dice()
	_show_feedback("👑 %s 처치! 신성 심볼과 특수 보상을 선택하세요." % enemy.enemy_data.display_name)
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/divine_reward.tscn")

func _handle_defeat() -> void:
	is_battle_over = true
	RunState.current_hp = 0
	RunState.die()
	_show_feedback("💀 보스에게 패배했습니다. 주사위 하나를 계승하세요.")
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reincarnation.tscn")
