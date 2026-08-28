class_name ProgressionStateManager
extends Node

const SAVE_PATH := "user://dicegod_progression.json"
const CURRENT_VERSION := 5

var save_version: int = CURRENT_VERSION
var total_runs: int = 0
var total_wins: int = 0
var total_losses: int = 0

# 메타 성장은 전투 수치가 아니라 선택지/콘텐츠를 확장한다.
var unlocked_dice: Array[String] = ["basic_dice", "healing_dice"]
var unlocked_abilities: Array[String] = ["matching_numbers"]
var unlocked_equipment: Array[String] = ["straight_equipment"]
var unlocked_divine_symbols: Array[String] = []
var unlocked_bosses: Array[String] = []
var unlocked_special_dice: Array[String] = []
var unlocked_events: Array[String] = []
var unlocked_forge_options: Array[String] = []
var unlocked_legacy_options: Array[String] = []
var legacy_slots: int = 0
var meta_currency: int = 0

func _ready() -> void:
	load_progression()

func record_run_start() -> void:
	total_runs += 1
	save_progression()

func record_run_loss() -> void:
	total_losses += 1
	save_progression()

func record_run_win() -> void:
	total_wins += 1
	save_progression()

func add_meta_currency(amount: int) -> void:
	meta_currency = maxi(0, meta_currency + amount)
	save_progression()

func unlock_dice(dice_id: String) -> bool:
	if unlocked_dice.has(dice_id):
		return false
	unlocked_dice.append(dice_id)
	save_progression()
	return true

func unlock_ability(ability_id: String) -> bool:
	if unlocked_abilities.has(ability_id):
		return false
	unlocked_abilities.append(ability_id)
	save_progression()
	return true

func unlock_equipment(equipment_id: String) -> bool:
	if unlocked_equipment.has(equipment_id):
		return false
	unlocked_equipment.append(equipment_id)
	save_progression()
	return true

func unlock_divine_symbol(symbol_id: String) -> bool:
	if unlocked_divine_symbols.has(symbol_id):
		return false
	unlocked_divine_symbols.append(symbol_id)
	save_progression()
	return true

func unlock_boss(boss_id: String) -> bool:
	if unlocked_bosses.has(boss_id):
		return false
	unlocked_bosses.append(boss_id)
	save_progression()
	return true

func unlock_special_dice(dice_id: String) -> bool:
	if unlocked_special_dice.has(dice_id):
		return false
	unlocked_special_dice.append(dice_id)
	save_progression()
	return true

func unlock_event(event_id: String) -> bool:
	if unlocked_events.has(event_id):
		return false
	unlocked_events.append(event_id)
	save_progression()
	return true

func unlock_forge_option(option_id: String) -> bool:
	if unlocked_forge_options.has(option_id):
		return false
	unlocked_forge_options.append(option_id)
	save_progression()
	return true

func unlock_legacy_option(legacy_id: String) -> bool:
	if unlocked_legacy_options.has(legacy_id):
		return false
	unlocked_legacy_options.append(legacy_id)
	save_progression()
	return true

func increase_legacy_slots(amount: int = 1) -> void:
	legacy_slots = maxi(0, legacy_slots + maxi(0, amount))
	save_progression()

func is_dice_unlocked(dice_id: String) -> bool:
	return unlocked_dice.has(dice_id)

func is_ability_unlocked(ability_id: String) -> bool:
	return unlocked_abilities.has(ability_id)

func is_equipment_unlocked(equipment_id: String) -> bool:
	return unlocked_equipment.has(equipment_id)

func is_legacy_unlocked(legacy_id: String) -> bool:
	return unlocked_legacy_options.has(legacy_id)

# 이전 영구 주사위 면 API는 의도적으로 비활성화한다.
# 완성된 런 주사위는 다음 런으로 전투력을 계승하지 않는다.
func get_persistent_dice_faces() -> Array[Array]:
	return []

func save_persistent_dice_faces(_dice_faces: Array) -> void:
	# 구버전 호출과의 호환성을 위해 함수는 유지하되 저장하지 않는다.
	return

func get_unlock_summary() -> String:
	return "영구 해금: 주사위 %d | 스킬 %d | 장비 %d | 신성 %d | 보스 %d | 이벤트 %d | 유산 %d" % [unlocked_dice.size(), unlocked_abilities.size(), unlocked_equipment.size(), unlocked_divine_symbols.size(), unlocked_bosses.size(), unlocked_events.size(), unlocked_legacy_options.size()]

func save_progression() -> void:
	var data := {
		"version": save_version,
		"total_runs": total_runs,
		"total_wins": total_wins,
		"total_losses": total_losses,
		"unlocked_dice": unlocked_dice,
		"unlocked_abilities": unlocked_abilities,
		"unlocked_equipment": unlocked_equipment,
		"unlocked_divine_symbols": unlocked_divine_symbols,
		"unlocked_bosses": unlocked_bosses,
		"unlocked_special_dice": unlocked_special_dice,
		"unlocked_events": unlocked_events,
		"unlocked_forge_options": unlocked_forge_options,
		"unlocked_legacy_options": unlocked_legacy_options,
		"legacy_slots": legacy_slots,
		"meta_currency": meta_currency,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))

func load_progression() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_progression()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	save_version = maxi(int(data.get("version", 1)), CURRENT_VERSION)
	total_runs = int(data.get("total_runs", 0))
	total_wins = int(data.get("total_wins", 0))
	total_losses = int(data.get("total_losses", 0))
	unlocked_dice = _load_string_array(data.get("unlocked_dice", unlocked_dice), unlocked_dice)
	unlocked_abilities = _load_string_array(data.get("unlocked_abilities", unlocked_abilities), unlocked_abilities)
	unlocked_equipment = _load_string_array(data.get("unlocked_equipment", unlocked_equipment), unlocked_equipment)
	unlocked_divine_symbols = _load_string_array(data.get("unlocked_divine_symbols", []), [])
	unlocked_bosses = _load_string_array(data.get("unlocked_bosses", []), [])
	unlocked_special_dice = _load_string_array(data.get("unlocked_special_dice", []), [])
	unlocked_events = _load_string_array(data.get("unlocked_events", []), [])
	unlocked_forge_options = _load_string_array(data.get("unlocked_forge_options", []), [])
	unlocked_legacy_options = _load_string_array(data.get("unlocked_legacy_options", []), [])
	legacy_slots = maxi(0, int(data.get("legacy_slots", 0)))
	meta_currency = maxi(0, int(data.get("meta_currency", 0)))
	save_progression()

func _load_string_array(value: Variant, fallback: Array[String]) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	if result.is_empty():
		return fallback.duplicate()
	return result
