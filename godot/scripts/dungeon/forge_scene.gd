class_name DungeonForgeScene
extends ForgeUI

func _ready() -> void:
	# 기존 실행 상태에서 run_dice_faces가 비어 있는 경우를 복구합니다.
	# 새 런은 RunState.start_new_run()에서 초기화되지만,
	# 이전 버전에서 생성된 런도 대장간 진입 시 기본 주사위 6개를 보장합니다.
	if RunState.active_run and RunState.run_dice_faces.is_empty():
		RunState.initialize_run_dice(PackedInt32Array([1, 2, 3, 4, 5, 6]))
	setup(RunState)
	closed.connect(_return_to_dungeon)

func _return_to_dungeon() -> void:
	RunState.resolve_event("forge_done")
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
