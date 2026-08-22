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
@export var is_elite_battle: bool = false

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
@onready var build_selection_panel: PanelContainer = $BuildSelectionPanel
@onready var build_buttons: Array[Button] = [$BuildSelectionPanel/Margin/VBox/MatchingBuildButton, $BuildSelectionPanel/Margin/VBox/StraightBuildButton, $BuildSelectionPanel/Margin/VBox/HealingBuildButton]

var dice_states: Array[DiceRuntimeState] = []
var dice_roller := DiceRoller.new()
var player: Player
var enemy: Enemy
var ability: Ability
var equipment: Equipment
var healing_dice: HealingDice
var calculated_attack_damage: int = 0
var is_battle_over: bool = false
var selected_build: BuildData
var healing_dice_used: bool = false

func _ready() -> void:
	_setup_build_selection()

func _set_action_buttons_for_build(build: BuildData) -> void:
	roll_button.show()
	reroll_button.show()
	confirm_button.show()
	attack_button.show()
	ability_button.visible = build != null and build.ability_data != null
	healing_dice_button.visible = build != null and build.healing_dice_data != null
	if ability_button.visible:
		ability_button.text = build.ability_data.display_name
	else:
		ability_button.hide()
	if not healing_dice_button.visible:
		healing_dice_button.hide()

func _hide_optional_action_buttons() -> void:
	ability_button.hide()
	healing_dice_button.hide()

func _setup_build_selection() -> void:
	var builds: Array[BuildData] = [matching_build, straight_build, healing_build]
	for index in build_buttons.size():
		var build := builds[index]
		build_buttons[index].text = "%s\n%s" % [build.display_name, build.description]
		if not build_buttons[index].pressed.is_connected(_on_build_selected.bind(build)):
			build_buttons[index].pressed.connect(_on_build_selected.bind(build))
	build_selection_panel.show()
	_hide_optional_action_buttons()
	restart_build_button.hide()
	status_label.text = "빌드를 선택하면 전투가 시작됩니다."

func _on_build_selected(build: BuildData) -> void:
	selected_build = build
	dice_data = build.dice_data
	ability_data = build.ability_data
	equipment_data = build.equipment_data
	healing_dice_data = build.healing_dice_data
	player = Player.new(player_data)
	var shop_heal: int = int(get_tree().get_meta("dungeon_shop_heal", 0))
	if shop_heal > 0:
		player.heal(shop_heal)
	enemy = Enemy.new(enemy_data)
	ability = Ability.new(ability_data)
	equipment = Equipment.new(equipment_data)
	healing_dice = HealingDice.new(healing_dice_data)
	dice_states.clear()
	is_battle_over = false
	calculated_attack_damage = 0
	healing_dice_used = false
	$MarginContainer/Content/PlayerNameLabel.text = player.player_data.display_name
	$MarginContainer/Content/EnemyNameLabel.text = enemy.enemy_data.display_name
	$MarginContainer/Content/PlayerHpLabel.text = "HP %d / %d" % [player.current_hp, player.player_data.max_hp]
	$MarginContainer/Content/EnemyHpLabel.text = "HP %d / %d" % [enemy.current_hp, enemy.enemy_data.max_hp]
	var event_bonus: int = get_tree().get_meta("dungeon_event_attack_bonus", 0)
	var shop_bonus: int = get_tree().get_meta("dungeon_shop_attack_bonus", 0)
	if event_bonus > 0 or shop_bonus > 0:
		selected_build_label.text = "선택한 빌드: %s — %s | 보너스 공격력 +%d" % [build.display_name, build.description, event_bonus + shop_bonus]
	else:
		selected_build_label.text = "선택한 빌드: %s — %s" % [build.display_name, build.description]
	_set_action_buttons_for_build(build)
	for dice_index in 3:
		dice_states.append(DiceRuntimeState.new(dice_data))
	build_selection_panel.hide()
	restart_build_button.hide()
	_start_turn("%s을(를) 선택했습니다. 주사위를 굴려 빌드의 핵심 조합을 시험해보세요." % build.display_name)

func _on_restart_build_button_pressed() -> void:
	_setup_build_selection()

func _start_turn(status_message: String = "주사위 굴리기를 눌러 전투를 시작하세요.") -> void:
	dice_roller.reset_turn_state()
	calculated_attack_damage = 0
	healing_dice_used = false
	for dice_state in dice_states:
		dice_state.result = 0
		dice_state.is_locked = false
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.set_dice_interaction_enabled(false)
	roll_button.disabled = false
	reroll_button.disabled = true
	confirm_button.disabled = true
	ability_button.disabled = true
	healing_dice_button.disabled = healing_dice_data == null
	attack_button.disabled = true
	restart_build_button.hide()
	status_label.text = status_message

