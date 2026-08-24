class_name RunBattle
extends Battle

## 런 전투 전용 컨트롤러
## 6면 심볼 주사위를 사용하며, 런 횟수에 따라 적이 강해집니다.
## 보스 전투에서는 보스별 전용 심볼 효과가 실제 전투에 적용됩니다.

@export var is_boss_battle: bool = false
@export var is_elite_battle: bool = false

var run_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var boss_symbol_label: String = ""

func _ready() -> void:
	run_rng.randomize()
	RunStatusOverlay.attach(self)
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
	for _dice_index in DiceData.STARTING_DICE_COUNT:
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
	var tier: String = "normal"
	if is_boss_battle:
		source = CombatContentSystem.roll_boss(run_rng)
		tier = "boss"
	elif is_elite_battle:
		source = CombatContentSystem.roll_elite(run_rng)
		tier = "elite"
	else:
		source = CombatContentSystem.roll_normal_enemy(run_rng)

	var run_number: int = maxi(1, RunState.run_number)
	data.display_name = str(source.get("name", "슬라임"))
	data.max_hp = DifficultyScaler.scale_hp(int(source.get("hp", 10)), run_number, tier)
	data.attack_dice = basic_dice
	var scaled_damage: int = DifficultyScaler.scale_damage(int(source.get("damage", 1)), run_number, tier)
	data.attack_bonus = maxi(0, scaled_damage - 3)
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
	data.armor = DifficultyScaler.scale_armor(data.armor, run_number, tier)

	if is_boss_battle:
		RunState.current_boss_id = str(source.get("name", ""))
		data.armor += 1
		data.status_resistance = 25
		data.boss_symbol_id = int(source.get("symbol", 0))
		data.boss_symbol_effect = BossSymbolSystem.get_effect(data.boss_symbol_id)
		data.boss_symbol_power = BossSymbolSystem.get_power(data.boss_symbol_id)
		boss_symbol_label = "%s %s" % [BossSymbolSystem.get_icon(data.boss_symbol_id), BossSymbolSystem.get_name(data.boss_symbol_id)]
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

	var skill_names: Array = skills.get("skills", [])
	if not skill_names.is_empty():
		status_label.text = "✨ 스킬 발동: %s" % ", ".join(skill_names)

func _on_attack_button_pressed() -> void:
	if is_battle_over:
		return

	var damage: int = calculated_attack_damage
	if damage > 0:
		damage = enemy.take_piercing_damage(damage, 0)

	if enemy.current_hp <= 0:
		await _handle_victory()
		return

	var incoming: int = enemy.consume_planned_attack()
	var boss_extra_damage: int = _apply_boss_symbol_effect(incoming)
	incoming += boss_extra_damage
	player.take_damage(incoming)
	RunState.current_hp = player.current_hp
	_update_hp_labels()
	_update_enemy_intent()
	if player.current_hp <= 0:
		await _handle_defeat()
		return

	_start_turn("⚔️ %d 피해를 주고 적의 공격을 견뎠습니다. 다시 굴리세요." % damage)

func _apply_boss_symbol_effect(base_damage: int) -> int:
	if not is_boss_battle or enemy == null or enemy.enemy_data.boss_symbol_id <= 0:
		return 0

	var power: int = enemy.enemy_data.boss_symbol_power
	var effect: String = enemy.enemy_data.boss_symbol_effect
	var extra_damage: int = 0
	match effect:
		"burn":
			extra_damage = power
			_show_feedback("🔥 화염 심볼: 추가 피해 +%d" % extra_damage)
		"frost":
			var lost_shield: int = mini(player.current_shield, power)
			player.current_shield -= lost_shield
			_show_feedback("❄️ 빙결 심볼: 보호막 -%d" % lost_shield)
		"plague":
			extra_damage = power
			_show_feedback("☠️ 역병 심볼: 추가 피해 +%d" % extra_damage)
		"drain":
			var healed: int = enemy.heal(maxi(1, base_damage / 2))
			_show_feedback("🩸 혈액 심볼: 보스 회복 +%d" % healed)
		"storm":
			extra_damage = power
			_show_feedback("⚡ 폭풍 심볼: 추가 피해 +%d" % extra_damage)
		"stone":
			enemy.add_temporary_armor(power)
			_show_feedback("🪨 거암 심볼: 보스 방어력 +%d" % power)
		"fate":
			extra_damage = maxi(0, power - 1)
			_show_feedback("🔮 운명 심볼: 추가 피해 +%d" % extra_damage)
		"void":
			var bypass: int = mini(player.current_shield, power)
			player.current_shield -= bypass
			_show_feedback("🌑 공허 심볼: 보호막 %d 무시" % bypass)
	return extra_damage

func _handle_victory() -> void:
	is_battle_over = true
	RunState.current_hp = player.current_hp
	RunState.battle_cleared = true
	if is_boss_battle:
		RunState.boss_cleared = true
		RunState.boss_reward_claimed = false
	RunState.reward_claimed = false
	_show_feedback("🏆 %s 격파! 보상을 선택하세요." % enemy.enemy_data.display_name)
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reward.tscn")

func _handle_defeat() -> void:
	is_battle_over = true
	RunState.current_hp = 0
	RunState.die()
	_show_feedback("💀 사망 — 주사위 하나를 계승할 수 있습니다.")
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reincarnation.tscn")
