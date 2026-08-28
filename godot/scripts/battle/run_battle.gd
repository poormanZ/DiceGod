class_name RunBattle
extends Battle

@export var is_boss_battle: bool = false
@export var is_elite_battle: bool = false

var run_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var boss_symbol_label: String = ""
var calculated_penetration: int = 0
var calculated_hits: int = 0
var calculated_status: int = 0

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
	for _dice_index: int in DiceData.STARTING_DICE_COUNT: dice_states.append(DiceRuntimeState.new(dice_data))
	selected_build_label.text = "심볼 주사위 × %d" % dice_states.size()
	player_name_label.text = player.player_data.display_name
	enemy_name_label.text = enemy.enemy_data.display_name
	_update_hp_labels()
	_update_enemy_intent()
	if is_boss_battle: _show_boss_symbol_status()
	else: _start_turn("6개의 주사위를 굴려 행동 심볼을 만드세요.")

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

func _roll_run_dice() -> void:
	for die_index: int in dice_states.size():
		var dice_state: DiceRuntimeState = dice_states[die_index]
		if dice_state.is_locked: continue
		if die_index < RunState.run_dice_faces.size():
			var faces: Array = RunState.get_die_faces(die_index)
			if not faces.is_empty():
				dice_state.result = int(faces[run_rng.randi_range(0, faces.size() - 1)])
				continue
		dice_roller.roll(dice_state)

func _on_roll_button_pressed() -> void:
	if is_battle_over: return
	_roll_run_dice()
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	dice_roll_panel.set_dice_interaction_enabled(true)
	roll_button.disabled = true
	reroll_button.disabled = false
	confirm_button.disabled = false
	_calculate_actions()
	_show_feedback("보유 주사위 6개를 굴렸습니다.")

func _on_reroll_button_pressed() -> void:
	if is_battle_over or dice_roller.has_rerolled: return
	_roll_run_dice()
	dice_roller.has_rerolled = true
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	reroll_button.disabled = true
	_calculate_actions()
	_show_feedback("리롤 완료 — 최종 심볼을 확정하세요.")

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
	if not skill_names.is_empty(): status_label.text = "자동 발동: %s" % ", ".join(skill_names)

func _on_attack_button_pressed() -> void:
	if is_battle_over: return
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
	_start_turn("공격 %d 피해 | 관통 %d | 추가 효과 %d" % [damage, calculated_penetration, calculated_status])
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
	if is_boss_battle: get_tree().change_scene_to_file("res://scenes/dungeon/divine_reward.tscn")
	else: get_tree().change_scene_to_file("res://scenes/dungeon/reward.tscn")

func _handle_defeat() -> void:
	is_battle_over = true
	RunState.current_hp = 0
	RunState.die()
	_show_feedback("사망 — 이번 런의 주사위와 강화는 소멸합니다.")
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reincarnation.tscn")
