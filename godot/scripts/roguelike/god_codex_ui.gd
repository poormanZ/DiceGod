class_name GodCodexUI
extends Control

signal closed

const GODS: Array[String] = ["gambling_god", "battle_god", "wisdom_god", "life_god", "war_god", "guardian_god", "fate_god", "death_god"]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var title: Label = Label.new()
	title.text = "📖 신의 축복 도감"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	root.add_child(grid)
	for god_id in GODS:
		var reward: Dictionary = DivineRewardSystem.get_boss_reward(god_id)
		var unlocked: bool = ProgressionState.unlocked_bosses.has(god_id)
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(360, 80)
		if unlocked:
			button.text = "%s\n%s — %s" % [str(reward.get("name", god_id)), str(reward.get("display", "")), str(reward.get("description", ""))]
		else:
			button.text = "🔒 미해금 신"
		button.disabled = true
		grid.add_child(button)
	var close_button: Button = Button.new()
	close_button.text = "닫기"
	close_button.pressed.connect(_on_close)
	root.add_child(close_button)

func _on_close() -> void:
	closed.emit()
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
