class_name Battle
extends Control

## 심볼 주사위 전투 전용 컨트롤러
## 기존 숫자 주사위, 빌드 선택, 특수 회복 주사위 시스템은 사용하지 않습니다.

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
@onready var selected_build_label: Label = $MarginContainer/Content/SelectedBuildLabel
@onready var player_name_label: Label = $MarginContainer/Content/PlayerArea/PlayerNameLabel
@onready var player_hp_label: Label = $MarginContainer/Content/PlayerArea/PlayerHpLabel
@onready var enemy_name_label: Label = $MarginContainer/Content/EnemyArea/EnemyNameLabel
@onready var enemy_hp_label: Label = $MarginContainer/Content/EnemyArea/EnemyHpLabel
@onready var enemy_hint_label: Label = $MarginContainer/Content/EnemyArea/EnemyHint
@onready var battle_box_label: Label = $MarginContainer/Content/BattleBox/BattleBoxLabel

const STARTING_DICE_COUNT: int = 6

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
	if dice_data == null:
		dice_data = load("res://resources/dice/basic_dice.tres") as DiceData
	if player_data == null:
		player_data = load("res://resources/characters/basic_player.tres") as PlayerData
	if enemy_data == null:
		enemy_data = load("res://resources/enemies/basic_slime.tres") as EnemyData
	if ability_data == null:
		ability_data = AbilityData.new()

	player = Player.new(player_data)
	enemy = Enemy.new(enemy_data)
	ability = Ability.new(ability_data)

	dice_states.clear()
	for _index in STARTING_DICE_COUNT:
		dice_states.append(DiceRuntimeState.new(dice_data))

	selected_build_label.text = "⚔️ 🏹 🔮 🗡️ 🛡️ ❤️  심볼 주사위"
	player_name_label.text = player.player_data.display_name
	enemy_name_label.text = enemy.enemy_data.display_name
	_update_hp_labels()
	_update_enemy_intent()
	_start_turn("6개의 심볼 주사위를 굴려 행동을 선택하세요.")

func _start_turn(message: String) -> void:
	dice_roller.reset_turn_state()
	calculated_attack_damage = 0
	calculated_block = 0
	calculated_heal = 0
	ability_used = false
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
	status_label.text = message
	_show_feedback(message)

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
	_calculate_actions()
	_show_feedback("🎲  ⚔️ 🏹 🔮 🗡️ 🛡️ ❤️  심볼을 확인하세요.")

func _on_reroll_button_pressed() -> void:
	if is_battle_over or not dice_roller.reroll(dice_states):
		return
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	reroll_button.disabled = true
	_calculate_actions()
	_show_feedback("↻ 리롤 완료 — 최종 심볼을 확정하세요.")

func _on_confirm_button_pressed() -> void:
	if is_battle_over or not dice_roller.confirm_results(dice_states):
		return
	dice_roll_panel.set_dice_interaction_enabled(false)
	reroll_button.disabled = true
	confirm_button.disabled = true
	_calculate_actions()
	_apply_heal()
	ability_button.disabled = not ability.can_use(dice_states)
	attack_button.disabled = calculated_attack_damage <= 0 and calculated_block <= 0 and calculated_heal <= 0
	status_label.text = "확정: ⚔️ %d  🛡️ %d  ❤️ %d" % [calculated_attack_damage, calculated_block, calculated_heal]
	_show_feedback(status_label.text)

func _calculate_actions() -> void:
	calculated_attack_damage = RunState.attack_bonus
	calculated_block = 0
	calculated_heal = 0
	for dice_state in dice_states:
		if not dice_state.has_result():
			continue
		if DiceData.is_attack(dice_state.result):
			calculated_attack_damage += 1
		elif DiceData.is_defense(dice_state.result):
			calculated_block += 1
		elif DiceData.is_heal(dice_state.result):
			calculated_heal += 1
	var counts: Dictionary = ability.get_symbol_counts(dice_states)
	var shield_count: int = int(counts.get(DiceData.SHIELD, 0))
	var heal_count: int = int(counts.get(DiceData.HEAL, 0))
	if shield_count >= 2:
		calculated_block += shield_count - 1
	if heal_count >= 2:
		calculated_heal += heal_count - 1

func _apply_heal() -> void:
	if calculated_heal <= 0:
		return
	var healed: int = player.heal(calculated_heal)
	RunState.current_hp = player.current_hp
	_update_hp_labels()
	if healed > 0:
		_show_feedback("❤️ 회복 +%d" % healed)

func _on_ability_button_pressed() -> void:
	if ability_used:
		return
	var bonus: int = ability.calculate_bonus(dice_states)
	if bonus <= 0:
		ability_button.disabled = true
		return
	ability_used = true
	calculated_attack_damage += bonus
	ability_button.disabled = true
	attack_button.disabled = false
	status_label.text = "✨ 심볼 스킬 발동: 공격 +%d" % bonus
	_show_feedback(status_label.text)

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
	player.take_damage(incoming)
	RunState.current_hp = player.current_hp
	_update_hp_labels()
	_update_enemy_intent()
	if player.current_hp <= 0:
		await _handle_defeat()
		return
	_start_turn("⚔️ %d 피해를 주고 적의 공격을 견뎠습니다. 다시 굴리세요." % damage)

func _handle_victory() -> void:
	is_battle_over = true
	RunState.current_hp = player.current_hp
	RunState.battle_cleared = true
	run_disable_action_buttons()
	_update_hp_labels()
	_show_feedback("🏆 전투 승리! %d 피해" % calculated_attack_damage)

func _handle_defeat() -> void:
	is_battle_over = true
	RunState.current_hp = 0
	run_disable_action_buttons()
	_show_feedback("💀 패배... 적의 공격을 견디지 못했습니다.")

func run_disable_action_buttons() -> void:
	roll_button.disabled = true
	reroll_button.disabled = true
	confirm_button.disabled = true
	attack_button.disabled = true
	ability_button.disabled = true

func _update_hp_labels() -> void:
	if player != null:
		player_hp_label.text = "HP %d / %d  🛡️ %d" % [player.current_hp, player.player_data.max_hp, player.current_shield]
	if enemy != null:
		enemy_hp_label.text = "HP %d / %d" % [enemy.current_hp, enemy.enemy_data.max_hp]

func _update_enemy_intent() -> void:
	if enemy == null or enemy_hint_label == null:
		return
	enemy_hint_label.text = "⚠️ 다음 공격: %d 피해" % enemy.get_attack_intent()

func _show_feedback(message: String) -> void:
	status_label.text = message
	battle_box_label.text = message
