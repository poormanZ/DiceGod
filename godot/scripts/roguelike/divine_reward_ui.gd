class_name DivineRewardUI
extends Control

signal completed

const GOLD_REWARD: int = 100
const UI_ICON_PATH: String = "res://assets/ui/"
const DICE_ICON_PATH: String = "res://assets/icons/dice/"

var run_state: RunStateManager
var boss_id: String = ""
var selected_die: int = -1
var selected_face: int = -1
var selected_mode: String = ""
var info_label: Label
var die_grid: GridContainer
var face_grid: GridContainer
var imprint_button: Button
var gold_button: Button

func setup(state: RunStateManager, defeated_boss_id: String) -> void:
	run_state = state
	boss_id = defeated_boss_id
	DivineRewardSystem.unlock_boss_symbol(run_state, boss_id)
	_build_ui()
	_refresh()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 14.0
	scroll.offset_right = -14.0
	scroll.offset_top = 8.0
	scroll.offset_bottom = -8.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 5)
	scroll.add_child(root)

	var reward: Dictionary = DivineRewardSystem.get_boss_reward(boss_id)
	var boss_reward: Dictionary = BossRewardSystem.get_reward(boss_id)
	var reward_name: String = str(reward.get("name", "신"))
	var reward_symbol: String = _boss_symbol_name(str(reward.get("symbol", "")))

	var title: Label = Label.new()
	title.text = "보스 처치 보상 — %s" % reward_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.custom_minimum_size = Vector2(0, 30)
	title.add_theme_icon_override("icon", _load_ui_icon("icon_boss.svg"))
	root.add_child(title)

	var reward_label: Label = Label.new()
	reward_label.text = "%s\n%s\n보스 장비: %s | 特殊 주사위: %s" % [reward_symbol, str(reward.get("description", "")), str(boss_reward.get("gear", "")), str(boss_reward.get("die_name", "특수 주사위"))]
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_label.custom_minimum_size = Vector2(0, 42)
	root.add_child(reward_label)

	var choice_label: Label = Label.new()
	choice_label.text = "보상을 하나 선택하세요 — 신성 심볼 각인 또는 골드 +%d G" % GOLD_REWARD
	choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_label.custom_minimum_size = Vector2(0, 22)
	root.add_child(choice_label)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(0, 26)
	root.add_child(info_label)

	var dice_title: Label = Label.new()
	dice_title.text = "현재 주사위 — 각인할 주사위 선택"
	dice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_title.custom_minimum_size = Vector2(0, 20)
	dice_title.add_theme_icon_override("icon", _load_ui_icon("icon_dice.svg"))
	root.add_child(dice_title)

	die_grid = GridContainer.new()
	die_grid.columns = 3
	die_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	die_grid.add_theme_constant_override("h_separation", 5)
	die_grid.add_theme_constant_override("v_separation", 4)
	root.add_child(die_grid)

	var face_title: Label = Label.new()
	face_title.text = "① 각인할 주사위 면 선택"
	face_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face_title.custom_minimum_size = Vector2(0, 20)
	root.add_child(face_title)

	face_grid = GridContainer.new()
	face_grid.columns = 6
	face_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	face_grid.add_theme_constant_override("h_separation", 3)
	root.add_child(face_grid)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_theme_constant_override("separation", 6)
	root.add_child(action_row)

	imprint_button = Button.new()
	imprint_button.text = "선택한 면에 %s 각인" % reward_symbol
	imprint_button.icon = _load_ui_icon("icon_divine.svg")
	imprint_button.custom_minimum_size = Vector2(0, 42)
	imprint_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	imprint_button.disabled = true
	imprint_button.pressed.connect(_on_imprint)
	action_row.add_child(imprint_button)

	gold_button = Button.new()
	gold_button.text = "골드 +%d G 획득" % GOLD_REWARD
	gold_button.icon = _load_ui_icon("icon_coin.svg")
	gold_button.custom_minimum_size = Vector2(0, 42)
	gold_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gold_button.pressed.connect(_on_gold)
	action_row.add_child(gold_button)

