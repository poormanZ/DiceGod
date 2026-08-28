class_name RoguelikeEquipmentSystem
extends RefCounted

const SLOTS: Array[String] = ["head", "body", "legs", "feet", "weapon", "neck", "ring"]
const GEAR: Dictionary = {
	"iron_armor": {"name":"철갑 장비", "description":"최대 HP +15", "slot":"body", "max_hp":15},
	"war_glove": {"name":"전투 장갑", "description":"공격력 +3", "slot":"weapon", "attack":3},
	"piercing_bow": {"name":"관통 활시위", "description":"활 시너지 활성화", "slot":"weapon", "synergy_tag":"bow"},
	"arcane_core": {"name":"비전 핵", "description":"지팡이 시너지 활성화", "slot":"neck", "synergy_tag":"staff"},
	"shadow_ring": {"name":"그림자 반지", "description":"표창 시너지 활성화", "slot":"ring", "synergy_tag":"shuriken"},
	"holy_charm": {"name":"성스러운 부적", "description":"힐 시너지 활성화", "slot":"neck", "synergy_tag":"heal"},
	"sword_relic": {"name":"강타의 인장", "description":"검 시너지 활성화", "slot":"weapon", "synergy_tag":"sword"},
	"shield_relic": {"name":"수호의 문장", "description":"방패 시너지 활성화", "slot":"body", "synergy_tag":"shield"},
	"gambling_god_coin": {"name":"도박신의 주화", "description":"골드 보상 +15", "slot":"ring", "gold":15},
	"battle_god_blade": {"name":"전투신의 검", "description":"치명타 강화", "slot":"weapon", "critical":1},
	"oracle_relic": {"name":"예지의 성배", "description":"리롤 전략 강화", "slot":"neck", "reroll":1},
	"life_relic": {"name":"생명의 성배", "description":"회복 효과 강화", "slot":"neck", "healing":2},
	"war_relic": {"name":"전쟁의 휘장", "description":"저HP 공격 강화", "slot":"head", "attack":2},
	"guardian_relic": {"name":"수호신의 방패", "description":"보호막 강화", "slot":"body", "block":2},
	"fate_relic": {"name":"운명의 실", "description":"심볼 변환 강화", "slot":"ring", "fate":1},
	"death_relic": {"name":"사신의 낫", "description":"마무리 피해 강화", "slot":"weapon", "execute":1}
}

static func get_gear(gear_id: String) -> Dictionary:
	return GEAR.get(gear_id, {})

static func get_slot(gear_id: String) -> String:
	return str(get_gear(gear_id).get("slot", ""))

static func is_owned(run_state: RunStateManager, gear_id: String) -> bool:
	return run_state.purchased_items.has(gear_id)

static func equip(run_state: RunStateManager, gear_id: String) -> Dictionary:
	var gear: Dictionary = get_gear(gear_id)
	if gear.is_empty(): return {"success":false,"message":"존재하지 않는 장비입니다."}
	if not is_owned(run_state, gear_id): return {"success":false,"message":"구매한 장비만 장착할 수 있습니다."}
	var slot: String = get_slot(gear_id)
	if not SLOTS.has(slot): return {"success":false,"message":"장비 부위가 없습니다."}
	var previous_id: String = str(run_state.equipped_by_slot.get(slot, ""))
	if previous_id == gear_id: return {"success":false,"message":"이미 장착 중입니다."}
	if not previous_id.is_empty():
		_unequip_stats(run_state, previous_id)
	run_state.equipped_by_slot[slot] = gear_id
	_sync_equipped_items(run_state)
	_apply_stats(run_state, gear_id)
	return {"success":true,"gear":gear,"replaced":previous_id}

static func unequip(run_state: RunStateManager, slot: String) -> Dictionary:
	var gear_id: String = str(run_state.equipped_by_slot.get(slot, ""))
	if gear_id.is_empty(): return {"success":false,"message":"해당 부위가 비어 있습니다."}
	_unequip_stats(run_state, gear_id)
	run_state.equipped_by_slot.erase(slot)
	_sync_equipped_items(run_state)
	return {"success":true,"gear_id":gear_id}

static func get_equipped(run_state: RunStateManager, slot: String) -> String:
	return str(run_state.equipped_by_slot.get(slot, ""))

static func has_tag(run_state: RunStateManager, tag: String) -> bool:
	for gear_id: String in run_state.equipped_by_slot.values():
		if str(get_gear(gear_id).get("synergy_tag", "")) == tag: return true
	return false

static func bonus(run_state: RunStateManager, key: String) -> int:
	var total: int = 0
	for gear_id: String in run_state.equipped_by_slot.values():
		total += int(get_gear(gear_id).get(key, 0))
	return total

static func _apply_stats(run_state: RunStateManager, gear_id: String) -> void:
	var gear: Dictionary = get_gear(gear_id)
	var hp_bonus: int = int(gear.get("max_hp", 0))
	if hp_bonus > 0:
		run_state.max_hp += hp_bonus
		run_state.current_hp = mini(run_state.max_hp, run_state.current_hp + hp_bonus)
	run_state.attack_bonus += int(gear.get("attack", 0))

static func _unequip_stats(run_state: RunStateManager, gear_id: String) -> void:
	var gear: Dictionary = get_gear(gear_id)
	var hp_bonus: int = int(gear.get("max_hp", 0))
	if hp_bonus > 0:
		run_state.max_hp = maxi(RunStateManager.MAX_HP, run_state.max_hp - hp_bonus)
		run_state.current_hp = mini(run_state.current_hp, run_state.max_hp)
	run_state.attack_bonus = maxi(0, run_state.attack_bonus - int(gear.get("attack", 0)))

static func _sync_equipped_items(run_state: RunStateManager) -> void:
	run_state.equipped_items.clear()
	for slot: String in SLOTS:
		var gear_id: String = str(run_state.equipped_by_slot.get(slot, ""))
		if not gear_id.is_empty(): run_state.equipped_items.append(gear_id)
