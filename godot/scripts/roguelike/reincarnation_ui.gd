class_name ReincarnationUI
extends Control

signal confirmed
signal cancelled

var run_state: RunStateManager
var selected_die: int = -1
var selected_legacies: Array[String] = []
var info_label: Label
var dice_grid: GridContainer
var legacy_grid: GridContainer
var confirm_button: Button

func setup(state: RunStateManager) -> void:
	run_state = state
	selected_legacies = run_state.selected_legacies.duplicate()
	_build_ui()
	_refresh()

func _build_ui() -> void:
	for child in get_children(): child.queue_free()
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	scroll.add_child(root)
	var title: Label = Label.new()
	title.text = "☠️ 이번 생은 끝났다"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info_label)
	var legacy_title: Label = Label.new()
	legacy_title.text = "유산 선택"
	legacy_title.add_theme_font_size_override("font_size", 22)
	root.add_child(legacy_title)
	var legacy_hint: Label = Label.new()
	legacy_hint.text = "유산은 전투력 대신 다음 런의 선택지를 확장합니다."
	legacy_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(legacy_hint)
	legacy_grid = GridContainer.new()
	legacy_grid.columns = 2
	root.add_child(legacy_grid)
	var die_title: Label = Label.new()
	die_title.text = "주사위 기록"
	die_title.add_theme_font_size_override("font_size", 22)
	root.add_child(die_title)
	var hint: Label = Label.new()
	hint.text = "주사위는 기록으로만 남으며 다음 런의 전투력을 직접 계승하지 않습니다."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)
	dice_grid = GridContainer.new()
	dice_grid.columns = 3
	root.add_child(dice_grid)
	confirm_button = Button.new()
	confirm_button.pressed.connect(_on_confirm)
	root.add_child(confirm_button)

func _refresh() -> void:
	if run_state == null: return
	for child in dice_grid.get_children(): child.queue_free()
	for child in legacy_grid.get_children(): child.queue_free()
	var options: Array[Dictionary] = ReincarnationSystem.get_inheritable_dice(run_state)
	for option in options:
		var index: int = int(option.get("index", -1))
		var die_button: Button = Button.new()
		die_button.custom_minimum_size = Vector2(220, 100)
		die_button.text = _format_die(option)
		die_button.pressed.connect(_select_die.bind(index))
		if selected_die == index: die_button.modulate.a = 0.65
		dice_grid.add_child(die_button)
	var unlocked: Array[Dictionary] = LegacySystem.get_unlocked()
	for legacy: Dictionary in unlocked:
		var legacy_id: String = str(legacy.get("id", ""))
		var legacy_button: Button = Button.new()
		legacy_button.custom_minimum_size = Vector2(320, 90)
		legacy_button.text = "%s\n%s" % [str(legacy.get("name", "유산")), str(legacy.get("description", ""))]
		legacy_button.pressed.connect(_toggle_legacy.bind(legacy_id))
		legacy_button.disabled = not LegacySystem.can_select(legacy_id, selected_legacies) and not selected_legacies.has(legacy_id)
		if selected_legacies.has(legacy_id): legacy_button.modulate.a = 0.65
		legacy_grid.add_child(legacy_button)
	var slot_count: int = maxi(0, ProgressionState.legacy_slots)
	var selected_text: String = "없음" if selected_legacies.is_empty() else ", ".join(selected_legacies)
	info_label.text = "유산 슬롯: %d | 선택: %d/%d | %s" % [slot_count, selected_legacies.size(), slot_count, selected_text]
	confirm_button.text = "선택한 유산으로 다음 생 시작" if slot_count > 0 else "다음 생 시작"
	confirm_button.disabled = slot_count > 0 and selected_legacies.is_empty()

func _format_die(option: Dictionary) -> String:
	var faces: Array = option.get("faces", [])
	var parts: Array[String] = []
	for face in faces: parts.append(ForgeSystem.get_symbol_name(int(face)))
	return "%s\n%s" % [str(option.get("name", "주사위")), " | ".join(parts)]

func _select_die(index: int) -> void:
	selected_die = index
	ReincarnationSystem.select_die_for_reincarnation(run_state, index)
	_refresh()

func _toggle_legacy(legacy_id: String) -> void:
	if selected_legacies.has(legacy_id):
		selected_legacies.erase(legacy_id)
	else:
		LegacySystem.select(legacy_id, selected_legacies)
	_refresh()

func _on_confirm() -> void:
	var slot_count: int = maxi(0, ProgressionState.legacy_slots)
	if slot_count > 0 and selected_legacies.is_empty(): return
	if selected_legacies.size() > slot_count: return
	run_state.set_selected_legacies(selected_legacies)
	if selected_die >= 0 and not ReincarnationSystem.confirm(run_state): return
	confirmed.emit()
