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
var event_type: String = ""

func _ready() -> void:
	rng.randomize()
	event_type = RunState.current_event_type
	if event_type.is_empty(): event_type = RunState.get_route_event(RunState.event_stage)
	if event_type.is_empty(): event_type = "camp"
	RunState.current_event_type = event_type
	RunState.event_id = event_type
	_setup_event(event_type)
	_setup_choices(event_type)

func _setup_event(type: String) -> void:
	title_label.text = "랜덤 이벤트 %d/2 · %s" % [RunState.event_stage, RoguelikeEventSystem.get_event_title(type)]
	description_label.text = LegacySystem.get_event_preview(RunState.selected_legacies, type, RoguelikeEventSystem.get_event_description(type))
	status_label.text = _event_text(type)
	if LegacySystem.has_effect(RunState.selected_legacies, "event_preview"):
		status_label.text += "\n[역병의 기억] 위험 정보가 공개되었습니다."
	if LegacySystem.has_effect(RunState.selected_legacies, "event_odds") and type == "gamble":
		status_label.text += "\n[운명의 기억] 도박 확률이 공개됩니다."
	if LegacySystem.has_effect(RunState.selected_legacies, "hp_trade_choice") and type == "shrine":
		status_label.text += "\n[혈왕의 기억] HP를 소모하지 않는 대체 선택지가 열립니다."

func _setup_choices(type: String) -> void:
	risky_button.hide()
	safe_button.hide()
	skip_button.hide()
	match type:
		"gamble":
			risky_button.text = "베팅하기 (50G)"
			risky_button.show()
			safe_button.text = "안전하게 지나가기"
			safe_button.show()
			skip_button.text = "포기"
			skip_button.show()
		"shrine":
			risky_button.text = "HP 10 → 120G"
			risky_button.show()
			safe_button.text = "혈왕의 기억: HP 대신 30G"
		if LegacySystem.has_effect(RunState.selected_legacies, "hp_trade_choice"):
			safe_button.show()
			skip_button.text = "지나가기"
			skip_button.show()
		"mystery":
			risky_button.text = "수수께끼를 연다"
			risky_button.show()
			safe_button.text = "안전하게 지나가기 (+20G)"
			safe_button.show()
			skip_button.text = "지나가기"
			skip_button.show()
		_:
			skip_button.text = "확인하고 계속"
			skip_button.show()

func _event_text(type: String) -> String:
	match type:
		"camp": return "캠프\n안전한 회복"
		"shop": return "상점\n장비 / 주사위 구매"
		"forge": return "대장간\n주사위 면 수정 / 강화"
		"gamble": return "도박장\n골드 도박"
		"shrine": return "신전\nHP를 골드로 교환"
		"mystery": return "수수께끼\n위험한 랜덤 보상"
	return type

func _finish(result_text: String) -> void:
	if resolved: return
	resolved = true
	status_label.text = result_text
	RunState.choose_event(event_type)
	RunState.resolve_event("%s_done" % event_type)
	await get_tree().create_timer(0.7).timeout
	if not RunState.is_alive():
		get_tree().change_scene_to_file("res://scenes/dungeon/reincarnation.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_risky_button_pressed() -> void:
	if resolved: return
	match event_type:
		"gamble":
			var result: Dictionary = RoguelikeEventSystem.gamble(RunState, rng, 50)
			_finish("%s · %dG" % [str(result.get("result", "결과 없음")), int(result.get("gold", 0))])
		"shrine":
			var result: Dictionary = RoguelikeEventSystem.shrine(RunState)
			_finish(str(result.get("result", "신전 결과 없음")))
		"mystery":
			var result: Dictionary = RoguelikeEventSystem.mystery(RunState, rng)
			_finish(str(result.get("result", "수수께끼 결과 없음")))
		_: _finish("안전하게 이벤트를 통과했습니다.")

func _on_safe_button_pressed() -> void:
	if resolved: return
	if event_type == "shrine" and LegacySystem.has_effect(RunState.selected_legacies, "hp_trade_choice"):
		if RunState.spend_gold(30):
			_finish("혈왕의 기억으로 HP 대신 30G를 지불했습니다.")
		else:
			status_label.text = "골드가 부족합니다."
		return
	if event_type == "mystery":
		RunState.add_gold(20)
		_finish("안전한 선택: 20G 획득")
	else:
		_finish("안전하게 지나갔습니다.")

func _on_skip_button_pressed() -> void:
	if resolved: return
	_finish("이벤트를 포기하고 지나갔습니다.")
