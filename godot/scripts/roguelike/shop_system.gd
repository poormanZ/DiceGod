class_name RoguelikeShopSystem
extends RefCounted

const ITEMS: Array[Dictionary] = [
	{"id": "dice_reroll", "name": "주사위", "description": "보유 주사위 1개를 새 주사위로 교체", "cost": 80, "type": "dice", "risk": "기존 주사위 하나를 잃습니다."},
	{"id": "iron_armor", "name": "철갑 장비", "description": "몸통 / 최대 HP +15", "cost": 100, "type": "equipment", "risk": "골드를 즉시 소비합니다."},
	{"id": "war_glove", "name": "전투 장갑", "description": "무기 / 공격력 +3", "cost": 120, "type": "equipment", "risk": "골드를 즉시 소비합니다."},
	{"id": "lucky_coin", "name": "행운의 동전", "description": "반지 / 전투 골드 보상 강화", "cost": 140, "type": "equipment", "risk": "초기 투자 비용이 가장 큽니다."}
]

static func get_inventory() -> Array[Dictionary]:
	return ITEMS.duplicate(true)

static func get_item(item_id: String) -> Dictionary:
	for item in ITEMS:
		if str(item.get("id", "")) == item_id: return item.duplicate(true)
	return {}

static func get_inventory_for_run(run_state: RunStateManager) -> Array[Dictionary]:
	var result: Array[Dictionary] = get_inventory()
	if run_state == null or not run_state.has_legacy_effect("special_shop_choice"):
		return result
	result.append({"id": "void_dice", "name": "공허 주사위", "description": "공허의 기억으로 추가된 특수 주사위 후보", "cost": 130, "type": "special_dice", "risk": "높은 비용 · 빌드 방향을 크게 바꿀 수 있습니다."})
	return result

static func get_affordable_items(run_state: RunStateManager) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if run_state == null: return result
	for item in get_inventory_for_run(run_state):
		var item_id: String = str(item.get("id", ""))
		if run_state.purchased_items.has(item_id): continue
		if run_state.gold >= int(item.get("cost", 0)): result.append(item.duplicate(true))
	return result

static func purchase(run_state: RunStateManager, item_id: String) -> Dictionary:
	var item: Dictionary = get_item(item_id)
	if item.is_empty() and item_id == "void_dice" and run_state != null and run_state.has_legacy_effect("special_shop_choice"):
		item = get_inventory_for_run(run_state)[-1]
	if item.is_empty(): return {"success": false, "message": "존재하지 않는 상품입니다."}
	if run_state.purchased_items.has(item_id): return {"success": false, "message": "이미 구매한 아이템입니다."}
	if not run_state.spend_gold(int(item.get("cost", 0))): return {"success": false, "message": "골드가 부족합니다."}
	if not _apply_item(run_state, item_id):
		run_state.add_gold(int(item.get("cost", 0)))
		return {"success": false, "message": "현재 상태에서는 구매할 수 없습니다."}
	run_state.purchased_items.append(item_id)
	return {"success": true, "item": item.duplicate(true), "cost": int(item.get("cost", 0))}

static func _apply_item(run_state: RunStateManager, item_id: String) -> bool:
	if item_id == "dice_reroll":
		var new_faces: Array[int] = _get_shop_die(run_state)
		var replace_index: int = _find_weakest_die(run_state)
		return replace_index >= 0 and run_state.replace_die(replace_index, new_faces)
	if item_id == "void_dice":
		var new_faces: Array[int] = [5, 5, 6, 6, 1, 3]
		if run_state.run_dice_faces.is_empty(): return false
		return run_state.replace_die(_find_weakest_die(run_state), new_faces)
	if RoguelikeEquipmentSystem.get_gear(item_id).is_empty(): return false
	return true

static func _get_shop_die(run_state: RunStateManager) -> Array[int]:
	if not run_state.special_dice_collection.is_empty():
		var special: Dictionary = run_state.special_dice_collection[0]
		var faces: Array[int] = []
		for face in special.get("faces", []): faces.append(int(face))
		if faces.size() == RunStateManager.DICE_FACE_COUNT: return faces
	return _roll_shop_die()

static func _roll_shop_die() -> Array[int]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var pool: Array[int] = [1, 1, 2, 3, 4, 5, 6]
	var faces: Array[int] = []
	for _i in RunStateManager.DICE_FACE_COUNT: faces.append(pool[rng.randi_range(0, pool.size() - 1)])
	return faces

static func _find_weakest_die(run_state: RunStateManager) -> int:
	if run_state.run_dice_faces.is_empty(): return -1
	var weakest_index: int = 0
	var weakest_score: int = 999999
	for die_index in run_state.run_dice_faces.size():
		var score: int = _die_score(run_state.run_dice_faces[die_index])
		if score < weakest_score:
			weakest_score = score
			weakest_index = die_index
	return weakest_index

static func _die_score(faces: Array) -> int:
	var score: int = 0
	for face in faces:
		var symbol: int = int(face)
		if symbol >= 100: score += 3
		elif symbol <= 4: score += 2
		else: score += 1
	return score
