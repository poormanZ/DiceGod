class_name ReincarnationSystem
extends RefCounted

static func get_inheritable_dice(run_state: RunStateManager) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for die_index in run_state.run_dice_faces.size():
		result.append({"index": die_index, "faces": run_state.get_die_faces(die_index), "name": "주사위 %d" % (die_index + 1)})
	return result

static func select_die_for_reincarnation(run_state: RunStateManager, die_index: int) -> bool:
	if die_index < 0 or die_index >= run_state.run_dice_faces.size():
		return false
	var faces: Array = run_state.get_die_faces(die_index)
	if faces.size() != RunStateManager.DICE_FACE_COUNT:
		return false
	run_state.prepare_inheritance(faces, "환생 주사위 %d" % (die_index + 1), die_index)
	return true

static func confirm(run_state: RunStateManager) -> bool:
	if run_state.pending_inheritance_die.is_empty():
		return false
	run_state.confirm_inheritance()
	return true

static func cancel(run_state: RunStateManager) -> void:
	run_state.clear_pending_inheritance()
