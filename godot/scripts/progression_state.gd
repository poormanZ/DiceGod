class_name ProgressionStateManager
extends Node

const SAVE_PATH := "user://dicegod_progression.json"
const CURRENT_VERSION := 6

var save_version: int = CURRENT_VERSION
var total_runs: int = 0
var total_wins: int = 0
var total_losses: int = 0
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
var pending_legacy_selection: Array[String] = []
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
	return _unlock(unlocked_dice, dice_id)
func unlock_ability(ability_id: String) -> bool:
	return _unlock(unlocked_abilities, ability_id)
func unlock_equipment(equipment_id: String) -> bool:
	return _unlock(unlocked_equipment, equipment_id)
func unlock_divine_symbol(symbol_id: String) -> bool:
	return _unlock(unlocked_divine_symbols, symbol_id)
func unlock_boss(boss_id: String) -> bool:
	return _unlock(unlocked_bosses, boss_id)
func unlock_special_dice(dice_id: String) -> bool:
	return _unlock(unlocked_special_dice, dice_id)
func unlock_event(event_id: String) -> bool:
	return _unlock(unlocked_events, event_id)
func unlock_forge_option(option_id: String) -> bool:
	return _unlock(unlocked_forge_options, option_id)
func unlock_legacy_option(legacy_id: String) -> bool:
	return _unlock(unlocked_legacy_options, legacy_id)

func _unlock(target: Array[String], value: String) -> bool:
	if target.has(value): return false
	target.append(value)
	save_progression()
	return true

func increase_legacy_slots(amount: int = 1) -> void:
	legacy_slots = maxi(0, legacy_slots + maxi(0, amount))
	save_progression()

func set_pending_legacy_selection(legacy_ids: Array[String]) -> bool:
	pending_legacy_selection.clear()
	for legacy_id: String in legacy_ids:
		if pending_legacy_selection.size() >= legacy_slots: break
		if unlocked_legacy_options.has(legacy_id) and not pending_legacy_selection.has(legacy_id):
			pending_legacy_selection.append(legacy_id)
	save_progression()
	return pending_legacy_selection.size() == legacy_ids.size()

func consume_pending_legacy_selection() -> Array[String]:
	var result: Array[String] = pending_legacy_selection.duplicate()
	pending_legacy_selection.clear()
	save_progression()
	return result

func is_dice_unlocked(dice_id: String) -> bool: return unlocked_dice.has(dice_id)
func is_ability_unlocked(ability_id: String) -> bool: return unlocked_abilities.has(ability_id)
func is_equipment_unlocked(equipment_id: String) -> bool: return unlocked_equipment.has(equipment_id)
func is_legacy_unlocked(legacy_id: String) -> bool: return unlocked_legacy_options.has(legacy_id)
func get_persistent_dice_faces() -> Array[Array]: return []
func save_persistent_dice_faces(_dice_faces: Array) -> void: return

func get_unlock_summary() -> String:
	return "영구 해금: 주사위 %d | 스킬 %d | 장비 %d | 신성 %d | 보스 %d | 이벤트 %d | 유산 %d" % [unlocked_dice.size(), unlocked_abilities.size(), unlocked_equipment.size(), unlocked_divine_symbols.size(), unlocked_bosses.size(), unlocked_events.size(), unlocked_legacy_options.size()]

func save_progression() -> void:
	var data := {"version": save_version, "total_runs": total_runs, "total_wins": total_wins, "total_losses": total_losses, "unlocked_dice": unlocked_dice, "unlocked_abilities": unlocked_abilities, "unlocked_equipment": unlocked_equipment, "unlocked_divine_symbols": unlocked_divine_symbols, "unlocked_bosses": unlocked_bosses, "unlocked_special_dice": unlocked_special_dice, "unlocked_events": unlocked_events, "unlocked_forge_options": unlocked_forge_options, "unlocked_legacy_options": unlocked_legacy_options, "legacy_slots": legacy_slots, "pending_legacy_selection": pending_legacy_selection, "meta_currency": meta_currency}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify(data))

func load_progression() -> void:
	if not FileAccess.file_exists(SAVE_PATH): save_progression(); return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary: return
	var data: Dictionary = parsed
	# 저장된 실제 버전을 그대로 읽어둡니다. (향후 버전별 마이그레이션 분기에 사용)
	save_version = maxi(1, int(data.get("version", 1)))
	total_runs = int(data.get("total_runs", 0)); total_wins = int(data.get("total_wins", 0)); total_losses = int(data.get("total_losses", 0))
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
	pending_legacy_selection = _load_string_array(data.get("pending_legacy_selection", []), [])
	meta_currency = maxi(0, int(data.get("meta_currency", 0)))
	# 마이그레이션 분기(향후 save_version 기준 처리)가 끝난 뒤, 다음 저장부터는 현재 스키마 버전을 기록합니다.
	save_version = CURRENT_VERSION

func _load_string_array(value: Variant, fallback: Array[String]) -> Array[String]:
	if not value is Array: return fallback.duplicate()
	var result: Array[String] = []
	for item in value: result.append(str(item))
	return result
