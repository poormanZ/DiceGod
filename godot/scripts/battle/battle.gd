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
var active_synergy_messages: Array[String] = []

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
	# 전투 주사위는 현재 런에서 보유한 주사위 구성을 우선 사용합니다.
	if RunState.run_dice_faces.size() > 0:
		for faces: Array in RunState.run_dice_faces:
			var runtime_data: DiceData = DiceData.new()
			runtime_data.face_values = PackedInt32Array(faces)
			dice_states.append(DiceRuntimeState.new(runtime_data))
	if dice_states.is_empty():
		for _index: int in DiceData.STARTING_DICE_COUNT:
			dice_states.append(DiceRuntimeState.new(dice_data))

func _add_run_status_overlay() -> void:
	if get_node_or_null("RunStatusOverlay") == null: RunStatusOverlay.attach(self)

func _start_turn(message: String) -> void:
	dice_roller.reset_turn_state()
	calculated_attack_damage = 0
	calculated_block = 0
	calculated_heal = 0
	active_synergy_messages.clear()
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
	var bonus: int = ability.calculate_bonus(dice_states)
	if bonus > 0:
		calculated_attack_damage += bonus
		ability_used = true
		active_synergy_messages.append("스킬 +%d" % bonus)
	ability_button.visible = false
	attack_button.disabled = not _has_player_action()
	var result_message: String = "확정: 공격 %d  |  보호막 %d  |  회복 %d" % [calculated_attack_damage, calculated_block, calculated_heal]
	if not active_synergy_messages.is_empty():
		result_message += "\n시너지: " + " · ".join(active_synergy_messages)
	status_label.text = result_message
	_show_feedback(result_message)

func _calculate_actions() -> void:
	calculated_attack_damage = RunState.attack_bonus
	calculated_block = 0
	calculated_heal = 0
	active_synergy_messages.clear()
	var counts: Dictionary = {}
	for dice_state: DiceRuntimeState in dice_states:
		if dice_state == null or not dice_state.has_result(): continue
		var value: int = dice_state.result
		counts[value] = int(counts.get(value, 0)) + 1
		match value:
			DiceData.SWORD, DiceData.BOW, DiceData.STAFF, DiceData.SHURIKEN: calculated_attack_damage += 1
			DiceData.SHIELD: calculated_block += 1
			DiceData.HEAL: calculated_heal += 1
	var shield_count: int = int(counts.get(DiceData.SHIELD, 0))
	var heal_count: int = int(counts.get(DiceData.HEAL, 0))
	if shield_count >= 2: calculated_block += shield_count - 1
	if heal_count >= 2: calculated_heal += heal_count - 1
	_apply_symbol_synergies(counts)
	var ability_counts: Dictionary = ability.get_symbol_counts(dice_states)
	# 기존 능력 보너스 계산은 시너지와 독립적으로 유지합니다.
	if ability_counts.is_empty():
		return

func _apply_symbol_synergies(counts: Dictionary) -> void:
	var attack_total: int = 0
	var distinct_attack: int = 0
	for symbol: int in [DiceData.SWORD, DiceData.BOW, DiceData.STAFF, DiceData.SHURIKEN]:
		var count: int = int(counts.get(symbol, 0))
		attack_total += count
		if count > 0: distinct_attack += 1

	# 2개 조합: 공격 심볼 2개 이상이면 작은 추가 공격 보너스.
	if attack_total >= 2:
		calculated_attack_damage += 1
		active_synergy_messages.append("공격 조합 +1")

	# 같은 공격 심볼 3개 이상: 높은 확률이 필요한 완성형 조합에만 추가 보너스.
	var triple_attack: bool = false
	for symbol: int in [DiceData.SWORD, DiceData.BOW, DiceData.STAFF, DiceData.SHURIKEN]:
		if int(counts.get(symbol, 0)) >= 3:
			triple_attack = true
			break
	if triple_attack:
		calculated_attack_damage += 2
		active_synergy_messages.append("집중 공격 +2")
	elif attack_total >= 3 and distinct_attack >= 2:
		calculated_attack_damage += 1
		active_synergy_messages.append("연계 공격 +1")

	var shield_count: int = int(counts.get(DiceData.SHIELD, 0))
	var heal_count: int = int(counts.get(DiceData.HEAL, 0))
	# 방패 + 힐 2개 조합은 생존용 소폭 보너스입니다.
	if shield_count >= 1 and heal_count >= 1:
		calculated_block += 1
		calculated_heal += 1
		active_synergy_messages.append("수호 회복 +1/+1")
	# 방패 3개 이상은 안정성 대신 제한된 추가 보호막만 제공합니다.
	if shield_count >= 3:
		calculated_block += 1
		active_synergy_messages.append("철벽 +1")
	# 힐 3개 이상은 과도한 무한 회복을 막기 위해 추가 +1만 제공합니다.
	if heal_count >= 3:
		calculated_heal += 1
		active_synergy_messages.append("집중 회복 +1")

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
