class_name RunBattle
extends Battle

var run_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	run_rng.randomize()
	# 기존 전투별 빌드 선택을 제거하고, 현재 런의 심볼 주사위를 즉시 사용한다.
	enemy_data = _create_run_enemy_data()
	player = Player.new(player_data)
	player.current_hp = clampi(RunState.current_hp, 1, player.player_data.max_hp)
	enemy = Enemy.new(enemy_data)
	enemy.current_hp = enemy.enemy_data.max_hp
	enemy.plan_next_attack()
	ability = Ability.new(ability_data)
	equipment = Equipment.new(equipment_data)
	dice_states.clear()
	is_battle_over = false
	calculated_attack_damage = 0
	calculated_block = 0
	calculated_heal = 0
	calculated_special_bonus = 0
	calculated_penetration = 0
	calculated_extra_hits = 0
	calculated_magic_bonus = 0
	calculated_status_damage = 0
	calculated_shield = 0
	effects_applied = false
	player_name_label.text = player.player_data.display_name
	enemy_name_label.text = enemy.enemy_data.display_name
	_update_player_hp_label()
	enemy_hp_label.text = "HP %d / %d" % [enemy.current_hp, enemy.enemy_data.max_hp]
	_update_enemy_intent_display()
	selected_build_label.text = "✨ 심볼 주사위"
	_set_action_buttons_for_build(null)
	for _dice_index in STARTING_DICE_COUNT:
		dice_states.append(DiceRuntimeState.new(dice_data))
	restart_build_button.hide()
	_start_turn("✨ 심볼 주사위 전투를 시작합니다. 6개의 주사위를 굴려 행동 심볼을 만드세요.")

func _create_run_enemy_data() -> EnemyData:
	var basic_dice: DiceData = load("res://resources/dice/basic_dice.tres") as DiceData
	var data: EnemyData = EnemyData.new()
	var source: Dictionary = {}
	if is_boss_battle:
		source = CombatContentSystem.roll_boss(run_rng)
	elif is_elite_battle:
		source = CombatContentSystem.roll_elite(run_rng)
	else:
		source = CombatContentSystem.roll_normal_enemy(run_rng)

	data.display_name = str(source.get("name", "슬라임"))
	data.max_hp = int(source.get("hp", 10))
	data.attack_dice = basic_dice
	var enemy_trait: String = str(source.get("trait", ""))
	data.armor = 0
	data.status_resistance = 0
	if enemy_trait == "high_defense":
		data.armor = 2
	elif enemy_trait == "evasive":
		data.armor = 1
	elif enemy_trait == "heal_pressure":
		data.status_resistance = 30
	elif enemy_trait == "symbol_check":
		data.armor = 1
	if is_boss_battle:
		data.armor += 1
		data.status_resistance = 25
	return data

func _on_roll_button_pressed() -> void:
	if is_battle_over:
		return
	for die_index: int in dice_states.size():
		var dice_state: DiceRuntimeState = dice_states[die_index]
		if die_index < RunState.run_dice_faces.size():
			var faces: Array = RunState.get_die_faces(die_index)
			if not faces.is_empty():
				dice_state.result = int(faces[run_rng.randi_range(0, faces.size() - 1)])
				continue
		dice_roller.roll(dice_state)
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	dice_roll_panel.set_dice_interaction_enabled(true)
	roll_button.disabled = true
	reroll_button.disabled = false
	confirm_button.disabled = false
	ability_button.disabled = true
	attack_button.disabled = true
	_calculate_actions()
	_update_damage_preview()
	status_label.text = "심볼을 잠그거나 리롤할 수 있습니다."
	_show_combat_feedback("🎲 보유 주사위 6개를 굴렸습니다.")

func _on_reroll_button_pressed() -> void:
	if dice_roller.has_rerolled:
		return
	for die_index: int in dice_states.size():
		var dice_state: DiceRuntimeState = dice_states[die_index]
		if dice_state.is_locked or die_index >= RunState.run_dice_faces.size():
			continue
		var faces: Array = RunState.get_die_faces(die_index)
		if not faces.is_empty():
			dice_state.result = int(faces[run_rng.randi_range(0, faces.size() - 1)])
	dice_roller.has_rerolled = true
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	reroll_button.disabled = true
	_calculate_actions()
	_update_damage_preview()
	status_label.text = "리롤을 사용했습니다. 최종 심볼을 확정하세요."
	_show_combat_feedback("↻ 리롤 완료")

func _calculate_actions() -> void:
	super._calculate_actions()
	var skills: Dictionary = SymbolSkillSystem.evaluate(dice_states)
	calculated_attack_damage += int(skills.get("attack", 0))
	calculated_block += int(skills.get("block", 0))
	calculated_heal += int(skills.get("heal", 0))
	calculated_penetration += int(skills.get("penetration", 0))
	calculated_extra_hits += int(skills.get("hits", 0))
	calculated_status_damage += int(skills.get("status", 0))

	var critical_count: int = _count_result(DiceData.DIVINE_CRITICAL)
	var berserk_count: int = _count_result(DiceData.DIVINE_BERSERK)
	var sanctuary_count: int = _count_result(DiceData.DIVINE_SANCTUARY)
	var life_count: int = _count_result(DiceData.DIVINE_LIFE)
	var death_count: int = _count_result(DiceData.DIVINE_DEATH)

	if critical_count > 0:
		calculated_attack_damage *= 2
	if berserk_count > 0 and player != null and player.current_hp * 100 <= player.player_data.max_hp * 30:
		calculated_attack_damage = int(ceil(float(calculated_attack_damage) * 1.5))
	if death_count > 0 and enemy != null and enemy.current_hp * 100 <= enemy.enemy_data.max_hp * 20:
		calculated_attack_damage *= 2
	if sanctuary_count > 0:
		calculated_shield += sanctuary_count
	if life_count > 0:
		calculated_heal += life_count

	var critical_bonus: int = RoguelikeEquipmentSystem.bonus(RunState, "critical")
	var heavy_bonus: int = RoguelikeEquipmentSystem.bonus(RunState, "heavy")
	var block_bonus: int = RoguelikeEquipmentSystem.bonus(RunState, "block")
	if critical_bonus > 0:
		calculated_attack_damage += critical_bonus
	if heavy_bonus > 0:
		calculated_special_bonus += heavy_bonus
		calculated_attack_damage += heavy_bonus
	if block_bonus > 0:
		calculated_block += block_bonus

	_update_damage_preview()
	var skill_names: Array = skills.get("skills", [])
	if not skill_names.is_empty():
		status_label.text = "✨ 스킬 발동: %s" % ", ".join(skill_names)

func _count_result(symbol_id: int) -> int:
	var count: int = 0
	for dice_state: DiceRuntimeState in dice_states:
		if dice_state != null and dice_state.result == symbol_id:
			count += 1
	return count

func _handle_victory() -> void:
	is_battle_over = true
	RunState.current_hp = player.current_hp
	RunState.battle_cleared = true
	RunState.reward_claimed = false
	_show_combat_feedback("🏆 일반 전투 승리! 골드 보상을 선택하세요.")
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reward.tscn")

func _handle_defeat() -> void:
	is_battle_over = true
	RunState.current_hp = 0
	RunState.die()
	_show_combat_feedback("💀 사망 — 주사위 하나를 계승할 수 있습니다.")
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reincarnation.tscn")
