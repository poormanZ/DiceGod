class_name RoguelikeEquipmentSystem
extends RefCounted

const GEAR: Dictionary = {
	"iron_armor": {"name": "철갑 장비", "description": "최대 HP +1", "max_hp": 1},
	"war_glove": {"name": "전투 장갑", "description": "공격력 +1", "attack": 1},
	"piercing_bow": {"name": "관통 활시위", "description": "활 관통 효과 강화", "tag": "bow"},
	"arcane_core": {"name": "비전 핵", "description": "지팡이 상태이상 강화", "tag": "wand"},
	"shadow_ring": {"name": "그림자 반지", "description": "표창 연타 강화", "tag": "shuriken"},
	"holy_charm": {"name": "성스러운 부적", "description": "힐/보호막 강화", "tag": "heal"},
	"battle_god_blade": {"name": "전투신의 검", "description": "크리티컬 피해 강화", "tag": "critical"},
	"gambling_god_coin": {"name": "도박신의 주화", "description": "골드 보상 +15", "tag": "gold"}
}

static func get_gear(gear_id: String) -> Dictionary:
	return GEAR.get(gear_id, {})

static func equip(run_state: RunStateManager, gear_id: String) -> Dictionary:
	var gear: Dictionary = get_gear(gear_id)
	if gear.is_empty():
		return {"success": false, "message": "존재하지 않는 장비입니다."}
	if run_state.equipped_items.has(gear_id):
		return {"success": false, "message": "이미 장착한 장비입니다."}
	run_state.equipped_items.append(gear_id)
	run_state.max_hp += int(gear.get("max_hp", 0))
	run_state.current_hp = mini(run_state.max_hp, run_state.current_hp + int(gear.get("max_hp", 0)))
	run_state.attack_bonus += int(gear.get("attack", 0))
	return {"success": true, "gear": gear}

static func has_tag(run_state: RunStateManager, tag: String) -> bool:
	for gear_id in run_state.equipped_items:
		var gear: Dictionary = get_gear(gear_id)
		if str(gear.get("tag", "")) == tag:
			return true
	return false
