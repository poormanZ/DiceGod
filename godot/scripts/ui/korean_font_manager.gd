extends Node

const KOREAN_FONT_PATH := "res://fonts/NotoSansKR-Regular.ttf"

var korean_font: Font

func _ready() -> void:
	korean_font = load(KOREAN_FONT_PATH) as Font
	if korean_font == null:
		push_warning("Korean font could not be loaded: %s" % KOREAN_FONT_PATH)
		return

	_apply_to_tree(get_tree().root)
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if korean_font == null:
		return
	if node is Control:
		_apply_to_control(node as Control)

func _apply_to_tree(node: Node) -> void:
	if node is Control:
		_apply_to_control(node as Control)
	for child in node.get_children():
		_apply_to_tree(child)

func _apply_to_control(control: Control) -> void:
	control.add_theme_font_override("font", korean_font)
	if control is Label:
		(control as Label).add_theme_font_override("font", korean_font)
	elif control is Button:
		(control as Button).add_theme_font_override("font", korean_font)
