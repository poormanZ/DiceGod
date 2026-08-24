class_name ReincarnationUI
extends Control

signal confirmed
signal cancelled

var run_state: RunStateManager
var selected_die: int = -1
var info_label: Label
var dice_grid: GridContainer
var confirm_button: Button

func setup(state: RunStateManager) -> void:
	run_state = state
	_build_ui()
	_refresh()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var title: Label = Label.new()
	title.text = "☠️ 이번 생은 끝났다"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info_label)
	var hint: Label = Label.new()
	hint.text = "보유 주사위 중 정확히 하나를 선택해 다음 환생으로 가져갑니다."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)
	dice_grid = GridContainer.new()
	dice_grid.columns = 3
	root.add_child(dice_grid)
	confirm_button = Button.new()
	confirm_button.text = "이 주사위를 다음 생으로 가져가기"
	confirm_button.disabled = true
	confirm_button.pressed.connect(_on_confirm)
	root.add_child(confirm_button)

func _refresh() -> void:
	if run_state == null:
		return
	for child in dice_grid.get_children():
		child.queue_free()
	var options: Array[Dictionary] = ReincarnationSystem.get_inheritable_dice(run_state)
	for option in options:
		var index: int = int(option.get("index", -1))
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(220, 100)
		button.text = _format_die(option)
		button.pressed.connect(_select_die.bind(index))
		dice_grid.add_child(button)
	var selected_text: String = "없음"
	if selected_die >= 0:
		selected_text = "주사위 %d" % (selected_die + 1)
	info_label.text = "계승 선택: %s | 계승 1/1" % selected_text
	confirm_button.disabled = selected_die < 0

func _format_die(option: Dictionary) -> String:
	var faces: Array = option.get("faces", [])
	var parts: Array[String] = []
	for face in faces:
		parts.append(ForgeSystem.get_symbol_name(int(face)))
	return "%s\n%s" % [str(option.get("name", "주사위")), " | ".join(parts)]

func _select_die(index: int) -> void:
	selected_die = index
	ReincarnationSystem.select_die_for_reincarnation(run_state, index)
	_refresh()

func _on_confirm() -> void:
	if selected_die < 0:
		return
	if ReincarnationSystem.confirm(run_state):
		confirmed.emit()
