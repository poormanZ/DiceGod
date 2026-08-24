class_name RunStatusOverlay
extends PanelContainer

## 현재 런의 주사위/장비 상태를 던전과 모든 전투 화면에서 확인하는 공용 패널.
## RunState를 직접 읽기 때문에 주사위 수정 결과가 다음 페이즈에도 즉시 반영됩니다.

var content_box: VBoxContainer
var summary_label: Label
var dice_label: Label
var equipment_label: Label
var close_button: Button
var refresh_button: Button

const EQUIPMENT_SLOTS: Array[String] = ["머리", "몸통", "다리", "신발", "무기", "목걸이", "반지"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(360, 500)
	size_flags_horizontal = Control.SIZE_SHRINK_END
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	z_index = 100
	_add_ui()
	_refresh()

func _add_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	content_box = VBoxContainer.new()
	content_box.add_theme_constant_override("separation", 8)
	margin.add_child(content_box)

	var title: Label = Label.new()
	title.text = "📋 현재 런 상태"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(title)

	summary_label = Label.new()
	summary_label.add_theme_font_size_override("font_size", 15)
	content_box.add_child(summary_label)

	var dice_title: Label = Label.new()
	dice_title.text = "🎲 주사위 상태"
	dice_title.add_theme_font_size_override("font_size", 18)
	content_box.add_child(dice_title)

	dice_label = Label.new()
	dice_label.add_theme_font_size_override("font_size", 15)
	dice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(dice_label)

	var separator: HSeparator = HSeparator.new()
	content_box.add_child(separator)

	var equipment_title: Label = Label.new()
	equipment_title.text = "🛡️ 장비 상태"
	equipment_title.add_theme_font_size_override("font_size", 18)
	content_box.add_child(equipment_title)

	equipment_label = Label.new()
	equipment_label.add_theme_font_size_override("font_size", 15)
	equipment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(equipment_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	content_box.add_child(button_row)

	refresh_button = Button.new()
	refresh_button.text = "↻ 새로고침"
	refresh_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refresh_button.pressed.connect(_refresh)
	button_row.add_child(refresh_button)

	close_button = Button.new()
	close_button.text = "닫기"
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.pressed.connect(_close_panel)
	button_row.add_child(close_button)

func _refresh() -> void:
	if not is_instance_valid(dice_label):
		return
	var summary: Dictionary = RunState.get_run_summary()
	summary_label.text = "런 %d  |  ❤️ %d/%d  |  💰 %dG" % [
		int(summary.get("run_number", 0)),
		int(summary.get("current_hp", 0)),
		int(summary.get("max_hp", 0)),
		int(summary.get("gold", 0))
	]

	var dice_lines: Array[String] = ["보유 주사위: %d/%d" % [RunState.run_dice_faces.size(), RunState.STARTING_DICE_COUNT]]
	for die_index: int in RunState.run_dice_faces.size():
		var faces: Array = RunState.get_die_faces(die_index)
		var symbols: Array[String] = []
		for face_index: int in faces.size():
			var value: int = int(faces[face_index])
			var symbol: String = _symbol_for_value(value)
			var upgrade: int = RunState.get_face_upgrade_level(die_index, face_index)
			if upgrade > 0:
				symbol += "+%d" % upgrade
			symbols.append(symbol)
		dice_lines.append("주사위 %d  %s" % [die_index + 1, "  ".join(symbols)])
	dice_label.text = "\n".join(dice_lines)

	var equipped: Array = RunState.equipped_items
	var equipment_lines: Array[String] = []
	for slot_index: int in EQUIPMENT_SLOTS.size():
		var item_text: String = "비어 있음"
		if slot_index < equipped.size():
			var item_id: String = str(equipped[slot_index])
			if not item_id.is_empty():
				item_text = item_id
		equipment_lines.append("%s  :  %s" % [EQUIPMENT_SLOTS[slot_index], item_text])
	equipment_label.text = "\n".join(equipment_lines)

func _symbol_for_value(value: int) -> String:
	if value >= 101:
		match value:
			101: return "✨"
			102: return "💥"
			103: return "👁️"
			104: return "💚"
			105: return "🔥"
			106: return "🛡️✨"
			107: return "🍀"
			108: return "💀"
		return "❔"
	return DiceData.symbol_for(value)

func _close_panel() -> void:
	visible = false

static func attach(parent: Control) -> RunStatusOverlay:
	var existing: Node = parent.get_node_or_null("RunStatusOverlay")
	if existing is RunStatusOverlay:
		return existing as RunStatusOverlay

	var overlay: RunStatusOverlay = RunStatusOverlay.new()
	overlay.name = "RunStatusOverlay"
	parent.add_child(overlay)
	overlay.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	overlay.offset_left = -382.0
	overlay.offset_right = -18.0
	overlay.offset_top = 68.0
	overlay.offset_bottom = 568.0
	overlay.visible = false

	var toggle: Button = Button.new()
	toggle.name = "RunStatusToggle"
	toggle.text = "📋 상태"
	toggle.custom_minimum_size = Vector2(110, 40)
	toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toggle.offset_left = -128.0
	toggle.offset_right = -18.0
	toggle.offset_top = 18.0
	toggle.offset_bottom = 58.0
	toggle.z_index = 101
	parent.add_child(toggle)
	toggle.pressed.connect(func() -> void:
		overlay.visible = not overlay.visible
		if overlay.visible:
			overlay._refresh()
	)
	return overlay
