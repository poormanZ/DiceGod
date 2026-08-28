class_name RunBattle
extends Battle

@export var is_boss_battle: bool = false
@export var is_elite_battle: bool = false

var run_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var boss_symbol_label: String = ""
var calculated_penetration: int = 0
var calculated_hits: int = 0
var calculated_status: int = 0
var run_rerolls_remaining: int = 1

func _ready() -> void:
	run_rng.randomize()
	RunStatusOverlay.attach(self)
	if dice_data == null: dice_data = load("res://resources/dice/basic_dice.tres") as DiceData
	if player_data == null: player_data = load("res://resources/characters/basic_player.tres") as PlayerData
	enemy_data = _create_run_enemy_data()
	if ability_data == null: ability_data = AbilityData.new()
	player = Player.new(player_data)
	player.current_hp = clampi(RunState.current_hp, 1, player.player_data.max_hp)
	enemy = Enemy.new(enemy_data)
	enemy.current_hp = enemy.enemy_data.max_hp
	enemy.plan_next_attack()
	ability = Ability.new(ability_data)
	dice_states.clear()
	is_battle_over = false
	ability_used = false
	for _dice_index: int in DiceData.STARTING_DICE_COUNT:
		dice_states.append(DiceRuntimeState.new(dice_data))
	selected_build_label.text = "심볼 주사위 × %d" % dice_states.size()
	player_name_label.text = player.player_data.display_name
	enemy_name_label.text = enemy.enemy_data.display_name
	_update_hp_labels()
	_update_enemy_intent()
	if is_boss_battle: _show_boss_symbol_status()
	_start_turn("주사위를 자동으로 굴립니다.")

func _create_run_enemy_data() -> EnemyData:
	var basic_dice: DiceData = load("res://resources/dice/basic_dice.tres") as DiceData
	var data: EnemyData = EnemyData.new()
	var source: Dictionary = {}
	var tier: String = "normal"
	if is_boss_battle:
		source = CombatContentSystem.roll_boss(run_rng)
		tier = "boss"
	elif is_elite_battle:
		source = CombatContentSystem.roll_elite(run_rng)
		tier = "elite"
	else: source = CombatContentSystem.roll_normal_enemy(run_rng)
	var run_number: int = maxi(1, RunState.run_number)
	data.display_name = str(source.get("name", "슬라임"))
	data.max_hp = DifficultyScaler.scale_hp(int(source.get("hp", 10)), run_number, tier)
	data.attack_dice = basic_dice
	data.attack_bonus = maxi(0, DifficultyScaler.scale_damage(int(source.get("damage", 1)), run_number, tier) - 3)
	var enemy_trait: String = str(source.get("trait", ""))
	data.armor = 0
	data.status_resistance = 0
	if enemy_trait == "high_defense": data.armor = 2
	elif enemy_trait == "evasive": data.armor = 1
	elif enemy_trait == "heal_pressure": data.status_resistance = 30
	elif enemy_trait == "symbol_check": data.armor = 1
	data.armor = DifficultyScaler.scale_armor(data.armor, run_number, tier)
	if is_boss_battle:
		var boss_id: String = BossRewardSystem.normalize_boss_id(str(source.get("id", "flame_god")))
		if boss_id.is_empty(): boss_id = "flame_god"
		var boss_symbol_id: int = int(source.get("symbol", 0))
		RunState.current_boss_id = boss_id
		data.armor += 1
		data.status_resistance = 25
		data.boss_symbol_id = boss_symbol_id
		data.boss_symbol_effect = BossSymbolSystem.get_effect(boss_symbol_id)
		data.boss_symbol_power = BossSymbolSystem.get_power(boss_symbol_id)
		boss_symbol_label = BossSymbolSystem.get_name(boss_symbol_id)
	return data

func _show_boss_symbol_status() -> void:
	var power: int = enemy.enemy_data.boss_symbol_power
	var description: String = BossSymbolSystem.get_symbol(enemy.enemy_data.boss_symbol_id).get("description", "")
	var message: String = "%s | %s | %s (위력 %d)" % [enemy.enemy_data.display_name, boss_symbol_label, description, power]
	status_label.text = message
	battle_box_label.text = message

func _get_run_reroll_bonus() -> int:
	if RunState.has_method("get_reroll_bonus"):
		return maxi(0, int(RunState.get_reroll_bonus()))
	return 0

func _get_max_run_rerolls() -> int:
	return mini(3, 1 + _get_run_reroll_bonus())

func _start_turn(message: String) -> void:
	dice_roller.reset_turn_state()
	run_rerolls_remaining = _get_max_run_rerolls()
	calculated_attack_damage = 0
	calculated_block = 0
	calculated_heal = 0
	calculated_penetration = 0
	calculated_hits = 0
	calculated_status = 0
	ability_used = false
	is_battle_over = false
	for dice_state: DiceRuntimeState in dice_states:
		dice_state.clear_result()
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.set_dice_interaction_enabled(false)
	roll_button.visible = false
	confirm_button.visible = false
	ability_button.visible = false
	_update_reroll_button()
	attack_button.disabled = true
	status_label.text = message
	_show_feedback(message)
	call_deferred("_auto_roll")

