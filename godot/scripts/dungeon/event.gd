class_name DungeonEvent
extends Control

@onready var title_label: Label = $MarginContainer/Content/TitleLabel
@onready var description_label: Label = $MarginContainer/Content/DescriptionLabel
@onready var risky_button: Button = $MarginContainer/Content/Choices/RiskyButton
@onready var safe_button: Button = $MarginContainer/Content/Choices/SafeButton
@onready var skip_button: Button = $MarginContainer/Content/SkipButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var resolved: bool = false

func _ready() -> void:
	# 이벤트 종류는 새 런 시작 시 RunState가 이미 확정한다.
	# 이 화면에서는 이벤트를 선택하지 않고, 확정된 이벤트를 보여준 뒤 실행한다.
	risky_button.hide()
	safe_button.hide()
	skip_button.hide()
	var event_type: String = RunState.current_event_type
	if event_type.is_empty():
		event_type = RunState.get_route_event(RunState.event_stage)
	if event_type.is_empty():
		event_type = "camp"
	RunState.current_event_type = event_type
	RunState.event_id = event_type
	_setup_event(event_type)
	call_deferred("_execute_fixed_event", event_type)

func _setup_event(event_type: String) -> void:
	title_label.text = "🎲 랜덤 이벤트 %d/2" % RunState.event_stage
	description_label.text = "이번 런에서 미리 결정된 이벤트입니다.\n이벤트 종류는 다음 런에서 새롭게 무작위 결정됩니다."
	status_label.text = _event_text(event_type)

func _event_text(event_type: String) -> String:
	match event_type:
		"camp": return "⛺ 캠프\nHP 회복"
		"shop": return "🏪 상점\n장비 / 주사위 구매"
		"forge": return "🔨 대장간\n주사위 면 수정 / 강화"
		"gamble": return "🎰 도박장\n골드 도박"
	return event_type

func _execute_fixed_event(event_type: String) -> void:
	if resolved:
		return
	resolved = true
	RunState.choose_event(event_type)
	match event_type:
		"camp":
			var healed: int = RoguelikeEventSystem.camp_heal(RunState)
			RunState.resolve_event("camp_%d" % healed)
			status_label.text = "⛺ 캠프에서 HP %d 회복" % healed
			await get_tree().create_timer(0.7).timeout
			get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
		"shop":
			RunState.resolve_event("shop_open")
			get_tree().change_scene_to_file("res://scenes/dungeon/shop.tscn")
		"forge":
			RunState.resolve_event("forge_open")
			get_tree().change_scene_to_file("res://scenes/dungeon/forge.tscn")
		"gamble":
			RunState.resolve_event("gamble_open")
			get_tree().change_scene_to_file("res://scenes/dungeon/gambling.tscn")

func _on_risky_button_pressed() -> void:
	pass

func _on_safe_button_pressed() -> void:
	pass

func _on_skip_button_pressed() -> void:
	pass