func _on_roll_button_pressed() -> void:
	if is_battle_over:
		return
	for dice_state in dice_states:
		dice_roller.roll(dice_state)
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.set_dice_interaction_enabled(true)
	roll_button.disabled = true
	reroll_button.disabled = false
	confirm_button.disabled = false
	ability_button.disabled = true
	healing_dice_button.disabled = true
	attack_button.disabled = true
	status_label.text = "주사위를 잠그거나 리롤할 수 있습니다."

func _on_reroll_button_pressed() -> void:
	if not dice_roller.reroll(dice_states):
		return
	dice_roll_panel.display_results(dice_states)
	reroll_button.disabled = true
	status_label.text = "리롤을 사용했습니다. 결과를 확정할 수 있습니다."

func _on_confirm_button_pressed() -> void:
	if not dice_roller.confirm_results(dice_states):
		return
	dice_roll_panel.set_dice_interaction_enabled(false)
	reroll_button.disabled = true
	confirm_button.disabled = true
	calculated_attack_damage = _calculate_attack_damage()
	ability_button.disabled = not ability.can_use(dice_states)
	healing_dice_button.disabled = healing_dice_data == null or healing_dice_used
	attack_button.disabled = false
	status_label.text = "결과를 확정했습니다: 공격력 %d" % calculated_attack_damage

func _on_ability_button_pressed() -> void:
	var bonus := ability.calculate_bonus(dice_states)
	if bonus <= 0:
		ability_button.disabled = true
		return
	calculated_attack_damage += bonus
	ability_button.disabled = true
	status_label.text = "%s 사용: 공격력 +%d (총 %d)" % [ability.ability_data.display_name, bonus, calculated_attack_damage]

func _on_healing_dice_button_pressed() -> void:
	if is_battle_over or healing_dice_used or healing_dice == null or healing_dice_data == null:
		return
	if not healing_dice.roll():
		healing_dice_button.disabled = true
		return
	var healing_amount := healing_dice.get_healing_amount()
	player.heal(healing_amount)
	$MarginContainer/Content/PlayerHpLabel.text = "HP %d / %d" % [player.current_hp, player.player_data.max_hp]
	healing_dice_used = true
	healing_dice_button.disabled = true
	status_label.text = "힐 주사위 %d: HP를 %d 회복했습니다. (이번 턴 사용 완료)" % [healing_dice.runtime_state.result, healing_amount]

func _on_attack_button_pressed() -> void:
	enemy.take_damage(calculated_attack_damage)
	$MarginContainer/Content/EnemyHpLabel.text = "HP %d / %d" % [enemy.current_hp, enemy.enemy_data.max_hp]
	attack_button.disabled = true
	if enemy.current_hp <= 0:
		_handle_victory()
		return
	_perform_enemy_action()

func _perform_enemy_action() -> void:
	if equipment.can_evade(dice_states):
		_start_turn("%s이(가) 스트레이트를 만들어 적의 공격을 회피했습니다." % equipment.equipment_data.display_name)
		return
	var enemy_damage := enemy.roll_attack_damage()
	player.take_damage(enemy_damage)
	$MarginContainer/Content/PlayerHpLabel.text = "HP %d / %d" % [player.current_hp, player.player_data.max_hp]
	if player.current_hp <= 0:
		_handle_defeat()
		return
	_start_turn("%s이(가) %d을 굴려 %d 피해를 입혔습니다. 다음 턴을 시작하세요." % [enemy.enemy_data.display_name, enemy_damage, enemy_damage])

func _handle_victory() -> void:
	is_battle_over = true
	if is_elite_battle:
		get_tree().set_meta("dungeon_elite_cleared", true)
	else:
		get_tree().set_meta("dungeon_battle_cleared", true)
	dice_roll_panel.set_dice_interaction_enabled(false)
	roll_button.disabled = true
	reroll_button.disabled = true
	confirm_button.disabled = true
	ability_button.disabled = true
	healing_dice_button.disabled = true
	attack_button.disabled = true
	status_label.text = "%s 승리! 던전으로 돌아갑니다." % selected_build.display_name
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _handle_defeat() -> void:
	is_battle_over = true
	dice_roll_panel.set_dice_interaction_enabled(false)
	roll_button.disabled = true
	reroll_button.disabled = true
	confirm_button.disabled = true
	ability_button.disabled = true
	healing_dice_button.disabled = true
	attack_button.disabled = true
	restart_build_button.show()
	status_label.text = "%s 빌드로 패배했습니다. 다른 빌드를 시험해보세요." % selected_build.display_name

func _calculate_attack_damage() -> int:
	var attack_damage := 0
	for dice_state in dice_states:
		attack_damage += dice_state.result
	var event_bonus: int = get_tree().get_meta("dungeon_event_attack_bonus", 0)
	var shop_bonus: int = get_tree().get_meta("dungeon_shop_attack_bonus", 0)
	attack_damage += event_bonus + shop_bonus
	get_tree().set_meta("dungeon_event_attack_bonus", 0)
	get_tree().set_meta("dungeon_shop_attack_bonus", 0)
	get_tree().set_meta("dungeon_shop_heal", 0)
	return attack_damage
