class_name RunStatusOverlay
extends PanelContainer

const ICON_DICE: Texture2D = preload("res://assets/ui/icon_dice.svg")
const ICON_SHIELD: Texture2D = preload("res://assets/ui/icon_shield.svg")
const EQUIPMENT_SLOTS: Array[String] = ["머리", "몸통", "다리", "신발", "무기", "목걸이", "반지"]
const EQUIPMENT_KEYS: Array[String] = ["head", "body", "legs", "feet", "weapon", "neck", "ring"]

var content_box: VBoxContainer
var summary_label: Label
var dice_label: Label
var equipment_label: Label
var equipment_actions: VBoxContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(360, 500)
	size_flags_horizontal = Control.SIZE_SHRINK_END
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	z_index = 100
	_add_ui()
	_refresh()

func _add_ui() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	scroll.add_child(margin)
	content_box = VBoxContainer.new()
	content_box.add_theme_constant_override("separation", 6)
	margin.add_child(content_box)
	var title: Label = Label.new()
	title.text = "현재 런 상태"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	content_box.add_child(title)
	summary_label = Label.new()
	summary_label.add_theme_font_size_override("font_size", 15)
	content_box.add_child(summary_label)
	var dice_title: Label = Label.new()
	dice_title.text = "주사위 상태"
	dice_title.add_theme_font_size_override("font_size", 18)
	content_box.add_child(dice_title)
	dice_label = Label.new()
	dice_label.add_theme_font_size_override("font_size", 14)
	dice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(dice_label)
	var equipment_title: Label = Label.new()
	equipment_title.text = "장비 상태 — 부위당 1개"
	equipment_title.add_theme_font_size_override("font_size", 18)
	content_box.add_child(equipment_title)
	equipment_label = Label.new()
	equipment_label.add_theme_font_size_override("font_size", 14)
	content_box.add_child(equipment_label)
	equipment_actions = VBoxContainer.new()
	equipment_actions.add_theme_constant_override("separation", 3)
	content_box.add_child(equipment_actions)
	var close_button: Button = Button.new()
	close_button.text = "닫기"
	close_button.custom_minimum_size = Vector2(0, 36)
	close_button.pressed.connect(func() -> void: visible = false)
	content_box.add_child(close_button)

func _refresh() -> void:
	if not is_instance_valid(dice_label): return
	var summary: Dictionary = RunState.get_run_summary()
	summary_label.text = "런 %d | HP %d/%d | 골드 %dG" % [int(summary.get("run_number", 0)), int(summary.get("current_hp", 0)), int(summary.get("max_hp", 0)), int(summary.get("gold", 0))]
	var dice_lines: Array[String] = ["보유 주사위: %d/%d" % [RunState.run_dice_faces.size(), DiceData.STARTING_DICE_COUNT]]
	for die_index: int in RunState.run_dice_faces.size():
		var faces: Array = RunState.get_die_faces(die_index)
		var symbols: Array[String] = []
		for face_index: int in faces.size():
			var symbol: String = _symbol_for_value(int(faces[face_index]))
			var level: int = RunState.get_face_upgrade_level(die_index, face_index)
			if level > 0: symbol += "+%d" % level
			symbols.append(symbol)
		dice_lines.append("주사위 %d: %s" % [die_index + 1, "  ".join(symbols)])
	dice_label.text = "\n".join(dice_lines)
	var lines: Array[String] = []
	for index: int in EQUIPMENT_SLOTS.size():
		var gear_id: String = str(RunState.equipped_by_slot.get(EQUIPMENT_KEYS[index], ""))
		var name: String = "비어 있음"
		if not gear_id.is_empty(): name = str(RoguelikeEquipmentSystem.get_gear(gear_id).get("name", gear_id))
		lines.append("%s: %s" % [EQUIPMENT_SLOTS[index], name])
	equipment_label.text = "\n".join(lines)
	for child in equipment_actions.get_children(): child.queue_free()
	for gear_id: String in RunState.purchased_items:
		var gear: Dictionary = RoguelikeEquipmentSystem.get_gear(gear_id)
		if gear.is_empty(): continue
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = "%s [%s]" % [str(gear.get("name", gear_id)), _slot_name(str(gear.get("slot", "")))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var button: Button = Button.new()
		var slot: String = str(gear.get("slot", ""))
		var equipped_id: String = str(RunState.equipped_by_slot.get(slot, ""))
		button.text = "해제" if equipped_id == gear_id else "장착"
		button.disabled = equipped_id == gear_id and not RoguelikeEquipmentSystem.is_owned(RunState, gear_id)
		button.pressed.connect(_toggle_equipment.bind(gear_id))
		row.add_child(button)
		equipment_actions.add_child(row)

func _toggle_equipment(gear_id: String) -> void:
	var gear: Dictionary = RoguelikeEquipmentSystem.get_gear(gear_id)
	var slot: String = str(gear.get("slot", ""))
	if str(RunState.equipped_by_slot.get(slot, "")) == gear_id:
		RoguelikeEquipmentSystem.unequip(RunState, slot)
	else:
		RoguelikeEquipmentSystem.equip(RunState, gear_id)
	_refresh()

func _slot_name(slot: String) -> String:
	var index: int = EQUIPMENT_KEYS.find(slot)
	return EQUIPMENT_SLOTS[index] if index >= 0 else "기타"

func _symbol_for_value(value: int) -> String:
	if value >= 101:
		match value:
			101: return "강화"
			102: return "치명"
			103: return "감지"
			104: return "회복"
			105: return "화염"
			106: return "수호"
			107: return "행운"
			108: return "저주"
		return "미지"
	return DiceData.name_for(value)

static func attach(parent: Control) -> RunStatusOverlay:
	var existing: Node = parent.get_node_or_null("RunStatusOverlay")
	if existing is RunStatusOverlay: return existing as RunStatusOverlay
	var overlay: RunStatusOverlay = RunStatusOverlay.new()
	overlay.name = "RunStatusOverlay"
	parent.add_child(overlay)
	overlay.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	overlay.offset_left = -382.0
	overlay.offset_right = -18.0
	overlay.offset_top = 68.0
	overlay.offset_bottom = 620.0
	overlay.visible = false
	var toggle: Button = Button.new()
	toggle.name = "RunStatusToggle"
	toggle.text = "상태"
	toggle.icon = ICON_DICE
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
		if overlay.visible: overlay._refresh()
	)
	return overlay
