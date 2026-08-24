class_name RoguelikeShopSystem
extends RefCounted

const ITEMS: Array[Dictionary] = [
	{"id": "dice_reroll", "name": "주사위", "description": "새로운 주사위 1개 획득", "cost": 80},
	{"id": "iron_armor", "name": "철갑 장비", "description": "최대 HP +15", "cost": 100},
	{"id": "war_glove", "name": "전투 장갑", "description": "공격력 +3", "cost": 120},
	{"id": "lucky_coin", "name": "행운의 동전", "description": "전투 골드 보상 +10", "cost": 140}
]

static func get_inventory() -> Array[Dictionary]:
	return ITEMS.duplicate(true)

static func purchase(run_state: RunStateManager, item_id: String) -> Dictionary:
	for item in ITEMS:
		if str(item.get("id", "")) != item_id:
			continue
		if run_state.purchased_items.has(item_id):
			return {"success": false, "message": "이미 구매한 아이템입니다."}
		if not run_state.spend_gold(int(item.get("cost", 0))):
			return {"success": false, "message": "골드가 부족합니다."}
		_apply_item(run_state, item_id)
		run_state.purchased_items.append(item_id)
		return {"success": true, "item": item}
	return {"success": false, "message": "존재하지 않는 상품입니다."}

static func _apply_item(run_state: RunStateManager, item_id: String) -> void:
	match item_id:
		"iron_armor":
			run_state.max_hp += 15
			run_state.current_hp += 15
		"war_glove":
			run_state.attack_bonus += 3
		"lucky_coin":
			run_state.reward_id = "lucky_coin"
		"dice_reroll":
			pass
