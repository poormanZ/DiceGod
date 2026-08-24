class_name DungeonForgeScene
extends ForgeUI

func _ready() -> void:
	setup(RunState)
	closed.connect(_return_to_dungeon)

func _return_to_dungeon() -> void:
	RunState.resolve_event("forge_done")
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
