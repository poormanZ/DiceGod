class_name DivineRewardUI
extends Control

signal completed

var run_state: RunStateManager
var boss_id: String = ""
var selected_die: int = -1
var selected_face: int = -1
var info_label: Label
var die_grid: GridContainer
var face_grid: GridContainer
var confirm_button: Button

func setup(state: RunStateManager, defeated_boss_id: String) -> void:
	run_state = state
	boss_id = defeated_boss_id
	DivineRewardSystem.unlock_boss_symbol(run_state, boss_id)
	_build_ui()
	_refresh()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var reward: Dictionary = DivineRewardSystem.get_boss_reward(boss_id)
	var boss_reward: Dictionary = BossRewardSystem.get_reward(boss_id)
	var title: Label = Label.new()
	title.text = "👑 보스 처치 보상 — %s" % str(reward.get("name", "신"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)
	var reward_label: Label = Label.new()
	reward_label.text = "%s\n%s\n\n🔨 보스 전용 장비: %s\n🎲 보스 전용 주사위: %s\n\n주사위의 면 하나를 이 신성 심볼로 각인할 수 있습니다." % [str(reward.get("display", "")), str(reward.get("description", "")), str(boss_reward.get("gear", "")), str(boss_reward.get("die_name", "특수 주사위"))]
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(reward_label)
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info_label)
	die_grid = GridContainer.new()
	die_grid.columns = 3
	root.add_child(die_grid)
	face_grid = GridContainer.new()
	face_grid.columns = 6
	root.add_child(face_grid)
	confirm_button = Button.new()
	confirm_button.text = "선택한 면에 신성 심볼 각인"
	confirm_button.disabled = true
	confirm_button.pressed.connect(_on_confirm)
	root.add_child(confirm_button)

func _refresh() -> void:
	if run_state == null:
		return
	for child in die_grid.get_children():
		child.queue_free()
	for child in face_grid.get_children():
		child.queue_free()
	for die_index in run_state.run_dice_faces.size():
		var die_button: Button = Button.new()
		die_button.text = "주사위 %d" % (die_index + 1)
		die_button.custom_minimum_size = Vector2(180, 50)
		die_button.pressed.connect(_select_die.bind(die_index))
		die_grid.add_child(die_button)
	for face_index in RunStateManager.DICE_FACE_COUNT:
		var face_button: Button = Button.new()
		face_button.text = "면 %d" % (face_index + 1)
		face_button.disabled = selected_die < 0
		face_button.pressed.connect(_select_face.bind(face_index))
		face_grid.add_child(face_button)
	var selection: String = "주사위/면을 선택하세요."
	if selected_die >= 0 and selected_face >= 0:
		selection = "주사위 %d / 면 %d 선택" % [selected_die + 1, selected_face + 1]
	info_label.text = selection
	confirm_button.disabled = selected_die < 0 or selected_face < 0

func _select_die(index: int) -> void:
	selected_die = index
	selected_face = -1
	_refresh()

func _select_face(index: int) -> void:
	selected_face = index
	_refresh()

func _on_confirm() -> void:
	if selected_die < 0 or selected_face < 0:
		return
	var result: Dictionary = DivineRewardSystem.imprint(run_state, selected_die, selected_face, boss_id)
	if bool(result.get("success", false)):
		completed.emit()
