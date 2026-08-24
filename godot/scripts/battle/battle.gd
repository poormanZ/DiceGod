class_name Battle
extends Control

@export var dice_data: DiceData
@export var player_data: PlayerData
@export var enemy_data: EnemyData
@export var ability_data: AbilityData
@export var equipment_data: EquipmentData
@export var healing_dice_data: HealingDiceData
@export var matching_build: BuildData
@export var straight_build: BuildData
@export var healing_build: BuildData
@export var power_build: BuildData
@export var flame_build: BuildData
@export var guardian_build: BuildData
@export var is_elite_battle: bool = false
@export var is_boss_battle: bool = false

@onready var dice_roll_panel: DiceRollPanel = $MarginContainer/Content/DiceRollPanel
@onready var roll_button: Button = $MarginContainer/Content/ActionButtons/RollButton
@onready var reroll_button: Button = $MarginContainer/Content/ActionButtons/RerollButton
@onready var confirm_button: Button = $MarginContainer/Content/ActionButtons/ConfirmButton
@onready var ability_button: Button = $MarginContainer/Content/ActionButtons/AbilityButton
@onready var healing_dice_button: Button = $MarginContainer/Content/ActionButtons/HealingDiceButton
@onready var attack_button: Button = $MarginContainer/Content/ActionButtons/AttackButton
@onready var restart_build_button: Button = $MarginContainer/Content/RestartBuildButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel
@onready var selected_build_label: Label = $MarginContainer/Content/SelectedBuildLabel
@onready var player_name_label: Label = $MarginContainer/Content/PlayerArea/PlayerNameLabel
@onready var player_hp_label: Label = $MarginContainer/Content/PlayerArea/PlayerHpLabel
@onready var enemy_name_label: Label = $MarginContainer/Content/EnemyArea/EnemyNameLabel
@onready var enemy_hp_label: Label = $MarginContainer/Content/EnemyArea/EnemyHpLabel
@onready var battle_box_label: Label = $MarginContainer/Content/BattleBox/BattleBoxLabel
@onready var build_selection_panel: PanelContainer = $BuildSelectionPanel
@onready var build_box: VBoxContainer = $BuildSelectionPanel/Margin/VBox

const STARTING_DICE_COUNT := 6

var build_buttons: Array[Button] = []
var available_builds: Array[BuildData] = []
var dice_states: Array[DiceRuntimeState] = []
var dice_roller := DiceRoller.new()
var player: Player
var enemy: Enemy
var ability: Ability
var equipment: Equipment
var calculated_attack_damage: int = 0
var calculated_block: int = 0
var calculated_heal: int = 0
var calculated_special_bonus: int = 0
var calculated_penetration: int = 0
var calculated_extra_hits: int = 0
var calculated_magic_bonus: int = 0
var calculated_status_damage: int = 0
var calculated_shield: int = 0
var is_battle_over: bool = false
var selected_build: BuildData
var effects_applied: bool = false

func _ready() -> void:
	_setup_build_selection()

func _set_action_buttons_for_build(build: BuildData) -> void:
	roll_button.show()
	reroll_button.show()
	confirm_button.show()
	attack_button.show()
	attack_button.text = "행동 실행"
	ability_button.visible = build != null and build.ability_data != null
	if ability_button.visible:
		ability_button.text = build.ability_data.display_name
	healing_dice_button.hide()

func _hide_optional_action_buttons() -> void:
	ability_button.hide()
	healing_dice_button.hide()

func _setup_build_selection() -> void:
	if flame_build == null:
		flame_build = load("res://resources/builds/flame_build.tres") as BuildData
	if guardian_build == null:
		guardian_build = load("res://resources/builds/guardian_build.tres") as BuildData
	available_builds.clear()
	for build in [matching_build, straight_build, healing_build, power_build, flame_build, guardian_build]:
		if build != null:
			available_builds.append(build)
	for child in build_box.get_children():
		if child is Button:
			build_box.remove_child(child)
			child.queue_free()
	build_buttons.clear()
	build_selection_panel.offset_left = -350.0
	build_selection_panel.offset_top = -310.0
	build_selection_panel.offset_right = 350.0
	build_selection_panel.offset_bottom = 310.0
	for build in available_builds:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s\n%s" % [build.display_name, build.description]
		button.add_theme_font_size_override("font_size", 14)
		var locked := build == power_build and not ProgressionState.is_dice_unlocked("power_dice")
		button.disabled = locked
		if locked:
			button.text += "\n🔒 보스 클리어 후 해금"
		button.pressed.connect(_on_build_selected.bind(build))
		build_box.add_child(button)
		build_buttons.append(button)
	build_selection_panel.show()
	_hide_optional_action_buttons()
	restart_build_button.hide()
	status_label.text = "빌드를 선택하면 심볼 주사위 전투가 시작됩니다."

