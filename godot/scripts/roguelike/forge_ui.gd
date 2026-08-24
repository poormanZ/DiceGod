class_name ForgeUI
extends Control

signal forge_completed(die_index: int, face_index: int, symbol_id: int)
signal upgraded(die_index: int, face_index: int, level: int)
signal closed

var run_state: RunStateManager
var selected_die: int = -1
var selected_face: int = -1
var selected_symbol: int = -1
var info_label: Label
var die_grid: GridContainer
var face_grid: GridContainer
var symbol_grid: GridContainer
var confirm_button: Button
var upgrade_button: Button

func setup(state: RunStateManager) -> void:
	run_state = state
	_build_ui()
	_refresh()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var title: Label = Label.new()
	title.text = "🔨 대장간"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info_label)
	var dice_title: Label = Label.new()
	dice_title.text = "주사위 선택"
	root.add_child(dice_title)
	die_grid = GridContainer.new()
	die_grid.columns = 3
	root.add_child(die_grid)
	var face_title: Label = Label.new()
	face_title.text = "수정/강화할 면 선택"
	root.add_child(face_title)
	face_grid = GridContainer.new()
	face_grid.columns = 6
	root.add_child(face_grid)
	var symbol_title: Label = Label.new()
	symbol_title.text = "원하는 심볼 선택"
	root.add_child(symbol_title)
	symbol_grid = GridContainer.new()
	symbol_grid.columns = 6
	root.add_child(symbol_grid)
	confirm_button = Button.new()
	confirm_button.text = "35G로 심볼 변경"
	confirm_button.pressed.connect(_on_confirm)
	root.add_child(confirm_button)
	upgrade_button = Button.new()
	upgrade_button.pressed.connect(_on_upgrade)
	root.add_child(upgrade_button)
	var close_button: Button = Button.new()
	close_button.text = "나가기"
	close_button.pressed.connect(func() -> void: closed.emit())
	root.add_child(close_button)

func _refresh() -> void:
	if run_state == null:
		return
	_clear_container(die_grid)
	_clear_container(face_grid)
	_clear_container(symbol_grid)
	for die_index in run_state.run_dice_faces.size():
		var button: Button = Button.new()
		button.text = "주사위 %d" % (die_index + 1)
		button.custom_minimum_size = Vector2(180, 52)
		button.pressed.connect(_select_die.bind(die_index))
		die_grid.add_child(button)
	for face_index in RunStateManager.DICE_FACE_COUNT:
		var face_button: Button = Button.new()
		face_button.text = "면 %d" % (face_index + 1)
		face_button.disabled = selected_die < 0
		face_button.custom_minimum_size = Vector2(100, 42)
		face_button.pressed.connect(_select_face.bind(face_index))
		face_grid.add_child(face_button)
	for symbol_id in ForgeSystem.get_symbol_ids():
		var symbol_button: Button = Button.new()
		symbol_button.text = ForgeSystem.get_symbol_name(symbol_id)
		symbol_button.disabled = selected_face < 0
		symbol_button.custom_minimum_size = Vector2(150, 42)
		symbol_button.pressed.connect(_select_symbol.bind(symbol_id))
		symbol_grid.add_child(symbol_button)
	var selected_text: String = "주사위를 선택하세요."
	if selected_die >= 0:
		selected_text = "주사위 %d" % (selected_die + 1)
	if selected_face >= 0:
		selected_text += " / 면 %d" % (selected_face + 1)
	if selected_symbol >= 0:
		selected_text += " → " + ForgeSystem.get_symbol_name(selected_symbol)
	var level: int = 0
	if selected_die >= 0 and selected_face >= 0:
		level = run_state.get_face_upgrade_level(selected_die, selected_face)
	var upgrade_cost: int = 50 + level * 25
	info_label.text = "골드: %dG | 대장간 각인: %s | 현재 강화 +%d" % [run_state.gold, selected_text, level]
	confirm_button.disabled = not ForgeSystem.can_modify(run_state, selected_die, selected_face) or selected_symbol < 0
	upgrade_button.text = "%dG로 면 강화 (+1)" % upgrade_cost
	upgrade_button.disabled = selected_die < 0 or selected_face < 0 or run_state.gold < upgrade_cost

func _select_die(index: int) -> void:
	selected_die = index
	selected_face = -1
	selected_symbol = -1
	_refresh()

func _select_face(index: int) -> void:
	selected_face = index
	selected_symbol = -1
	_refresh()

func _select_symbol(symbol_id: int) -> void:
	selected_symbol = symbol_id
	_refresh()

func _on_confirm() -> void:
	var result: Dictionary = ForgeSystem.modify_face(run_state, selected_die, selected_face, selected_symbol)
	if bool(result.get("success", false)):
		forge_completed.emit(selected_die, selected_face, selected_symbol)
		selected_symbol = -1
		_refresh()

func _on_upgrade() -> void:
	if selected_die < 0 or selected_face < 0:
		return
	var level: int = run_state.get_face_upgrade_level(selected_die, selected_face)
	var cost: int = 50 + level * 25
	if run_state.upgrade_die_face(selected_die, selected_face, cost):
		upgraded.emit(selected_die, selected_face, level + 1)
		_refresh()

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
