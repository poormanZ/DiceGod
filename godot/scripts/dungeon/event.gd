class_name DungeonEvent
extends Control

@onready var title_label: Label = $MarginContainer/Content/TitleLabel
@onready var description_label: Label = $MarginContainer/Content/DescriptionLabel
@onready var risky_button: Button = $MarginContainer/Content/Choices/RiskyButton
@onready var safe_button: Button = $MarginContainer/Content/Choices/SafeButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var resolved: bool = false
var event_type: int = 0

func _ready() -> void:
	event_type = randi_range(0, 2)
	_setup_event()
	status_label.text = "선택하세요."

func _setup_event() -> void:
	match event_type:
		0:
			title_label.text = "EVENT · 수상한 제단"
			description_label.text = "고대의 제단이 당신의 힘을 시험합니다.\n위험을 감수하면 다음 전투에 도움이 될 힘을 얻을 수 있습니다."
			risky_button.text = "힘을 받는다\n다음 전투 공격력 +2"
			safe_button.text = "안전하게 지나간다\n효과 없음"
		1:
			title_label.text = "EVENT · 숨겨진 야영지"
			description_label.text = "폐허 뒤에서 잠시 쉬어갈 수 있는 야영지를 발견했습니다.\n회복하거나 보급품을 챙길 수 있습니다."
			risky_button.text = "휴식을 취한다\nHP +20"
			safe_button.text = "보급품을 챙긴다\n골드 +40"
		2:
			title_label.text = "EVENT · 행운의 제단"
			description_label.text = "빛나는 동전을 발견했습니다.\n당장의 이득과 다음 전투의 준비 중 하나를 선택하세요."
			risky_button.text = "행운을 시험한다\n주사위 강화 +1"
			safe_button.text = "동전을 챙긴다\n골드 +25"

func _resolve_event(result_id: String, result_text: String) -> void:
	if resolved:
		return
	resolved = true
	RunState.event_resolved = true
	RunState.event_id = result_id
	risky_button.disabled = true
	safe_button.disabled = true
	status_label.text = "%s\n%s" % [result_text, RunState.get_run_summary()]
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_risky_button_pressed() -> void:
	match event_type:
		0:
			RunState.attack_bonus += 2
			_resolve_event("power", "힘을 얻었습니다! 다음 전투부터 공격력 +2")
		1:
			RunState.heal(20)
			_resolve_event("rest", "야영지에서 휴식했습니다. HP를 20 회복했습니다.")
		2:
			RunState.unlocked_dice_bonus += 1
			_resolve_event("fortune", "행운이 따랐습니다! 이번 런의 주사위 강화가 +1 증가했습니다.")

func _on_safe_button_pressed() -> void:
	match event_type:
		0:
			_resolve_event("safe", "안전하게 지나갔습니다. 아무런 변화가 없습니다.")
		1:
			RunState.add_gold(40)
			_resolve_event("supplies", "보급품을 챙겼습니다. 골드 +40")
		2:
			RunState.add_gold(25)
			_resolve_event("coin", "빛나는 동전을 챙겼습니다. 골드 +25")
