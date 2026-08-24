class_name RoguelikeEquipmentSystem
extends RefCounted

const GEAR: Dictionary = {
	"iron_armor": {"name": "철갑 장비", "description": "최대 HP +15", "max_hp": 15},
	"war_glove": {"name": "전투 장갑", "description": "공격력 +3", "attack": 3},
	"piercing_bow": {"name": "관통 활시위", "description": "활 관통 효과 강화", "tag": "bow", "penetration": 1},
	"arcane_core": {"name": "비전 핵", "description": "지팡이 상태이상 강화", "tag": "wand", "magic": 1},
	"shadow_ring": {"name": "그림자 반지", "description": "표창 연타 강화", "tag": "shuriken", "hits": 1},
	"holy_charm": {"name": "성스러운 부적", "description": "힐/보호막 강화", "tag": "heal", "healing": 1},
	"sword_relic": {"name": "강타의 인장", "description": "검 강타 강화", "tag": "sword", "heavy": 1},
	"shield_relic": {"name": "수호의 문장", "description": "방패 반격/보호 강화", "tag": "shield", "block": 1},
	"gambling_god_coin": {"name": "도박신의 주화", "description": "골드 보상 +15", "tag": "gold", "gold": 15},
	"battle_god_blade": {"name": "전투신의 검", "description": "크리티컬 피해 강화", "tag": "critical", "critical": 1},
	"oracle_relic": {"name": "예지의 성배", "description": "리롤/예측 전략 강화", "tag": "foresight", "reroll": 1},
	"life_relic": {"name": "생명의 성배", "description": "회복 효과 강화", "tag": "life", "healing": 2},
	"war_relic": {"name": "전쟁의 휘장", "description": "저HP 공격 강화", "tag": "berserk", "attack": 2},
	"guardian_relic": {"name": "수호신의 방패", "description": "보호막 강화", "tag": "sanctuary", "block": 2},
	"fate_relic": {"name": "운명의 실", "description": "전투당 심볼 변환 강화", "tag": "fate", "fate": 1},
	"death_relic": {"name": "사신의 낫", "description": "마무리 피해 강화", "tag": "death", "execute": 1}
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
	var hp_bonus: int = int(gear.get("max_hp", 0))
	run_state.max_hp += hp_bonus
	run_state.current_hp = mini(run_state.max_hp, run_state.current_hp + hp_bonus)
	run_state.attack_bonus += int(gear.get("attack", 0))
	return {"success": true, "gear": gear}

static func has_tag(run_state: RunStateManager, tag: String) -> bool:
	for gear_id in run_state.equipped_items:
		var gear: Dictionary = get_gear(gear_id)
		if str(gear.get("tag", "")) == tag:
			return true
	return false

static func bonus(run_state: RunStateManager, key: String) -> int:
	var total: int = 0
	for gear_id in run_state.equipped_items:
		total += int(get_gear(gear_id).get(key, 0))
	return total
