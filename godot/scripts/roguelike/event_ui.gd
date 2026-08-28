class_name RoguelikeEventUI
extends Control

signal resolved(event_type: String)
signal skipped

var run_state: RunStateManager
var title_label: Label
var info_label: Label
var options_box: VBoxContainer

func setup(state: RunStateManager, stage: int) -> void:
	run_state = state
	run_state.begin_event(stage)
	_build_ui()
	_show_fixed_event()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	title_label = Label.new()
	title_label.text = "🎲 런 이벤트"
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

func _show_fixed_event() -> void:
	for child in options_box.get_children():
		child.queue_free()
	var event_type: String = run_state.current_event_type
	if event_type.is_empty():
		event_type = run_state.get_route_event(run_state.event_stage)
	if event_type.is_empty():
		info_label.text = "진행할 이벤트가 없습니다."
		return
	run_state.choose_event(event_type)
	info_label.text = "골드: %dG | 이벤트 %d/2" % [run_state.gold, run_state.event_stage]

	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(500, 90)
	button.text = _event_name(event_type)
	button.pressed.connect(_choose.bind(event_type))
	options_box.add_child(button)

func _choose(event_type: String) -> void:
	if run_state == null or run_state.event_resolved:
		return
	run_state.choose_event(event_type)
	match event_type:
		"camp":
			var before_hp: int = run_state.current_hp
			var healed: int = run_state.heal(run_state.max_hp)
			if healed <= 0:
				info_label.text = "캠프 — 이미 HP가 가득 찼습니다."
			else:
				info_label.text = "캠프 — HP %d → %d (+%d)" % [before_hp, run_state.current_hp, healed]
			run_state.resolve_event("camp_heal_%d" % healed)
		"shop":
			run_state.resolve_event("shop_open")
			info_label.text = "상점이 열렸습니다."
		"forge":
			run_state.resolve_event("forge_open")
			info_label.text = "대장간이 열렸습니다."
		"gamble":
			run_state.resolve_event("gamble_open")
			info_label.text = "도박장이 열렸습니다."
		"shrine":
			var shrine_result: Dictionary = RoguelikeEventSystem.shrine(run_state)
			info_label.text = "신전 — %s" % str(shrine_result.get("result", "결과 없음"))
			run_state.resolve_event("shrine_%s" % str(shrine_result.get("success", false)))
		"mystery":
			var mystery_rng: RandomNumberGenerator = RandomNumberGenerator.new()
			mystery_rng.randomize()
			var mystery_result: Dictionary = RoguelikeEventSystem.mystery(run_state, mystery_rng)
			info_label.text = "수수께끼 — %s" % str(mystery_result.get("result", "결과 없음"))
			run_state.resolve_event("mystery_%s" % str(mystery_result.get("roll", 0)))
	resolved.emit(event_type)

func _skip() -> void:
	if run_state == null or run_state.event_resolved:
		return
	run_state.skip_event()
	skipped.emit()

func _event_name(event_type: String) -> String:
	match event_type:
		"camp": return "캠프 — HP 회복"
		"shop": return "상점 — 장비 / 주사위 구매"
		"forge": return "대장간 — 주사위 면 수정"
		"gamble": return "도박장 — 주사위 도박"
		"shrine": return "신전 — HP를 바쳐 골드 획득"
		"mystery": return "수수께끼 — 결과를 알 수 없음"
	return event_type