func _auto_roll() -> void:
	if is_battle_over: return
	_roll_run_dice()
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	_calculate_actions()
	_update_reroll_button()
	attack_button.disabled = false
	_show_feedback("자동 ROLL 완료 — REROLL 또는 ATTACK을 선택하세요.")

func _roll_run_dice() -> void:
	for die_index: int in dice_states.size():
		var dice_state: DiceRuntimeState = dice_states[die_index]
		if dice_state == null or dice_state.is_locked: continue
		if die_index < RunState.run_dice_faces.size():
			var faces: Array = RunState.get_die_faces(die_index)
			if not faces.is_empty():
				dice_state.result = int(faces[run_rng.randi_range(0, faces.size() - 1)])
				continue
		dice_roller.roll(dice_state)

func _on_roll_button_pressed() -> void:
	return

func _on_reroll_button_pressed() -> void:
	if is_battle_over or run_rerolls_remaining <= 0: return
	_roll_run_dice()
	run_rerolls_remaining -= 1
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	_calculate_actions()
	_update_reroll_button()
	attack_button.disabled = false
	_show_feedback("REROLL 완료 — 남은 횟수 %d회. REROLL 또는 ATTACK을 선택하세요." % run_rerolls_remaining)

func _update_reroll_button() -> void:
	reroll_button.text = "REROLL × %d" % run_rerolls_remaining
	reroll_button.disabled = run_rerolls_remaining <= 0 or is_battle_over

func _calculate_actions() -> void:
	calculated_attack_damage = RunState.attack_bonus
	calculated_block = 0
	calculated_heal = 0
	calculated_penetration = 0
	calculated_hits = 0
	calculated_status = 0
	var symbols: Dictionary = SymbolSkillSystem.evaluate(dice_states, RunState)
	calculated_attack_damage += int(symbols.get("attack", 0))
	calculated_block += int(symbols.get("block", 0))
	calculated_heal += int(symbols.get("heal", 0))
	calculated_penetration = int(symbols.get("penetration", 0))
	calculated_hits = int(symbols.get("hits", 0))
	calculated_status = int(symbols.get("status", 0))
	var skill_names: Array = symbols.get("skills", [])
	if not skill_names.is_empty():
		status_label.text = "자동 발동: %s" % ", ".join(skill_names)

func _on_confirm_button_pressed() -> void:
	return

func _on_ability_button_pressed() -> void:
	return

func _on_attack_button_pressed() -> void:
	if is_battle_over or not dice_roller.confirm_results(dice_states): return
	_set_action_buttons(true, true)
	dice_roll_panel.set_dice_interaction_enabled(false)
	_calculate_actions()
	_apply_heal()
	_apply_block()
	var damage: int = calculated_attack_damage
	if calculated_hits > 0: damage += calculated_hits
	if calculated_status > 0: damage += calculated_status
	if damage > 0: damage = enemy.take_piercing_damage(damage, calculated_penetration)
	if enemy.current_hp <= 0:
		await _handle_victory()
		return
	var incoming: int = enemy.consume_planned_attack()
	incoming = _apply_boss_symbol_effect(incoming)
	player.take_damage(incoming)
	RunState.current_hp = player.current_hp
	_update_hp_labels()
	_update_enemy_intent()
	if player.current_hp <= 0:
		await _handle_defeat()
		return
	_start_turn("ATTACK %d 피해. 적의 공격을 견뎠습니다." % damage)
	if is_boss_battle: _show_boss_symbol_status()

func _apply_boss_symbol_effect(base_damage: int) -> int:
	if not is_boss_battle or enemy == null or enemy.enemy_data.boss_symbol_id <= 0: return base_damage
	var power: int = enemy.enemy_data.boss_symbol_power
	var effect: String = enemy.enemy_data.boss_symbol_effect
	var incoming: int = base_damage
	match effect:
		"burn": incoming += power
		"frost":
			var lost_shield: int = mini(player.current_shield, power)
			player.current_shield -= lost_shield
		"plague": incoming += power
		"drain": enemy.heal(maxi(1, base_damage / 2))
		"storm": incoming += power
		"stone": enemy.add_temporary_armor(power)
		"fate": incoming = maxi(0, incoming - power)
		"void":
			var bypass: int = mini(player.current_shield, power)
			player.current_shield -= bypass
	return incoming

func _handle_victory() -> void:
	is_battle_over = true
	RunState.current_hp = player.current_hp
	RunState.battle_cleared = true
	if is_boss_battle:
		RunState.boss_cleared = true
		RunState.boss_reward_claimed = false
		RunState.reward_claimed = false
	_show_feedback("%s 격파! 보상을 선택하세요." % enemy.enemy_data.display_name)
	await get_tree().create_timer(0.6).timeout
	if is_boss_battle:
		get_tree().change_scene_to_file("res://scenes/dungeon/divine_reward.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/dungeon/reward.tscn")

func _handle_defeat() -> void:
	is_battle_over = true
	RunState.current_hp = 0
	RunState.die()
	_show_feedback("사망 — 이번 런의 주사위와 강화는 소멸합니다.")
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reincarnation.tscn")

func _set_action_buttons(reroll_disabled: bool, attack_disabled: bool) -> void:
	reroll_button.disabled = reroll_disabled
	attack_button.disabled = attack_disabled
	roll_button.disabled = true
	confirm_button.disabled = true
	ability_button.disabled = true
