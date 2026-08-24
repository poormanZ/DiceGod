class_name GamblingUI
extends Control

signal completed

var run_state: RunStateManager
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var selected: Array[int] = []
var info_label: Label
var dice_grid: GridContainer
var wager_spin: SpinBox
var play_button: Button

func setup(state: RunStateManager) -> void:
	run_state = state
	rng.randomize()
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
	title.text = "🎰 신의 주사위"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info_label)
	dice_grid = GridContainer.new()
	dice_grid.columns = 3
	root.add_child(dice_grid)
	wager_spin = SpinBox.new()
	wager_spin.min_value = GamblingSystem.MIN_WAGER
	wager_spin.max_value = GamblingSystem.MAX_WAGER
	wager_spin.step = 10
	wager_spin.value = GamblingSystem.MIN_WAGER
	root.add_child(wager_spin)
	play_button = Button.new()
	play_button.text = "주사위 3개 굴리기"
	play_button.pressed.connect(_play)
	root.add_child(play_button)
	var close_button: Button = Button.new()
	close_button.text = "도박장 나가기"
	close_button.pressed.connect(func() -> void: completed.emit())
	root.add_child(close_button)

func _refresh() -> void:
	if run_state == null:
		return
	for child in dice_grid.get_children():
		child.queue_free()
	for die_index in run_state.run_dice_faces.size():
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(180, 60)
		button.text = "주사위 %d%s" % [die_index + 1, " ✓" if selected.has(die_index) else ""]
		button.pressed.connect(_toggle_die.bind(die_index))
		dice_grid.add_child(button)
	info_label.text = "골드: %dG | 주사위 3개 선택 | 베팅: %dG" % [run_state.gold, int(wager_spin.value) if wager_spin else GamblingSystem.MIN_WAGER]
	play_button.disabled = selected.size() != 3 or run_state.gold < int(wager_spin.value)

func _toggle_die(index: int) -> void:
	if selected.has(index):
		selected.erase(index)
	elif selected.size() < 3:
		selected.append(index)
	_refresh()

func _play() -> void:
	var result: Dictionary = GamblingSystem.play(run_state, int(wager_spin.value), selected, rng)
	if bool(result.get("success", false)):
		info_label.text = "결과: %s | 굴림 %s | 총합 %d | 획득 %dG" % [str(result.get("result", "")), str(result.get("rolls", [])), int(result.get("total", 0)), int(result.get("payout", 0))]
	selected.clear()
	_refresh()