func _on_build_selected(build: BuildData) -> void:
	selected_build = build
	RunState.selected_build_id = build.display_name
	dice_data = build.dice_data
	ability_data = build.ability_data
	equipment_data = build.equipment_data
	player = Player.new(player_data)
	player.current_hp = player.player_data.max_hp
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
	selected_build_label.text = "선택한 빌드: %s — %s\n⚔️ 공격  🛡️ 방어  ✚ 치료" % [build.display_name, build.description]
	_set_action_buttons_for_build(build)
	for _dice_index in STARTING_DICE_COUNT:
		dice_states.append(DiceRuntimeState.new(dice_data))
	build_selection_panel.hide()
	restart_build_button.hide()
	_start_turn("%s을(를) 선택했습니다. 6개의 주사위를 굴려 행동 심볼을 만드세요." % build.display_name)

func _update_enemy_intent_display() -> void:
	if enemy == null or enemy_name_label == null:
		return
	var intent_text := enemy.get_attack_intent()
	var enemy_hint := get_node_or_null("MarginContainer/Content/EnemyArea/EnemyHint") as Label
	if enemy_hint != null:
		enemy_hint.text = "⚠️ " + str(intent_text)

func _update_player_hp_label() -> void:
	player_hp_label.text = "HP %d / %d" % [player.current_hp, player.player_data.max_hp]

func _update_damage_preview() -> void:
	if enemy == null or player == null or not enemy.has_planned_attack():
		return
	var incoming := enemy.planned_attack_damage
	var mitigation: int = calculated_block + calculated_shield
	var expected_damage: int = maxi(0, incoming - mitigation)
	var preview := "⚠️ 적 공격 %d  |  🛡️ 방어 %d  + 보호 %d  |  예상 피해 %d" % [incoming, calculated_block, calculated_shield, expected_damage]
	status_label.text = preview
	_show_combat_feedback(preview, Color(0.75, 0.85, 1.0, 1.0))

func _pulse_control(control: Control, flash_color: Color = Color.WHITE, duration: float = 0.22) -> void:
	if control == null:
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(1.08, 1.08)
	control.modulate = flash_color
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(control, "scale", Vector2.ONE, duration)
	tween.parallel().tween_property(control, "modulate", Color.WHITE, duration)

