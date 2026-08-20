class_name DiceRollPanel
extends PanelContainer

@onready var dice_buttons: Array[Button] = [
	$Content/DiceContainer/DiceOneButton,
	$Content/DiceContainer/DiceTwoButton,
	$Content/DiceContainer/DiceThreeButton,
]
var dice_states: Array[DiceRuntimeState] = []


func _ready() -> void:
	for index in dice_buttons.size():
		dice_buttons[index].pressed.connect(_on_dice_button_pressed.bind(index))


func display_results(new_dice_states: Array[DiceRuntimeState]) -> void:
	dice_states = new_dice_states
	for index in dice_buttons.size():
		_refresh_dice_button(index)


func set_dice_interaction_enabled(is_enabled: bool) -> void:
	for index in dice_buttons.size():
		var can_interact := is_enabled and index < dice_states.size() and dice_states[index].has_result()
		dice_buttons[index].disabled = not can_interact


func _on_dice_button_pressed(index: int) -> void:
	if index >= dice_states.size():
		return

	dice_states[index].toggle_lock()
	_refresh_dice_button(index)


func _refresh_dice_button(index: int) -> void:
	var dice_button := dice_buttons[index]
	if index >= dice_states.size() or not dice_states[index].has_result():
		dice_button.disabled = true
		dice_button.text = "-"
		dice_button.tooltip_text = "주사위를 굴린 뒤 잠글 수 있습니다."
		return

	var dice_state := dice_states[index]
	dice_button.disabled = false
	dice_button.text = str(dice_state.result)
	dice_button.tooltip_text = "잠금 해제" if dice_state.is_locked else "잠금"
	dice_button.modulate = Color(1.0, 0.84, 0.35, 1.0) if dice_state.is_locked else Color.WHITE
