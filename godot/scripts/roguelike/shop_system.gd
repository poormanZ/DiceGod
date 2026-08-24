class_name RoguelikeShopSystem
extends RefCounted

const ITEMS: Array[Dictionary] = [
	{"id": "dice_reroll", "name": "주사위", "description": "보유 주사위 1개를 새 주사위로 교체", "cost": 80},
	{"id": "iron_armor", "name": "철갑 장비", "description": "최대 HP +15", "cost": 100},
	{"id": "war_glove", "name": "전투 장갑", "description": "공격력 +3", "cost": 120},
	{"id": "lucky_coin", "name": "행운의 동전", "description": "전투 골드 보상 강화", "cost": 140}
]

static func get_inventory() -> Array[Dictionary]:
	return ITEMS.duplicate(true)

static func purchase(run_state: RunStateManager, item_id: String) -> Dictionary:
	for item in ITEMS:
		if str(item.get("id", "")) != item_id:
			continue
		if run_state.purchased_items.has(item_id):
			return {"success": false, "message": "이미 구매한 아이템입니다."}
		if item_id == "dice_reroll" and run_state.run_dice_faces.is_empty():
			return {"success": false, "message": "주사위가 준비되지 않았습니다."}
		if not run_state.spend_gold(int(item.get("cost", 0))):
			return {"success": false, "message": "골드가 부족합니다."}
		if not _apply_item(run_state, item_id):
			run_state.add_gold(int(item.get("cost", 0)))
			return {"success": false, "message": "현재 상태에서는 구매할 수 없습니다."}
		run_state.purchased_items.append(item_id)
		return {"success": true, "item": item}
	return {"success": false, "message": "존재하지 않는 상품입니다."}

static func _apply_item(run_state: RunStateManager, item_id: String) -> bool:
	match item_id:
		"iron_armor":
			run_state.max_hp += 15
			run_state.current_hp += 15
			return true
		"war_glove":
			run_state.attack_bonus += 3
			return true
		"lucky_coin":
			run_state.reward_id = "lucky_coin"
			return true
		"dice_reroll":
			var new_faces: Array[int] = _roll_shop_die()
			var replace_index: int = _find_weakest_die(run_state)
			return run_state.replace_die(replace_index, new_faces)
	return false

static func _roll_shop_die() -> Array[int]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var pool: Array[int] = [1, 1, 2, 3, 4, 5, 6]
	var faces: Array[int] = []
	for i in RunStateManager.DICE_FACE_COUNT:
		faces.append(pool[rng.randi_range(0, pool.size() - 1)])
	return faces

static func _find_weakest_die(run_state: RunStateManager) -> int:
	if run_state.run_dice_faces.is_empty():
		return -1
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
		if symbol >= 100:
			score += 3
		elif symbol == 1 or symbol == 2 or symbol == 3 or symbol == 4:
			score += 2
		else:
			score += 1
	return score
