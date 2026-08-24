class_name DungeonReincarnationScene
extends ReincarnationUI

func _ready() -> void:
	setup(RunState)
	confirmed.connect(_start_reincarnation)
	cancelled.connect(_cancel_selection)

func _start_reincarnation() -> void:
	RunState.start_new_run()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _cancel_selection() -> void:
	ReincarnationSystem.cancel(RunState)
