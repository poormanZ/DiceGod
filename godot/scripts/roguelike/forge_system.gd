class_name ForgeSystem
extends RefCounted

const FORGE_COST: int = 35
const SYMBOL_NAMES: Dictionary = {
	1: "⚔️ 검",
	2: "🏹 활",
	3: "杖 지팡이",
	4: "✦ 표창",
	5: "🛡️ 방패",
	6: "✚ 힐",
}

static func get_symbol_name(symbol_id: int) -> String:
	return str(SYMBOL_NAMES.get(symbol_id, "알 수 없음"))

static func get_symbol_ids() -> Array[int]:
	return [1, 2, 3, 4, 5, 6]

static func can_modify(run_state: RunStateManager, die_index: int, face_index: int) -> bool:
	return run_state.can_forge() and die_index >= 0 and die_index < run_state.run_dice_faces.size() and face_index >= 0 and face_index < RunStateManager.DICE_FACE_COUNT and run_state.gold >= FORGE_COST

static func modify_face(run_state: RunStateManager, die_index: int, face_index: int, symbol_id: int) -> Dictionary:
	if not can_modify(run_state, die_index, face_index):
		return {"success": false, "message": "대장간 사용 조건을 만족하지 않습니다."}
	if not SYMBOL_NAMES.has(symbol_id):
		return {"success": false, "message": "선택할 수 없는 심볼입니다."}
	var success: bool = run_state.forge_change_face(die_index, face_index, symbol_id, FORGE_COST)
	if not success:
		return {"success": false, "message": "골드가 부족하거나 이미 대장간을 사용했습니다."}
	return {"success": true, "message": "%s 심볼로 변경했습니다." % get_symbol_name(symbol_id), "cost": FORGE_COST, "symbol_id": symbol_id}

static func describe_die(run_state: RunStateManager, die_index: int) -> Array[String]:
	var result: Array[String] = []
	for face in run_state.get_die_faces(die_index):
		result.append(get_symbol_name(int(face)))
	return result