func _show_combat_feedback(message: String, flash_color: Color = Color.WHITE) -> void:
	battle_box_label.text = message
	battle_box_label.modulate = flash_color
	battle_box_label.scale = Vector2(1.06, 1.06)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(battle_box_label, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(battle_box_label, "modulate", Color(0.85, 0.85, 0.85, 1.0), 0.3)

func _on_restart_build_button_pressed() -> void:
	_setup_build_selection()

func _start_turn(status_message: String = "주사위 굴리기를 눌러 전투를 시작하세요.") -> void:
	dice_roller.reset_turn_state()
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
	if enemy != null:
		enemy.plan_next_attack()
		_update_enemy_intent_display()
	for dice_state in dice_states:
		dice_state.result = 0
		dice_state.is_locked = false
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.set_dice_interaction_enabled(false)
	roll_button.disabled = false
	reroll_button.disabled = true
	confirm_button.disabled = true
	ability_button.disabled = true
	attack_button.disabled = true
	restart_build_button.hide()
	status_label.text = status_message
	_show_combat_feedback(status_message)

func _on_roll_button_pressed() -> void:
	if is_battle_over:
		return
	for dice_state in dice_states:
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
	_show_combat_feedback("🎲 6개의 심볼 주사위를 굴렸습니다.")

func _on_reroll_button_pressed() -> void:
	if not dice_roller.reroll(dice_states):
		return
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	reroll_button.disabled = true
	_calculate_actions()
	_update_damage_preview()
	status_label.text = "리롤을 사용했습니다. 최종 심볼을 확정하세요."
	_show_combat_feedback("↻ 리롤 완료")

func _on_confirm_button_pressed() -> void:
	if not dice_roller.confirm_results(dice_states):
		return
	AudioManager.play_confirm()
	dice_roll_panel.set_dice_interaction_enabled(false)
	reroll_button.disabled = true
	confirm_button.disabled = true
	_calculate_actions()
	_apply_non_attack_effects()
	ability_button.disabled = not ability.can_use(dice_states)
	attack_button.disabled = calculated_attack_damage <= 0 and calculated_block <= 0 and calculated_heal <= 0
	status_label.text = "확정: ⚔️ %d  🛡️ %d  ✚ %d" % [calculated_attack_damage, calculated_block, calculated_heal]
	_show_combat_feedback("⚡ ⚔️ %d  🛡️ %d  ✚ %d" % [calculated_attack_damage, calculated_block, calculated_heal], Color(1.0, 0.84, 0.35, 1.0))

func _calculate_actions() -> void:
	calculated_attack_damage = RunState.attack_bonus
	calculated_block = 0
	calculated_heal = 0
	calculated_special_bonus = 0
	calculated_penetration = 0
	calculated_extra_hits = 0
	calculated_magic_bonus = 0
	calculated_status_damage = 0
	calculated_shield = 0
	for dice_state in dice_states:
		if not dice_state.has_result():
			continue
		if DiceData.is_attack(dice_state.result):
			calculated_attack_damage += 1
		elif DiceData.is_defense(dice_state.result):
			calculated_block += 1
		elif DiceData.is_heal(dice_state.result):
			calculated_heal += 1
	var sword_count := ability.get_attack_symbol_count(dice_states, DiceData.SWORD)
	var bow_count := ability.get_attack_symbol_count(dice_states, DiceData.BOW)
	var staff_count := ability.get_attack_symbol_count(dice_states, DiceData.STAFF)
	var shuriken_count := ability.get_attack_symbol_count(dice_states, DiceData.SHURIKEN)
	if sword_count >= 2:
		calculated_special_bonus += ability.ability_data.sword_heavy_bonus
	if bow_count >= 2:
		calculated_penetration = ability.ability_data.bow_penetration * (bow_count - 1)
	if staff_count >= 2:
		calculated_magic_bonus = (staff_count - 1) * ability.ability_data.staff_magic_bonus
		calculated_special_bonus += calculated_magic_bonus
		calculated_status_damage = calculated_magic_bonus
	if shuriken_count >= 2:
		calculated_extra_hits = ability.ability_data.shuriken_extra_hits * (shuriken_count - 1)
		calculated_special_bonus += calculated_extra_hits
	calculated_attack_damage += calculated_special_bonus
	var shield_count := ability.get_symbol_count(dice_states, DiceData.SHIELD)
	var heal_count := ability.get_symbol_count(dice_states, DiceData.HEAL)
	if shield_count >= 2:
		calculated_shield = shield_count - 1
	if heal_count >= 2:
		calculated_heal += heal_count - 1
	_update_damage_preview()

func _apply_non_attack_effects() -> void:
	if effects_applied:
		return
	effects_applied = true
	if calculated_heal > 0:
		var previous_hp := player.current_hp
		player.heal(calculated_heal)
		var actual_heal := player.current_hp - previous_hp
		var overheal := calculated_heal - actual_heal
		if overheal > 0:
			player.add_shield(overheal)
			calculated_shield += overheal
		RunState.current_hp = player.current_hp
		_update_player_hp_label()
		_pulse_control(player_hp_label, Color(0.35, 1.0, 0.5, 1.0))

func _on_ability_button_pressed() -> void:
	var bonus := ability.calculate_bonus(dice_states)
	if bonus <= 0:
		ability_button.disabled = true
		return
	AudioManager.play_confirm()
	calculated_attack_damage += bonus
	ability_button.disabled = true
	status_label.text = "%s 사용: ⚔️ 공격 +%d (총 %d)" % [ability.ability_data.display_name, bonus, calculated_attack_damage]
	_show_combat_feedback("✨ %s +%d" % [ability.ability_data.display_name, bonus], Color(0.7, 0.9, 1.0, 1.0))
	_update_damage_preview()

func _on_attack_button_pressed() -> void:
	if is_battle_over:
		return
	dice_roll_panel.play_attack_feedback()
	var final_damage := 0
	if calculated_attack_damage > 0:
		_pulse_control(enemy_name_label, Color(1.0, 0.35, 0.25, 1.0))
		final_damage = enemy.take_piercing_damage(calculated_attack_damage, calculated_penetration)
		if calculated_extra_hits > 0:
			for _hit_index in calculated_extra_hits:
				var extra_hit_damage := enemy.take_piercing_damage(1, calculated_penetration)
				final_damage += extra_hit_damage
			AudioManager.play_hit()
			dice_roll_panel.play_damage_feedback(final_damage)
		if calculated_status_damage > 0:
			enemy.apply_status("burn", 2, calculated_status_damage)
	else:
		final_damage = 0
	enemy_hp_label.text = "HP %d / %d" % [enemy.current_hp, enemy.enemy_data.max_hp]
	_pulse_control(enemy_hp_label, Color(1.0, 0.35, 0.25, 1.0))
	var special_text := ""
	if calculated_penetration > 0:
		special_text += " 🏹 관통-%d" % calculated_penetration
	if calculated_magic_bonus > 0:
		special_text += " 🪄 마법+%d/화상" % calculated_magic_bonus
	if calculated_extra_hits > 0:
		special_text += " ✦ 연타+%d" % calculated_extra_hits
	if ability.get_attack_symbol_count(dice_states, DiceData.SWORD) >= 2:
		special_text += " ⚔️ 강타+%d" % ability.ability_data.sword_heavy_bonus
	if calculated_shield > 0:
		special_text += " 🛡️ 보호+%d" % calculated_shield
	_show_combat_feedback("행동 실행 — 피해 %d  🛡️ %d  ✚ %d%s" % [final_damage, calculated_block, calculated_heal, special_text], Color(1.0, 0.45, 0.35, 1.0))
	attack_button.disabled = true
	if enemy.current_hp <= 0:
		_handle_victory()
		return
	_perform_enemy_action()

func _perform_enemy_action() -> void:
	if equipment.can_evade(dice_states):
		_show_combat_feedback("🛡️ 방패 3개 완성! 적의 공격을 완전히 막았습니다.", Color(0.55, 0.8, 1.0, 1.0))
		_start_turn("방어 성공. 다음 턴의 심볼을 굴리세요.")
		return
	var enemy_damage: int = int(enemy.consume_planned_attack())
	var blocked_damage: int = mini(enemy_damage, calculated_block + calculated_shield)
	var final_damage: int = maxi(enemy_damage - calculated_block - calculated_shield, 0)
	if blocked_damage > 0:
		_show_combat_feedback("🛡️ 방어 %d + 보호 %d로 피해 %d 차단" % [calculated_block, calculated_shield, blocked_damage], Color(0.55, 0.8, 1.0, 1.0))
	if final_damage > 0:
		player.take_damage(final_damage)
		AudioManager.play_hit()
		_pulse_control(player_hp_label, Color(1.0, 0.35, 0.25, 1.0))
	RunState.current_hp = player.current_hp
	_update_player_hp_label()
	if final_damage > 0:
		_show_combat_feedback("💥 %d 피해를 받았습니다. (방어 %d / 보호 %d)" % [final_damage, calculated_block, calculated_shield], Color(1.0, 0.4, 0.35, 1.0))
	else:
		_show_combat_feedback("🛡️ 모든 피해를 막았습니다!", Color(0.55, 0.8, 1.0, 1.0))
	var status_effects := enemy.tick_statuses()
	if status_effects.has("burn"):
		var burn_damage := int(status_effects["burn"])
		enemy.take_damage(burn_damage)
		_show_combat_feedback("🔥 화상 피해 %d" % burn_damage, Color(1.0, 0.55, 0.2, 1.0))
	if player.current_hp <= 0:
		_handle_defeat()
		return
	_start_turn("%s의 공격을 견뎠습니다. 다음 턴을 시작하세요." % enemy.enemy_data.display_name)

func _handle_victory() -> void:
	is_battle_over = true
	AudioManager.play_victory()
	_pulse_control(enemy_hp_label, Color(1.0, 0.84, 0.35, 1.0), 0.35)
	_show_combat_feedback("🏆 VICTORY!", Color(1.0, 0.84, 0.35, 1.0))
	RunState.current_hp = player.current_hp
	if is_boss_battle:
		RunState.boss_cleared = true
		RunState.complete_run()

func _handle_defeat() -> void:
	is_battle_over = true
	AudioManager.play_defeat()
	_show_combat_feedback("💀 DEFEAT", Color(1.0, 0.35, 0.35, 1.0))
	restart_build_button.show()
