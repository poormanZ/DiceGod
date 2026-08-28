class_name Battle
extends Control

@export var dice_data: DiceData
@export var player_data: PlayerData
@export var enemy_data: EnemyData
@export var ability_data: AbilityData

@onready var dice_roll_panel: DiceRollPanel = $MarginContainer/Content/DiceRollPanel
@onready var roll_button: Button = $MarginContainer/Content/ActionButtons/RollButton
@onready var reroll_button: Button = $MarginContainer/Content/ActionButtons/RerollButton
@onready var confirm_button: Button = $MarginContainer/Content/ActionButtons/ConfirmButton
@onready var ability_button: Button = $MarginContainer/Content/ActionButtons/AbilityButton
@onready var attack_button: Button = $MarginContainer/Content/ActionButtons/AttackButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel
@onready var selected_build_label: Label = $MarginContainer/Content/SelectedBuildRow/SelectedBuildLabel
@onready var player_name_label: Label = $MarginContainer/Content/PlayerArea/PlayerNameLabel
@onready var player_hp_label: Label = $MarginContainer/Content/PlayerArea/PlayerHpLabel
@onready var enemy_name_label: Label = $MarginContainer/Content/EnemyArea/EnemyNameLabel
@onready var enemy_hp_label: Label = $MarginContainer/Content/EnemyArea/EnemyHpLabel
@onready var enemy_hint_label: Label = $MarginContainer/Content/EnemyArea/EnemyHintRow/EnemyHint
@onready var battle_box_label: Label = $MarginContainer/Content/BattleBox/BattleBoxLabel

var dice_states: Array[DiceRuntimeState] = []
var dice_roller := DiceRoller.new()
var player: Player
var enemy: Enemy
var ability: Ability
var calculated_attack_damage: int = 0
var calculated_block: int = 0
var calculated_heal: int = 0
var is_battle_over: bool = false
var ability_used: bool = false

func _ready() -> void:
	_load_default_data()
	_create_battle_entities()
	_create_dice_states()
	ability_button.visible = false
	ability_button.disabled = true
	selected_build_label.text = "심볼 주사위 × %d" % dice_states.size()
	player_name_label.text = player.player_data.display_name
	enemy_name_label.text = enemy.enemy_data.display_name
	_add_run_status_overlay()
	_update_hp_labels()
	_update_enemy_intent()
	_start_turn("6개의 심볼 주사위를 굴려 행동을 선택하세요.")

func _load_default_data() -> void:
	if dice_data == null: dice_data = load("res://resources/dice/basic_dice.tres") as DiceData
	if player_data == null: player_data = load("res://resources/characters/basic_player.tres") as PlayerData
	if enemy_data == null: enemy_data = load("res://resources/enemies/basic_slime.tres") as EnemyData
	if ability_data == null: ability_data = AbilityData.new()

func _create_battle_entities() -> void:
	player = Player.new(player_data)
	enemy = Enemy.new(enemy_data)
	ability = Ability.new(ability_data)

func _create_dice_states() -> void:
	dice_states.clear()
	for _index: int in DiceData.STARTING_DICE_COUNT: dice_states.append(DiceRuntimeState.new(dice_data))

func _add_run_status_overlay() -> void:
	if get_node_or_null("RunStatusOverlay") == null: RunStatusOverlay.attach(self)

func _start_turn(message: String) -> void:
	dice_roller.reset_turn_state()
	calculated_attack_damage = 0
	calculated_block = 0
	calculated_heal = 0
	ability_used = false
	is_battle_over = false
	for dice_state: DiceRuntimeState in dice_states: dice_state.clear_result()
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.set_dice_interaction_enabled(false)
	_set_action_buttons(false, false, false, true, false)
	roll_button.disabled = false
	status_label.text = message
	_show_feedback(message)

func _on_roll_button_pressed() -> void:
	if is_battle_over or not dice_roller.roll_all(dice_states): return
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	dice_roll_panel.set_dice_interaction_enabled(true)
	roll_button.disabled = true
	reroll_button.disabled = false
	confirm_button.disabled = false
	_calculate_actions()
	_show_feedback("주사위 결과를 확인하고 필요한 주사위를 잠그세요.")

func _on_reroll_button_pressed() -> void:
	if is_battle_over or not dice_roller.reroll(dice_states): return
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	reroll_button.disabled = true
	_calculate_actions()
	_show_feedback("리롤 완료 — 최종 심볼을 확정하세요.")

