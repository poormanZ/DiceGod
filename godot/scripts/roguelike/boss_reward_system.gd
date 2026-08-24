class_name BossRewardSystem
extends RefCounted

## 보스 ID와 보스 보상의 단일 매핑입니다.
const REWARDS: Dictionary = {
	"flame_god": {"gear": "flame_relic", "die": "flame_die", "die_name": "화염 주사위", "faces": [101, 101, 1, 1, 4, 5]},
	"frost_god": {"gear": "frost_relic", "die": "frost_die", "die_name": "빙결 주사위", "faces": [102, 102, 2, 2, 5, 6]},
	"plague_god": {"gear": "plague_relic", "die": "plague_die", "die_name": "역병 주사위", "faces": [103, 103, 1, 3, 5, 6]},
	"blood_god": {"gear": "blood_relic", "die": "blood_die", "die_name": "혈액 주사위", "faces": [104, 104, 2, 4, 5, 6]},
	"storm_god": {"gear": "storm_relic", "die": "storm_die", "die_name": "폭풍 주사위", "faces": [105, 105, 1, 1, 4, 6]},
	"stone_god": {"gear": "stone_relic", "die": "stone_die", "die_name": "거암 주사위", "faces": [106, 106, 2, 3, 5, 5]},
	"fate_god": {"gear": "fate_relic", "die": "fate_die", "die_name": "운명 주사위", "faces": [107, 107, 1, 2, 5, 6]},
	"void_god": {"gear": "void_relic", "die": "void_die", "die_name": "공허 주사위", "faces": [108, 108, 1, 1, 3, 4]}
}

const LEGACY_ALIASES: Dictionary = {
	"gambling_god": "flame_god",
	"battle_god": "storm_god",
	"wisdom_god": "fate_god",
	"life_god": "blood_god",
	"war_god": "storm_god",
	"guardian_god": "stone_god",
	"death_god": "void_god"
}

static func normalize_boss_id(boss_id: String) -> String:
	var normalized: String = boss_id.strip_edges()
	if REWARDS.has(normalized):
		return normalized
	if LEGACY_ALIASES.has(normalized):
		return str(LEGACY_ALIASES[normalized])
	return ""

static func boss_id_from_display_name(display_name: String) -> String:
	for boss_id in CombatContentSystem.BOSSES.keys():
		var boss: Dictionary = CombatContentSystem.BOSSES[boss_id]
		if str(boss.get("name", "")) == display_name:
			return normalize_boss_id(str(boss_id))
	return ""

static func get_reward(boss_id: String) -> Dictionary:
	var normalized: String = normalize_boss_id(boss_id)
	if normalized.is_empty():
		return {}
	return REWARDS.get(normalized, {})

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
	var normalized: String = normalize_boss_id(boss_id)
	var reward: Dictionary = get_reward(normalized)
	if reward.is_empty():
		return {"success": false, "message": "보스 보상 데이터가 없습니다: %s" % boss_id}

	run_state.current_boss_id = normalized
	var gear_id: String = str(reward.get("gear", ""))
	var gear_result: Dictionary = RoguelikeEquipmentSystem.equip(run_state, gear_id)
	var die_entry: Dictionary = {
		"id": str(reward.get("die", "")),
		"name": str(reward.get("die_name", "특수 주사위")),
		"faces": reward.get("faces", []).duplicate(true),
		"boss_id": normalized
	}
	var found: bool = false
	for existing in run_state.special_dice_collection:
		if str(existing.get("id", "")) == die_entry["id"]:
			found = true
			break
	if not found:
		run_state.special_dice_collection.append(die_entry)
	ProgressionState.unlock_special_dice(str(die_entry["id"]))
	ProgressionState.unlock_equipment(gear_id)
	return {"success": true, "boss_id": normalized, "gear": gear_result.get("gear", {}), "die": die_entry}
