class_name DivineRewardUI
extends Control

signal completed

const GOLD_REWARD: int = 100

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

	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var reward: Dictionary = DivineRewardSystem.get_boss_reward(boss_id)
	var boss_reward: Dictionary = BossRewardSystem.get_reward(boss_id)

	var title: Label = Label.new()
	title.text = "👑 보스 처치 보상 — %s" % str(reward.get("name", "신"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var reward_label: Label = Label.new()
	reward_label.text = "%s\n%s\n\n🔨 보스 전용 장비: %s\n🎲 보스 전용 주사위: %s" % [str(reward.get("display", "")), str(reward.get("description", "")), str(boss_reward.get("gear", "")), str(boss_reward.get("die_name", "특수 주사위"))]
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(reward_label)

	var choice_label: Label = Label.new()
	choice_label.text = "보상을 하나 선택하세요 — 신성 심볼 각인 또는 골드 +%d G" % GOLD_REWARD
	choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(choice_label)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info_label)

	var dice_title: Label = Label.new()
	dice_title.text = "🎲 현재 주사위 — 실제 심볼 배치"
	dice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(dice_title)

	die_grid = GridContainer.new()
	die_grid.columns = 3
	root.add_child(die_grid)

	var face_title: Label = Label.new()
	face_title.text = "① 각인할 주사위 면 선택"
	face_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(face_title)

	face_grid = GridContainer.new()
	face_grid.columns = 6
	root.add_child(face_grid)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(action_row)

	imprint_button = Button.new()
	imprint_button.text = "🔨 선택한 면에 %s 각인" % str(reward.get("display", "신성 심볼"))
	imprint_button.custom_minimum_size = Vector2(260, 55)
	imprint_button.disabled = true
	imprint_button.pressed.connect(_on_imprint)
	action_row.add_child(imprint_button)

	gold_button = Button.new()
	gold_button.text = "💰 골드 +%d G 획득" % GOLD_REWARD
	gold_button.custom_minimum_size = Vector2(220, 55)
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
		die_button.custom_minimum_size = Vector2(230, 100)
		die_button.pressed.connect(_select_die.bind(die_index))
		die_grid.add_child(die_button)

	if selected_die >= 0 and selected_die < run_state.run_dice_faces.size():
		var faces: Array = run_state.get_die_faces(selected_die)
		for face_index in RunStateManager.DICE_FACE_COUNT:
			var face_button: Button = Button.new()
			face_button.text = _symbol_for_face(faces[face_index])
			face_button.custom_minimum_size = Vector2(80, 55)
			face_button.pressed.connect(_select_face.bind(face_index))
			face_grid.add_child(face_button)

	var selection: String = "주사위를 선택하면 실제 심볼 배치를 확인할 수 있습니다."
	if selected_die >= 0:
		selection = "주사위 %d 선택" % (selected_die + 1)
	if selected_die >= 0 and selected_face >= 0:
		var current_faces: Array = run_state.get_die_faces(selected_die)
		selection = "주사위 %d / 현재 심볼 %s 선택" % [selected_die + 1, _symbol_for_face(current_faces[selected_face])]
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
	return "🎲 주사위 %d\n%s%s" % [die_index + 1, first_row, second_row]

func _symbol_for_face(value: Variant) -> String:
	var face_value: int = int(value)
	match face_value:
		1: return "⚔️"
		2: return "🏹"
		3: return "🔮"
		4: return "🗡️"
		5: return "🛡️"
		6: return "❤️"
		101: return "💰"
		102: return "💥"
		103: return "🔮✨"
		104: return "❤️✨"
		105: return "⚡"
		106: return "🛡️✨"
		107: return "⭐"
		108: return "☠️"
	return "❔"

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
	run_state.persist_completed_run_dice()
	info_label.text = "✅ %s 각인 완료! 이 주사위 변경은 다음 런에도 유지됩니다." % str(result.get("display", "신성 심볼"))
	_refresh()
	completed.emit()

func _on_gold() -> void:
	if run_state == null or selected_mode != "":
		return
	run_state.add_gold(GOLD_REWARD)
	selected_mode = "gold"
	info_label.text = "✅ 골드 +%d G 획득!" % GOLD_REWARD
	_refresh()
	completed.emit()
