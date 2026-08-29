class_name DungeonEvent
extends Control

@onready var title_label: Label = $MarginContainer/Content/TitleLabel
@onready var description_label: Label = $MarginContainer/Content/DescriptionLabel
@onready var risky_button: Button = $MarginContainer/Content/Choices/RiskyButton
@onready var safe_button: Button = $MarginContainer/Content/Choices/SafeButton
@onready var skip_button: Button = $MarginContainer/Content/SkipButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var resolved: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
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
	title_label.text = "🎲 랜덤 이벤트 %d/2 · %s" % [RunState.event_stage, RoguelikeEventSystem.get_event_title(event_type)]
	description_label.text = "%s\n%s" % [RoguelikeEventSystem.get_event_description(event_type), RoguelikeEventSystem.get_event_risk(event_type)]
	status_label.text = _event_text(event_type)

func _event_text(event_type: String) -> String:
	match event_type:
		"camp": return "⛺ 캠프\n안전한 회복"
		"shop": return "🏪 상점\n장비 / 주사위 구매"
		"forge": return "🔨 대장간\n주사위 면 수정 / 강화"
		"gamble": return "🎰 도박장\n골드 도박"
		"shrine": return "⛩ 신전\nHP를 골드로 교환"
		"mystery": return "❓ 수수께끼\n위험한 랜덤 보상"
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
		"shrine":
			var shrine_result: Dictionary = RoguelikeEventSystem.shrine(RunState)
			RunState.resolve_event("shrine_%s" % ("success" if bool(shrine_result.get("success", false)) else "blocked"))
			status_label.text = "⛩ " + str(shrine_result.get("result", "신전 이벤트 실패"))
			await get_tree().create_timer(0.9).timeout
			get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
		"mystery":
			var mystery_result: Dictionary = RoguelikeEventSystem.mystery(RunState, rng)
			RunState.resolve_event("mystery_%d" % int(mystery_result.get("roll", 0)))
			status_label.text = "❓ " + str(mystery_result.get("result", "수수께끼의 결과를 확인했습니다."))
			await get_tree().create_timer(0.9).timeout
			if not RunState.is_alive():
				get_tree().change_scene_to_file("res://scenes/dungeon/reincarnation.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_risky_button_pressed() -> void:
	pass

func _on_safe_button_pressed() -> void:
	pass

func _on_skip_button_pressed() -> void:
	pass
