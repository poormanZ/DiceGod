class_name DiceRollPanel
extends PanelContainer

@onready var dice_buttons: Array[Button] = [
	$Content/DiceContainer/DiceOneButton,
	$Content/DiceContainer/DiceTwoButton,
	$Content/DiceContainer/DiceThreeButton,
]
var dice_states: Array[DiceRuntimeState] = []

const DICE_IDLE_SCALE := Vector2.ONE
const DICE_POP_SCALE := Vector2(1.08, 1.08)
const DICE_LOCK_SCALE := Vector2(1.04, 1.04)
const FEEDBACK_SCALE := Vector2(1.12, 1.12)

func _ready() -> void:
	for index in dice_buttons.size():
		dice_buttons[index].pressed.connect(_on_dice_button_pressed.bind(index))
		dice_buttons[index].pivot_offset = dice_buttons[index].size * 0.5

func display_results(new_dice_states: Array[DiceRuntimeState]) -> void:
	dice_states = new_dice_states
	for index in dice_buttons.size():
		_refresh_dice_button(index)

func set_dice_interaction_enabled(is_enabled: bool) -> void:
	for index in dice_buttons.size():
		var can_interact := is_enabled and index < dice_states.size() and dice_states[index].has_result()
		dice_buttons[index].disabled = not can_interact

func play_roll_feedback() -> void:
	AudioManager.play_roll()
	for index in dice_buttons.size():
		var button := dice_buttons[index]
		button.scale = DICE_POP_SCALE
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", DICE_IDLE_SCALE, 0.18 + index * 0.03)

func play_attack_feedback() -> void:
	AudioManager.play_attack()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for button in dice_buttons:
		button.scale = DICE_IDLE_SCALE
		tween.parallel().tween_property(button, "scale", DICE_POP_SCALE, 0.08)
	tween.tween_interval(0.05)
	for button in dice_buttons:
		tween.parallel().tween_property(button, "scale", DICE_IDLE_SCALE, 0.14)

func play_damage_feedback(_damage: int) -> void:
	var flash_color := Color(1.0, 0.35, 0.25, 1.0)
	for button in dice_buttons:
		button.modulate = flash_color
		button.scale = FEEDBACK_SCALE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for button in dice_buttons:
		tween.parallel().tween_property(button, "scale", DICE_IDLE_SCALE, 0.16)
		tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.22)

func _on_dice_button_pressed(index: int) -> void:
	if index >= dice_states.size():
		return
	dice_states[index].toggle_lock()
	AudioManager.play_lock()
	_refresh_dice_button(index)
	var button := dice_buttons[index]
	button.scale = DICE_LOCK_SCALE if dice_states[index].is_locked else DICE_IDLE_SCALE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", DICE_IDLE_SCALE, 0.14)

func _refresh_dice_button(index: int) -> void:
	var dice_button := dice_buttons[index]
	if index >= dice_states.size() or not dice_states[index].has_result():
		dice_button.disabled = true
		dice_button.text = "—"
		dice_button.tooltip_text = "주사위를 굴린 뒤 잠글 수 있습니다."
		dice_button.modulate = Color.WHITE
		return
	var dice_state := dice_states[index]
	dice_button.disabled = false
	dice_button.text = dice_state.get_symbol()
	dice_button.tooltip_text = "%s · %s" % [dice_state.get_name(), "잠금 해제" if dice_state.is_locked else "잠금"]
	dice_button.modulate = Color(1.0, 0.84, 0.35, 1.0) if dice_state.is_locked else Color.WHITE
	dice_button.scale = DICE_IDLE_SCALE
