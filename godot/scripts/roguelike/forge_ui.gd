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
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(info_label)

	var dice_title: Label = Label.new()
	dice_title.text = "🎲 주사위 선택 — 현재 6면을 확인하세요"
	dice_title.add_theme_font_size_override("font_size", 18)
	root.add_child(dice_title)

	die_grid = GridContainer.new()
	die_grid.columns = 3
	die_grid.add_theme_constant_override("h_separation", 8)
	die_grid.add_theme_constant_override("v_separation", 8)
	root.add_child(die_grid)

	var face_title: Label = Label.new()
	face_title.text = "① 변경할 면 선택 — 숫자 대신 실제 심볼을 표시합니다"
	face_title.add_theme_font_size_override("font_size", 17)
	root.add_child(face_title)

	face_grid = GridContainer.new()
	face_grid.columns = 6
	face_grid.add_theme_constant_override("h_separation", 6)
	root.add_child(face_grid)

	var symbol_title: Label = Label.new()
	symbol_title.text = "② 변경할 심볼 선택"
	symbol_title.add_theme_font_size_override("font_size", 17)
	root.add_child(symbol_title)

	symbol_grid = GridContainer.new()
	symbol_grid.columns = 6
	symbol_grid.add_theme_constant_override("h_separation", 6)
	root.add_child(symbol_grid)

	confirm_button = Button.new()
	confirm_button.text = "35G로 심볼 변경"
	confirm_button.custom_minimum_size = Vector2(0, 48)
	confirm_button.pressed.connect(_on_confirm)
	root.add_child(confirm_button)

	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(0, 42)
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
		button.text = _format_die_card(die_index)
		button.tooltip_text = "주사위 %d의 현재 6면" % (die_index + 1)
		button.custom_minimum_size = Vector2(210, 92)
		button.toggle_mode = true
		button.button_pressed = die_index == selected_die
		button.pressed.connect(_select_die.bind(die_index))
		die_grid.add_child(button)

	var current_faces: Array = []
	if selected_die >= 0:
		current_faces = run_state.get_die_faces(selected_die)
	for face_index in RunStateManager.DICE_FACE_COUNT:
		var face_button: Button = Button.new()
		var face_symbol: String = "?"
		if face_index < current_faces.size():
			face_symbol = DiceData.symbol_for(int(current_faces[face_index]))
		face_button.text = "%s\n면 %d" % [face_symbol, face_index + 1]
		face_button.tooltip_text = "현재 심볼: %s" % face_symbol
		face_button.disabled = selected_die < 0
		face_button.custom_minimum_size = Vector2(92, 68)
		face_button.toggle_mode = true
		face_button.button_pressed = face_index == selected_face
		face_button.pressed.connect(_select_face.bind(face_index))
		face_grid.add_child(face_button)

	for symbol_id in ForgeSystem.get_symbol_ids():
		var symbol_button: Button = Button.new()
		var symbol: String = DiceData.symbol_for(symbol_id)
		symbol_button.text = "%s\n%s" % [symbol, _symbol_short_name(symbol_id)]
		symbol_button.tooltip_text = ForgeSystem.get_symbol_name(symbol_id)
		symbol_button.disabled = selected_face < 0
		symbol_button.custom_minimum_size = Vector2(100, 68)
		symbol_button.toggle_mode = true
		symbol_button.button_pressed = symbol_id == selected_symbol
		symbol_button.pressed.connect(_select_symbol.bind(symbol_id))
		symbol_grid.add_child(symbol_button)

	var selected_text: String = "주사위를 선택하세요."
	if selected_die >= 0:
		selected_text = "주사위 %d 선택" % (selected_die + 1)
	if selected_face >= 0:
		var selected_faces: Array = run_state.get_die_faces(selected_die)
		var current_symbol: String = DiceData.symbol_for(int(selected_faces[selected_face])) if selected_face < selected_faces.size() else "?"
		selected_text += " → 면 %d [%s]" % [selected_face + 1, current_symbol]
	if selected_symbol >= 0:
		selected_text += " → %s" % DiceData.symbol_for(selected_symbol)

	var level: int = 0
	if selected_die >= 0 and selected_face >= 0:
		level = run_state.get_face_upgrade_level(selected_die, selected_face)
	var upgrade_cost: int = 50 + level * 25
	info_label.text = "골드: %dG | %s | 현재 강화 +%d" % [run_state.gold, selected_text, level]
	confirm_button.disabled = not ForgeSystem.can_modify(run_state, selected_die, selected_face) or selected_symbol < 0
	upgrade_button.text = "%dG로 선택한 면 강화 (+1)" % upgrade_cost
	upgrade_button.disabled = selected_die < 0 or selected_face < 0 or run_state.gold < upgrade_cost

func _format_die_card(die_index: int) -> String:
	var lines: Array[String] = ["🎲 주사위 %d" % (die_index + 1)]
	var faces: Array = run_state.get_die_faces(die_index)
	for row_start in [0, 3]:
		var row: String = ""
		for offset in 3:
			var face_index: int = row_start + offset
			if face_index < faces.size():
				row += DiceData.symbol_for(int(faces[face_index])) + " "
		lines.append(row.strip_edges())
	return "\n".join(lines)

func _symbol_short_name(symbol_id: int) -> String:
	match symbol_id:
		1: return "검"
		2: return "활"
		3: return "지팡이"
		4: return "표창"
		5: return "방패"
		6: return "힐"
	return "심볼"

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
