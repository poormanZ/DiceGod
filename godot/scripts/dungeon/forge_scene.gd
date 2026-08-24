class_name DungeonForgeScene
extends ForgeUI

func _ready() -> void:
	setup(RunState)
	closed.connect(_return_to_dungeon)
	forge_completed.connect(_on_forge_completed)

func _on_forge_completed(_die_index: int, _face_index: int, _symbol_id: int) -> void:
	await get_tree().create_timer(0.5).timeout
	_return_to_dungeon()

func _return_to_dungeon() -> void:
	RunState.resolve_event("forge_done")
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
