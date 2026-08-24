class_name BossRewardSystem
extends RefCounted

const REWARDS: Dictionary = {
	"gambling_god": {"gear": "gambling_god_coin", "die": "golden_die", "die_name": "황금 주사위", "faces": [101, 101, 1, 5, 6, 2]},
	"battle_god": {"gear": "battle_god_blade", "die": "critical_die", "die_name": "전투 주사위", "faces": [102, 102, 1, 1, 4, 5]},
	"wisdom_god": {"gear": "oracle_relic", "die": "oracle_die", "die_name": "예지 주사위", "faces": [103, 103, 2, 3, 5, 6]},
	"life_god": {"gear": "life_relic", "die": "life_die", "die_name": "생명 주사위", "faces": [104, 104, 6, 6, 5, 1]},
	"war_god": {"gear": "war_relic", "die": "berserk_die", "die_name": "광전 주사위", "faces": [105, 105, 1, 1, 4, 2]},
	"guardian_god": {"gear": "guardian_relic", "die": "sanctuary_die", "die_name": "성역 주사위", "faces": [106, 106, 5, 5, 6, 2]},
	"fate_god": {"gear": "fate_relic", "die": "fate_die", "die_name": "운명 주사위", "faces": [107, 107, 1, 2, 5, 6]},
	"death_god": {"gear": "death_relic", "die": "death_die", "die_name": "사신 주사위", "faces": [108, 108, 1, 1, 3, 4]}
}

static func boss_id_from_display_name(display_name: String) -> String:
	for boss_id in CombatContentSystem.BOSSES.keys():
		var boss: Dictionary = CombatContentSystem.BOSSES[boss_id]
		if str(boss.get("name", "")) == display_name:
			return str(boss_id)
	return ""

static func get_reward(boss_id: String) -> Dictionary:
	return REWARDS.get(boss_id, {})

static func get_special_die(die_id: String) -> Dictionary:
	for boss_id in REWARDS.keys():
		var reward: Dictionary = REWARDS[boss_id]
		if str(reward.get("die", "")) == die_id:
			return {"id": die_id, "name": reward.get("die_name", "특수 주사위"), "faces": reward.get("faces", []).duplicate(true), "boss_id": boss_id}
	return {}

static func sync_owned_special_dice(run_state: RunStateManager) -> void:
	for die_id in ProgressionState.unlocked_special_dice:
		var die: Dictionary = get_special_die(str(die_id))
		if die.is_empty():
			continue
		var found: bool = false
		for existing in run_state.special_dice_collection:
			if str(existing.get("id", "")) == str(die.get("id", "")):
				found = true
				break
		if not found:
			run_state.special_dice_collection.append(die)

static func grant(run_state: RunStateManager, boss_id: String) -> Dictionary:
	var reward: Dictionary = get_reward(boss_id)
	if reward.is_empty():
		return {"success": false, "message": "보스 보상 데이터가 없습니다."}
	var gear_id: String = str(reward.get("gear", ""))
	var gear_result: Dictionary = RoguelikeEquipmentSystem.equip(run_state, gear_id)
	var die_entry: Dictionary = {"id": str(reward.get("die", "")), "name": str(reward.get("die_name", "특수 주사위")), "faces": reward.get("faces", []).duplicate(true), "boss_id": boss_id}
	var found: bool = false
	for existing in run_state.special_dice_collection:
		if str(existing.get("id", "")) == die_entry["id"]:
			found = true
			break
	if not found:
		run_state.special_dice_collection.append(die_entry)
	ProgressionState.unlock_special_dice(str(die_entry["id"]))
	ProgressionState.unlock_equipment(gear_id)
	return {"success": true, "gear": gear_result.get("gear", {}), "die": die_entry}
