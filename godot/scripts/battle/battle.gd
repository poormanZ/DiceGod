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

const STARTING_DICE_COUNT: int = 6

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
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s\n%s" % [build.display_name, build.description]
		button.add_theme_font_size_override("font_size", 14)
		var locked: bool = build == power_build and not ProgressionState.is_dice_unlocked("power_dice")
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
	RunState.initialize_run_dice(dice_data.face_values)
	player_name_label.text = player.player_data.display_name
	enemy_name_label.text = enemy.enemy_data.display_name
	_update_player_hp_label()
	enemy_hp_label.text = "HP %d / %d" % [enemy.current_hp, enemy.enemy_data.max_hp]
	_update_enemy_intent_display()
	selected_build_label.text = "선택한 빌드: %s — %s\n⚔️ 공격  🛡️ 방어  ✚ 치료" % [build.display_name, build.description]
	_set_action_buttons_for_build(build)
	for die_index in STARTING_DICE_COUNT:
		var persistent_dice_data: DiceData = dice_data.duplicate(true) as DiceData
		persistent_dice_data.face_values = PackedInt32Array(RunState.get_die_faces(die_index))
		dice_states.append(DiceRuntimeState.new(persistent_dice_data))
	build_selection_panel.hide()
	restart_build_button.hide()
	_start_turn("%s을(를) 선택했습니다. 6개의 주사위를 굴려 행동 심볼을 만드세요." % build.display_name)

func _update_enemy_intent_display() -> void:
	if enemy == null or enemy_name_label == null:
		return
	var intent_text: int = enemy.get_attack_intent()
	var enemy_hint: Label = get_node_or_null("MarginContainer/Content/EnemyArea/EnemyHint") as Label
	if enemy_hint != null:
		enemy_hint.text = "⚠️ 다음 공격: %d" % intent_text

func _update_player_hp_label() -> void:
	player_hp_label.text = "HP %d / %d" % [player.current_hp, player.player_data.max_hp]

func _update_damage_preview() -> void:
	if enemy == null or player == null or not enemy.has_planned_attack():
		return
	var incoming: int = enemy.planned_attack_damage
	var mitigation: int = calculated_block + calculated_shield
	var expected_damage: int = maxi(0, incoming - mitigation)
	var preview: String = "⚠️ 적 공격 %d  |  🛡️ 방어 %d  + 보호 %d  |  예상 피해 %d" % [incoming, calculated_block, calculated_shield, expected_damage]
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
	tween.tween_property(control, "scale", Vector2.ONE, duration)
	tween.parallel().tween_property(control, "modulate", Color.WHITE, duration)
