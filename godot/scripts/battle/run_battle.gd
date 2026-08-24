class_name RunBattle
extends Battle

## 런 전투 전용 컨트롤러
## 빌드/장비/특수 주사위 없이 6면 심볼 주사위만 사용합니다.

@export var is_boss_battle: bool = false
@export var is_elite_battle: bool = false

var run_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	run_rng.randomize()
	if dice_data == null:
		dice_data = load("res://resources/dice/basic_dice.tres") as DiceData
	if player_data == null:
		player_data = load("res://resources/characters/basic_player.tres") as PlayerData
	enemy_data = _create_run_enemy_data()
	if ability_data == null:
		ability_data = AbilityData.new()

	player = Player.new(player_data)
	player.current_hp = clampi(RunState.current_hp, 1, player.player_data.max_hp)
	enemy = Enemy.new(enemy_data)
	enemy.current_hp = enemy.enemy_data.max_hp
	enemy.plan_next_attack()
	ability = Ability.new(ability_data)

	dice_states.clear()
	is_battle_over = false
	ability_used = false
	for _dice_index in STARTING_DICE_COUNT:
		dice_states.append(DiceRuntimeState.new(dice_data))

	selected_build_label.text = "⚔️ 🏹 🔮 🗡️ 🛡️ ❤️  심볼 주사위"
	player_name_label.text = player.player_data.display_name
	enemy_name_label.text = enemy.enemy_data.display_name
	_update_hp_labels()
	_update_enemy_intent()
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

func _roll_run_dice() -> void:
	for die_index: int in dice_states.size():
		var dice_state: DiceRuntimeState = dice_states[die_index]
		if dice_state.is_locked:
			continue
		if die_index < RunState.run_dice_faces.size():
			var faces: Array = RunState.get_die_faces(die_index)
			if not faces.is_empty():
				dice_state.result = int(faces[run_rng.randi_range(0, faces.size() - 1)])
				continue
		dice_roller.roll(dice_state)

func _on_roll_button_pressed() -> void:
	if is_battle_over:
		return
	_roll_run_dice()
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	dice_roll_panel.set_dice_interaction_enabled(true)
	roll_button.disabled = true
	reroll_button.disabled = false
	confirm_button.disabled = false
	_calculate_actions()
	_show_feedback("🎲 보유 주사위 6개를 굴렸습니다.")

func _on_reroll_button_pressed() -> void:
	if is_battle_over or dice_roller.has_rerolled:
		return
	_roll_run_dice()
	dice_roller.has_rerolled = true
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	reroll_button.disabled = true
	_calculate_actions()
	_show_feedback("↻ 리롤 완료 — 최종 심볼을 확정하세요.")

func _calculate_actions() -> void:
	super._calculate_actions()
	var skills: Dictionary = SymbolSkillSystem.evaluate(dice_states)
	calculated_attack_damage += int(skills.get("attack", 0))
	calculated_block += int(skills.get("block", 0))
	calculated_heal += int(skills.get("heal", 0))

	_update_damage_preview()
	var skill_names: Array = skills.get("skills", [])
	if not skill_names.is_empty():
		status_label.text = "✨ 스킬 발동: %s" % ", ".join(skill_names)

func _handle_victory() -> void:
	is_battle_over = true
	RunState.current_hp = player.current_hp
	RunState.battle_cleared = true
	RunState.reward_claimed = false
	_show_feedback("🏆 전투 승리! 보상을 선택하세요.")
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reward.tscn")

func _handle_defeat() -> void:
	is_battle_over = true
	RunState.current_hp = 0
	RunState.die()
	_show_feedback("💀 사망 — 주사위 하나를 계승할 수 있습니다.")
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reincarnation.tscn")
