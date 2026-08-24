class_name RunStatusOverlay
extends PanelContainer

## 현재 런의 영구 상태를 보여주는 접이식 상태 패널.
## 주사위 면은 RunState.run_dice_faces를 직접 읽기 때문에
## 대장간/보상/이벤트/전투를 넘어 변경 사항이 유지됩니다.

var content_box: VBoxContainer
var dice_label: Label
var equipment_label: Label
var close_button: Button
var refresh_button: Button

const EQUIPMENT_SLOTS: Array[String] = ["머리", "몸통", "다리", "신발", "무기", "목걸이", "반지"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(360, 420)
	size_flags_horizontal = Control.SIZE_SHRINK_END
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
	content_box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "다음 페이즈에도 유지되는 상태"
	content_box.add_child(subtitle)

	dice_label = Label.new()
	dice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(dice_label)

	var separator: HSeparator = HSeparator.new()
	content_box.add_child(separator)

	equipment_label = Label.new()
	equipment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(equipment_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	content_box.add_child(button_row)

	refresh_button = Button.new()
	refresh_button.text = "↻ 새로고침"
	refresh_button.pressed.connect(_refresh)
	button_row.add_child(refresh_button)

	close_button = Button.new()
	close_button.text = "닫기"
	close_button.pressed.connect(_close_panel)
	button_row.add_child(close_button)

func _refresh() -> void:
	if not is_instance_valid(dice_label):
		return
	var dice_lines: Array[String] = ["🎲 주사위 상태 (%d/6)" % RunState.run_dice_faces.size()]
	for die_index: int in RunState.run_dice_faces.size():
		var faces: Array = RunState.get_die_faces(die_index)
		var symbols: Array[String] = []
		for face_index: int in faces.size():
			var value: int = int(faces[face_index])
			var symbol: String = DiceData.symbol_for(value)
			var upgrade: int = RunState.get_face_upgrade_level(die_index, face_index)
			if upgrade > 0:
				symbol += "+%d" % upgrade
			symbols.append(symbol)
		dice_lines.append("주사위 %d  %s" % [die_index + 1, " ".join(symbols)])
	dice_label.text = "\n".join(dice_lines)

	var equipped: Array = RunState.equipped_items
	var equipment_lines: Array[String] = ["🛡️ 장비 상태"]
	for slot_index: int in EQUIPMENT_SLOTS.size():
		var item_text: String = "비어 있음"
		if slot_index < equipped.size() and not str(equipped[slot_index]).is_empty():
			item_text = str(equipped[slot_index])
		equipment_lines.append("%s  :  %s" % [EQUIPMENT_SLOTS[slot_index], item_text])
	equipment_label.text = "\n".join(equipment_lines)

func _close_panel() -> void:
	queue_free()

static func attach(parent: Control) -> RunStatusOverlay:
	var overlay: RunStatusOverlay = RunStatusOverlay.new()
	overlay.name = "RunStatusOverlay"
	parent.add_child(overlay)
	overlay.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	overlay.position = Vector2(-380, 72)
	overlay.visible = false

	var toggle: Button = Button.new()
	toggle.name = "RunStatusToggle"
	toggle.text = "📋 상태"
	toggle.custom_minimum_size = Vector2(110, 40)
	parent.add_child(toggle)
	toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toggle.position = Vector2(-122, 18)
	toggle.pressed.connect(func() -> void:
		overlay.visible = not overlay.visible
		if overlay.visible:
			overlay._refresh()
	)
	return overlay
