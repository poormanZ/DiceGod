class_name DungeonGamblingScene
extends GamblingUI

func _ready() -> void:
	setup(RunState)
	completed.connect(_return_to_dungeon)

func _return_to_dungeon() -> void:
	RunState.resolve_event("gamble_done")
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