func _refresh() -> void:
	if run_state == null:
		return
	for child in die_grid.get_children():
		child.queue_free()
	for child in face_grid.get_children():
		child.queue_free()

	for die_index in run_state.run_dice_faces.size():
		var die_button: Button = Button.new()
		die_button.text = _format_die_text(die_index)
		die_button.icon = _load_ui_icon("icon_dice.svg")
		die_button.custom_minimum_size = Vector2(0, 72)
		die_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		die_button.toggle_mode = true
		die_button.button_pressed = die_index == selected_die
		die_button.pressed.connect(_select_die.bind(die_index))
		die_grid.add_child(die_button)

	if selected_die >= 0 and selected_die < run_state.run_dice_faces.size():
		var faces: Array = run_state.get_die_faces(selected_die)
		for face_index in RunStateManager.DICE_FACE_COUNT:
			var face_button: Button = Button.new()
			face_button.text = _symbol_for_face(faces[face_index])
			face_button.icon = _icon_for_face(faces[face_index])
			face_button.custom_minimum_size = Vector2(0, 48)
			face_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			face_button.toggle_mode = true
			face_button.button_pressed = face_index == selected_face
			face_button.pressed.connect(_select_face.bind(face_index))
			face_grid.add_child(face_button)

	var selection: String = "주사위를 선택하면 각인할 면을 고를 수 있습니다."
	if selected_die >= 0:
		selection = "주사위 %d 선택" % (selected_die + 1)
	if selected_die >= 0 and selected_face >= 0:
		var current_faces: Array = run_state.get_die_faces(selected_die)
		selection = "주사위 %d / 면 %d [%s] 선택" % [selected_die + 1, selected_face + 1, _symbol_for_face(current_faces[selected_face])]
	info_label.text = selection

	imprint_button.disabled = selected_die < 0 or selected_face < 0 or selected_mode == "gold"
	gold_button.disabled = selected_mode == "imprint"

func _format_die_text(die_index: int) -> String:
	var faces: Array = run_state.get_die_faces(die_index)
	var lines: Array[String] = []
	for index: int in faces.size():
		lines.append(_symbol_for_face(faces[index]))
	var first_row: String = " ".join(lines.slice(0, mini(3, lines.size())))
	var second_row: String = ""
	if lines.size() > 3:
		second_row = "\n" + " ".join(lines.slice(3, lines.size()))
	return "주사위 %d\n%s%s" % [die_index + 1, first_row, second_row]

func _symbol_for_face(value: Variant) -> String:
	match int(value):
		1: return "검"
		2: return "활"
		3: return "지팡이"
		4: return "표창"
		5: return "방패"
		6: return "회복"
		101: return "골드"
		102: return "폭발"
		103: return "역병"
		104: return "혈액"
		105: return "폭풍"
		106: return "강화 방패"
		107: return "운명"
		108: return "죽음"
		201: return "화염"
		202: return "빙결"
		203: return "역병"
		204: return "혈액"
		205: return "폭풍"
		206: return "거암"
		207: return "운명"
		208: return "공허"
	return "알 수 없음"

func _icon_for_face(value: Variant) -> Texture2D:
	match int(value):
		1: return _load_dice_icon("sword.svg")
		2: return _load_dice_icon("bow.svg")
		3: return _load_dice_icon("staff.svg")
		4: return _load_dice_icon("shuriken.svg")
		5: return _load_dice_icon("shield.svg")
		6: return _load_dice_icon("heal.svg")
		101, 102, 103, 104, 105, 106, 107, 108, 201, 202, 203, 204, 205, 206, 207, 208:
			return _load_ui_icon("icon_divine.svg")
	return null

func _boss_symbol_name(symbol_id: String) -> String:
	match symbol_id:
		"flame": return "화염"
		"frost": return "빙결"
		"plague": return "역병"
		"blood": return "혈액"
		"storm": return "폭풍"
		"stone": return "거암"
		"fate": return "운명"
		"void": return "공허"
	return "신성 심볼"

func _load_ui_icon(file_name: String) -> Texture2D:
	return load(UI_ICON_PATH + file_name) as Texture2D

func _load_dice_icon(file_name: String) -> Texture2D:
	return load(DICE_ICON_PATH + file_name) as Texture2D

func _select_die(index: int) -> void:
	if selected_mode != "":
		return
	selected_die = index
	selected_face = -1
	_refresh()

func _select_face(index: int) -> void:
	if selected_mode != "":
		return
	selected_face = index
	_refresh()

func _on_imprint() -> void:
	if selected_die < 0 or selected_face < 0 or run_state == null:
		return
	var result: Dictionary = DivineRewardSystem.imprint(run_state, selected_die, selected_face, boss_id)
	if not bool(result.get("success", false)):
		info_label.text = str(result.get("message", "각인에 실패했습니다."))
		return
	selected_mode = "imprint"
	info_label.text = "각인 완료! 이 주사위의 변경은 이번 런에서만 유지됩니다."
	_refresh()
	completed.emit()

func _on_gold() -> void:
	if run_state == null or selected_mode != "":
		return
	run_state.add_gold(GOLD_REWARD)
	selected_mode = "gold"
	info_label.text = "골드 +%d G 획득!" % GOLD_REWARD
	_refresh()
	completed.emit()
