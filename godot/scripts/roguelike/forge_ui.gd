class_name ForgeUI
extends Control

signal forge_completed(die_index: int, face_index: int, symbol_id: int)
signal upgraded(die_index: int, face_index: int, level: int)
signal closed

const UPGRADE_BASE_COST: int = 50
const UPGRADE_COST_PER_LEVEL: int = 25
const ICON_DICE: Texture2D = preload("res://assets/ui/icon_dice.svg")
const ICON_SWORD: Texture2D = preload("res://assets/ui/icon_sword.svg")
const ICON_BOW: Texture2D = preload("res://assets/ui/icon_bow.svg")
const ICON_STAFF: Texture2D = preload("res://assets/ui/icon_staff.svg")
const ICON_SHURIKEN: Texture2D = preload("res://assets/ui/icon_shuriken.svg")
const ICON_SHIELD: Texture2D = preload("res://assets/ui/icon_shield.svg")
const ICON_HEAL: Texture2D = preload("res://assets/ui/icon_heal.svg")

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

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 12.0
	scroll.offset_right = -12.0
	scroll.offset_top = 8.0
	scroll.offset_bottom = -8.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 4)
	scroll.add_child(root)

	var title: Label = Label.new()
	title.text = "대장간"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.custom_minimum_size = Vector2(0, 30)
	root.add_child(title)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(0, 30)
	root.add_child(info_label)

	var dice_title: Label = Label.new()
	dice_title.text = "주사위 선택 — 현재 6면"
	dice_title.add_theme_font_size_override("font_size", 16)
	dice_title.custom_minimum_size = Vector2(0, 20)
	root.add_child(dice_title)

	die_grid = GridContainer.new()
	die_grid.columns = 3
	die_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	die_grid.add_theme_constant_override("h_separation", 6)
	die_grid.add_theme_constant_override("v_separation", 4)
	root.add_child(die_grid)

	var face_title: Label = Label.new()
	face_title.text = "① 변경할 면 선택"
	face_title.add_theme_font_size_override("font_size", 15)
	face_title.custom_minimum_size = Vector2(0, 18)
	root.add_child(face_title)

	face_grid = GridContainer.new()
	face_grid.columns = 6
	face_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	face_grid.add_theme_constant_override("h_separation", 4)
	root.add_child(face_grid)

	var symbol_title: Label = Label.new()
	symbol_title.text = "② 변경할 심볼 선택"
	symbol_title.add_theme_font_size_override("font_size", 15)
	symbol_title.custom_minimum_size = Vector2(0, 18)
	root.add_child(symbol_title)

	symbol_grid = GridContainer.new()
	symbol_grid.columns = 6
	symbol_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	symbol_grid.add_theme_constant_override("h_separation", 4)
	root.add_child(symbol_grid)

	# ScrollContainer가 콘텐츠가 길어질 경우에도 이 영역까지 접근할 수 있게 한다.
	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_theme_constant_override("separation", 6)
	root.add_child(action_row)

	confirm_button = Button.new()
	confirm_button.text = "35G로 심볼 변경"
	confirm_button.custom_minimum_size = Vector2(0, 38)
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_button.pressed.connect(_on_confirm)
	action_row.add_child(confirm_button)

	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(0, 38)
	upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_button.pressed.connect(_on_upgrade)
	action_row.add_child(upgrade_button)

	var close_button: Button = Button.new()
	close_button.text = "나가기"
	close_button.custom_minimum_size = Vector2(0, 34)
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		button.icon = ICON_DICE
		button.tooltip_text = "주사위 %d의 현재 6면" % (die_index + 1)
		button.custom_minimum_size = Vector2(0, 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_pressed = die_index == selected_die
		button.pressed.connect(_select_die.bind(die_index))
		die_grid.add_child(button)

	var current_faces: Array = []
	if selected_die >= 0:
		current_faces = run_state.get_die_faces(selected_die)
	for face_index in RunStateManager.DICE_FACE_COUNT:
		var face_button: Button = Button.new()
		var symbol_id: int = int(current_faces[face_index]) if face_index < current_faces.size() else 0
		face_button.text = "면 %d\n%s" % [face_index + 1, _symbol_name(symbol_id)]
		face_button.icon = _icon_for_symbol(symbol_id)
		face_button.tooltip_text = "현재 심볼: %s" % _symbol_name(symbol_id)
		face_button.disabled = selected_die < 0
		face_button.custom_minimum_size = Vector2(0, 50)
		face_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		face_button.toggle_mode = true
		face_button.button_pressed = face_index == selected_face
		face_button.pressed.connect(_select_face.bind(face_index))
		face_grid.add_child(face_button)

	for symbol_id in ForgeSystem.get_symbol_ids():
		var symbol_button: Button = Button.new()
		symbol_button.text = DiceData.name_for(symbol_id)
		symbol_button.icon = _icon_for_symbol(symbol_id)
		symbol_button.tooltip_text = ForgeSystem.get_symbol_name(symbol_id)
		symbol_button.disabled = selected_face < 0
		symbol_button.custom_minimum_size = Vector2(0, 50)
		symbol_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		symbol_button.toggle_mode = true
		symbol_button.button_pressed = symbol_id == selected_symbol
		symbol_button.pressed.connect(_select_symbol.bind(symbol_id))
		symbol_grid.add_child(symbol_button)

	var selected_text: String = "주사위를 선택하세요."
	if selected_die >= 0:
		selected_text = "주사위 %d 선택" % (selected_die + 1)
	if selected_face >= 0:
		var selected_faces: Array = run_state.get_die_faces(selected_die)
		var current_symbol_id: int = int(selected_faces[selected_face]) if selected_face < selected_faces.size() else 0
		selected_text += " → 면 %d [%s]" % [selected_face + 1, _symbol_name(current_symbol_id)]
	if selected_symbol >= 0:
		selected_text += " → %s" % ForgeSystem.get_symbol_name(selected_symbol)

	var level: int = 0
	if selected_die >= 0 and selected_face >= 0:
		level = run_state.get_face_upgrade_level(selected_die, selected_face)
	var upgrade_cost: int = _upgrade_cost(level)
	info_label.text = "골드: %dG | %s | 현재 강화 +%d" % [run_state.gold, selected_text, level]
	confirm_button.disabled = not ForgeSystem.can_modify(run_state, selected_die, selected_face) or selected_symbol < 0
	upgrade_button.text = "%dG로 선택한 면 강화 (+1)" % upgrade_cost
	upgrade_button.disabled = selected_die < 0 or selected_face < 0 or run_state.gold < upgrade_cost

func _format_die_card(die_index: int) -> String:
	var lines: Array[String] = ["주사위 %d" % (die_index + 1)]
	var faces: Array = run_state.get_die_faces(die_index)
	for row_start in [0, 3]:
		var row: String = ""
		for offset in 3:
			var face_index: int = row_start + offset
			if face_index < faces.size():
				row += _symbol_name(int(faces[face_index])) + " "
		lines.append(row.strip_edges())
	return "\n".join(lines)

func _symbol_name(symbol_id: int) -> String:
	return ForgeSystem.get_symbol_name(symbol_id) if ForgeSystem.get_symbol_ids().has(symbol_id) else "미지"

func _icon_for_symbol(symbol_id: int) -> Texture2D:
	match symbol_id:
		1: return ICON_SWORD
		2: return ICON_BOW
		3: return ICON_STAFF
		4: return ICON_SHURIKEN
		5: return ICON_SHIELD
		6: return ICON_HEAL
	return ICON_DICE

func _upgrade_cost(level: int) -> int:
	return UPGRADE_BASE_COST + level * UPGRADE_COST_PER_LEVEL

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
	var cost: int = _upgrade_cost(level)
	if run_state.upgrade_die_face(selected_die, selected_face, cost):
		upgraded.emit(selected_die, selected_face, level + 1)
		_refresh()

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
