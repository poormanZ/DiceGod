class_name DungeonEvent
extends Control

@onready var risky_button: Button = $MarginContainer/Content/Choices/RiskyButton
@onready var safe_button: Button = $MarginContainer/Content/Choices/SafeButton
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var resolved: bool = false

func _ready() -> void:
	status_label.text = "제단 앞에서 선택하세요."

func _resolve_event(result_id: String, result_text: String) -> void:
	if resolved:
		return
	resolved = true
	get_tree().set_meta("dungeon_event_resolved", true)
	get_tree().set_meta("dungeon_event_id", result_id)
	get_tree().set_meta("dungeon_event_attack_bonus", 2 if result_id == "power" else 0)
	risky_button.disabled = true
	safe_button.disabled = true
	status_label.text = result_text
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_risky_button_pressed() -> void:
	_resolve_event("power", "힘을 얻었습니다! 다음 전투에서 공격력 +2")

func _on_safe_button_pressed() -> void:
	_resolve_event("safe", "안전하게 지나갔습니다. 아무런 변화가 없습니다.")
