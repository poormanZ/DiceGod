class_name DungeonEvent
extends Control

@onready var title_label: Label = $MarginContainer/Content/TitleLabel
@onready var description_label: Label = $MarginContainer/Content/DescriptionLabel
@onready var risky_button: Button = $MarginContainer/Content/Choices/RiskyButton
@onready var safe_button: Button = $MarginContainer/Content/Choices/SafeButton
@onready var skip_button: Button = $MarginContainer/Content/SkipButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var options: Array[String] = []
var resolved: bool = false

func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	options = RoguelikeEventSystem.roll_event_options(rng)
	RunState.set_event_options(options)
	_setup_options()
	status_label.text = "두 개 중 하나를 선택하거나 스킵하세요."

func _setup_options() -> void:
	if options.size() < 2:
		return
	risky_button.text = _event_text(options[0])
	safe_button.text = _event_text(options[1])
	title_label.text = "🎲 랜덤 이벤트 %d/2" % RunState.event_stage
	description_label.text = "이번 이벤트에서 하나를 선택하세요.\n선택한 이벤트는 즉시 실행됩니다."

func _event_text(event_type: String) -> String:
	match event_type:
		"camp": return "⛺ 캠프\nHP 회복"
		"shop": return "🏪 상점\n장비 / 주사위 구매"
		"forge": return "🔨 대장간\n주사위 면 수정 / 강화"
		"gamble": return "🎰 도박장\n보유 주사위로 골드 도박"
	return event_type

func _resolve(event_type: String) -> void:
	if resolved:
		return
	resolved = true
	RunState.choose_event(event_type)
	risky_button.disabled = true
	safe_button.disabled = true
	skip_button.disabled = true
	match event_type:
		"camp":
			var healed: int = RoguelikeEventSystem.camp_heal(RunState)
			RunState.resolve_event("camp_%d" % healed)
			status_label.text = "⛺ 캠프에서 HP %d 회복" % healed
			await get_tree().create_timer(0.5).timeout
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

func _skip() -> void:
	if resolved:
		return
	resolved = true
	RunState.skip_event()
	risky_button.disabled = true
	safe_button.disabled = true
	skip_button.disabled = true
	status_label.text = "이벤트를 스킵했습니다."
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_risky_button_pressed() -> void:
	if options.size() >= 1:
		_resolve(options[0])

func _on_safe_button_pressed() -> void:
	if options.size() >= 2:
		_resolve(options[1])

func _on_skip_button_pressed() -> void:
	_skip()