func _on_confirm_button_pressed() -> void:
	if is_battle_over or not dice_roller.confirm_results(dice_states): return
	dice_roll_panel.set_dice_interaction_enabled(false)
	reroll_button.disabled = true
	confirm_button.disabled = true
	_calculate_actions()
	_apply_heal()
	_apply_block()
	# 스킬은 별도 버튼 없이 확정 결과의 조건을 만족하면 자동 적용한다.
	var bonus: int = ability.calculate_bonus(dice_states)
	if bonus > 0:
		calculated_attack_damage += bonus
		ability_used = true
		_show_feedback("스킬 자동 발동: 공격 +%d" % bonus)
	ability_button.visible = false
	attack_button.disabled = not _has_player_action()
	status_label.text = "확정: 공격 %d  |  보호막 %d  |  회복 %d" % [calculated_attack_damage, calculated_block, calculated_heal]

func _calculate_actions() -> void:
	calculated_attack_damage = RunState.attack_bonus
	calculated_block = 0
	calculated_heal = 0
	for dice_state: DiceRuntimeState in dice_states:
		if dice_state == null or not dice_state.has_result(): continue
		match dice_state.result:
			DiceData.SWORD, DiceData.BOW, DiceData.STAFF, DiceData.SHURIKEN: calculated_attack_damage += 1
			DiceData.SHIELD: calculated_block += 1
			DiceData.HEAL: calculated_heal += 1
	var counts: Dictionary = ability.get_symbol_counts(dice_states)
	var shield_count: int = int(counts.get(DiceData.SHIELD, 0))
	var heal_count: int = int(counts.get(DiceData.HEAL, 0))
	if shield_count >= 2: calculated_block += shield_count - 1
	if heal_count >= 2: calculated_heal += heal_count - 1

func _apply_heal() -> void:
	if calculated_heal <= 0: return
	var healed: int = player.heal(calculated_heal)
	RunState.current_hp = player.current_hp
	_update_hp_labels()
	if healed > 0: _show_feedback("회복 +%d" % healed)

func _apply_block() -> void:
	if calculated_block <= 0: return
	var added_shield: int = player.add_shield(calculated_block)
	_update_hp_labels()
	_show_feedback("보호막 +%d" % added_shield)

func _has_player_action() -> bool:
	return calculated_attack_damage > 0 or calculated_block > 0 or calculated_heal > 0

func _on_ability_button_pressed() -> void:
	# 하위 씬과 기존 연결을 위한 호환 함수. 실제 발동은 확정 시 자동 처리한다.
	return

func _on_attack_button_pressed() -> void:
	if is_battle_over: return
	var damage: int = calculated_attack_damage
	if damage > 0: damage = enemy.take_piercing_damage(damage, 0)
	if enemy.current_hp <= 0:
		await _handle_victory()
		return
	var incoming: int = enemy.consume_planned_attack()
	player.take_damage(incoming)
	RunState.current_hp = player.current_hp
	_update_hp_labels()
	_update_enemy_intent()
	if player.current_hp <= 0:
		await _handle_defeat()
		return
	_start_turn("공격 %d 피해를 주고 적의 공격을 견뎠습니다. 다시 굴리세요." % damage)

func _handle_victory() -> void:
	is_battle_over = true
	RunState.current_hp = player.current_hp
	RunState.battle_cleared = true
	run_disable_action_buttons()
	_update_hp_labels()
	_show_feedback("전투 승리! %d 피해" % calculated_attack_damage)

func _handle_defeat() -> void:
	is_battle_over = true
	RunState.current_hp = 0
	run_disable_action_buttons()
	_show_feedback("패배... 적의 공격을 견디지 못했습니다.")

func run_disable_action_buttons() -> void: _set_action_buttons(true, true, true, true, true)
func _set_action_buttons(roll_disabled: bool, reroll_disabled: bool, confirm_disabled: bool, ability_disabled: bool, attack_disabled: bool) -> void:
	roll_button.disabled = roll_disabled
	reroll_button.disabled = reroll_disabled
	confirm_button.disabled = confirm_disabled
	ability_button.disabled = true
	attack_button.disabled = attack_disabled

func _update_hp_labels() -> void:
	if player != null: player_hp_label.text = "HP %d / %d  |  보호막 %d" % [player.current_hp, player.player_data.max_hp, player.current_shield]
	if enemy != null: enemy_hp_label.text = "HP %d / %d" % [enemy.current_hp, enemy.enemy_data.max_hp]

func _update_enemy_intent() -> void:
	if enemy == null or enemy_hint_label == null: return
	enemy_hint_label.text = "다음 공격: %d 피해" % enemy.get_attack_intent()

func _show_feedback(message: String) -> void:
	status_label.text = message
	battle_box_label.text = message
