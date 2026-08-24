class_name RoguelikeEventUI
extends Control

signal resolved(event_type: String)
signal skipped

var run_state: RunStateManager
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var title_label: Label
var info_label: Label
var options_box: VBoxContainer

func setup(state: RunStateManager, stage: int) -> void:
	run_state = state
	run_state.begin_event(stage)
	rng.randomize()
	_build_ui()
	_show_options()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	title_label = Label.new()
	title_label.text = "🎲 랜덤 이벤트"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	root.add_child(title_label)
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info_label)
	options_box = VBoxContainer.new()
	root.add_child(options_box)
	var skip_button: Button = Button.new()
	skip_button.text = "이벤트 스킵"
	skip_button.pressed.connect(_skip)
	root.add_child(skip_button)

func _show_options() -> void:
	for child in options_box.get_children():
		child.queue_free()
	var options: Array[String] = RoguelikeEventSystem.roll_event_options(rng)
	run_state.set_event_options(options)
	info_label.text = "골드: %dG | 이벤트 %d/2" % [run_state.gold, run_state.event_stage]
	for event_type in options:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(400, 70)
		button.text = _event_name(event_type)
		button.pressed.connect(_choose.bind(event_type))
		options_box.add_child(button)

func _choose(event_type: String) -> void:
	run_state.choose_event(event_type)
	match event_type:
		"camp":
			var healed: int = RoguelikeEventSystem.camp_heal(run_state)
			run_state.resolve_event("camp_heal_%d" % healed)
			info_label.text = "⛺ 캠프에서 HP %d 회복" % healed
		"shop":
			run_state.resolve_event("shop_open")
			info_label.text = "🏪 상점이 열렸습니다."
		"forge":
			run_state.resolve_event("forge_open")
			info_label.text = "🔨 대장간이 열렸습니다."
		"gamble":
			run_state.resolve_event("gamble_open")
			info_label.text = "🎰 도박장이 열렸습니다."
	resolved.emit(event_type)

func _skip() -> void:
	run_state.skip_event()
	skipped.emit()

func _event_name(event_type: String) -> String:
	match event_type:
		"camp": return "⛺ 캠프 — HP 회복"
		"shop": return "🏪 상점 — 장비 / 주사위 구매"
		"forge": return "🔨 대장간 — 주사위 면 수정"
		"gamble": return "🎰 도박장 — 주사위 도박"
	return event_type
