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

var build_buttons: Array[Button] = []
var available_builds: Array[BuildData] = []
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
	# 신규 빌드는 이전 씬의 export가 비어 있어도 항상 로드되도록 보정합니다.
	if flame_build == null:
		flame_build = load("res://resources/builds/flame_build.tres") as BuildData
	if guardian_build == null:
		guardian_build = load("res://resources/builds/guardian_build.tres") as BuildData

	available_builds.clear()
	for build in [matching_build, straight_build, healing_build, power_build, flame_build, guardian_build]:
		if build != null:
			available_builds.append(build)

	# 씬에 남아 있던 4개의 빈 고정 버튼을 제거합니다.
	for child in build_box.get_children():
		if child is Button:
			build_box.remove_child(child)
			child.queue_free()
	build_buttons.clear()

	# 1280×720 기준에서도 전체 선택창이 화면 안에 들어오도록 크기를 제한합니다.
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
		button.add_theme_constant_override("outline_size", 0)
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
	status_label.text = "빌드를 선택하면 전투가 시작됩니다."

func _on_build_selected(build: BuildData) -> void:
	selected_build = build
	RunState.selected_build_id = build.display_name
	dice_data = build.dice_data
	ability_data = build.ability_data
	equipment_data = build.equipment_data
	healing_dice_data = build.healing_dice_data
	player = Player.new(player_data)
	player.current_hp = clampi(RunState.current_hp, 1, player.player_data.max_hp)
	enemy = Enemy.new(enemy_data)
	ability = Ability.new(ability_data)
	equipment = Equipment.new(equipment_data)
	healing_dice = HealingDice.new(healing_dice_data)
	dice_states.clear()
	is_battle_over = false
	calculated_attack_damage = 0
	healing_dice_used = false
	player_name_label.text = player.player_data.display_name
	enemy_name_label.text = enemy.enemy_data.display_name
	_update_player_hp_label()
	enemy_hp_label.text = "HP %d / %d" % [enemy.current_hp, enemy.enemy_data.max_hp]
	selected_build_label.text = "선택한 빌드: %s — %s\n런 보너스: 공격력 +%d / 주사위 강화 +%d" % [build.display_name, build.description, RunState.attack_bonus, RunState.unlocked_dice_bonus]
	_set_action_buttons_for_build(build)
	var dice_count: int = 3 + RunState.unlocked_dice_bonus
	for dice_index in dice_count:
		dice_states.append(DiceRuntimeState.new(dice_data))
	build_selection_panel.hide()
	restart_build_button.hide()
	_start_turn("%s을(를) 선택했습니다. 현재 런 빌드 상태를 적용했습니다." % build.display_name)

func _update_player_hp_label() -> void:
	player_hp_label.text = "HP %d / %d" % [player.current_hp, player.player_data.max_hp]

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
	healing_dice_button.disabled = true
	attack_button.disabled = true
	status_label.text = "주사위를 잠그거나 리롤할 수 있습니다."
	_show_combat_feedback("🎲 주사위를 굴렸습니다.")

func _on_reroll_button_pressed() -> void:
	if not dice_roller.reroll(dice_states):
		return
	dice_roll_panel.display_results(dice_states)
	dice_roll_panel.play_roll_feedback()
	reroll_button.disabled = true
	status_label.text = "리롤을 사용했습니다. 결과를 확정할 수 있습니다."
	_show_combat_feedback("↻ 리롤 완료")

func _on_confirm_button_pressed() -> void:
	if not dice_roller.confirm_results(dice_states):
		return
	AudioManager.play_confirm()
	dice_roll_panel.set_dice_interaction_enabled(false)
	reroll_button.disabled = true
	confirm_button.disabled = true
	calculated_attack_damage = _calculate_attack_damage()
	ability_button.disabled = not ability.can_use(dice_states)
	healing_dice_button.disabled = healing_dice_data == null or healing_dice_used
	attack_button.disabled = false
	status_label.text = "결과를 확정했습니다: 공격력 %d" % calculated_attack_damage
	_show_combat_feedback("⚡ 공격력 %d 확정" % calculated_attack_damage, Color(1.0, 0.84, 0.35, 1.0))

func _on_ability_button_pressed() -> void:
	var bonus := ability.calculate_bonus(dice_states)
	if bonus <= 0:
		ability_button.disabled = true
		return
	AudioManager.play_confirm()
	calculated_attack_damage += bonus
	ability_button.disabled = true
	status_label.text = "%s 사용: 공격력 +%d (총 %d)" % [ability.ability_data.display_name, bonus, calculated_attack_damage]
	_show_combat_feedback("✨ %s +%d" % [ability.ability_data.display_name, bonus], Color(0.7, 0.9, 1.0, 1.0))
