extends SceneTree

## 현재 DiceGod 기준의 최소 실행 검증입니다.
## 구형 빌드/장비/특수 주사위 시스템을 직접 참조하지 않습니다.

func _init() -> void:
	# SceneTree._init() 시점에는 project.godot의 autoload 노드가
	# 아직 root에 모두 등록되지 않을 수 있으므로 한 프레임 뒤에 검증합니다.
	call_deferred("_run_validation")

func _run_validation() -> void:
	var root: Node = get_root()
	var run_state: RunStateManager = root.get_node_or_null("RunState") as RunStateManager
	if run_state == null:
		_fail("RunState autoload is missing")
		return

	_assert(RunStateManager.STARTING_DICE_COUNT == 6, "run uses six dice")
	_assert(RunStateManager.DICE_FACE_COUNT == 6, "dice has six faces")

	run_state.start_new_run()
	var dice_data_script: GDScript = load("res://scripts/dice/dice_data.gd") as GDScript
	_assert(dice_data_script != null, "DiceData script loads")
	var dice_data: Resource = dice_data_script.new() as Resource
	_assert(dice_data != null, "DiceData resource can be instantiated")

	run_state.initialize_run_dice(PackedInt32Array([1, 2, 3, 4, 5, 6]))
	_assert(run_state.run_dice_faces.size() == RunStateManager.STARTING_DICE_COUNT, "run starts with six dice")
	for faces: Array in run_state.run_dice_faces:
		_assert(faces.size() == RunStateManager.DICE_FACE_COUNT, "every die has six faces")

	_assert(not run_state.is_alive() or run_state.current_hp > 0, "run state is valid")
	print("DiceGod roadmap validation: PASS")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	push_error("Roadmap validation failed: " + message)
	quit(1)
