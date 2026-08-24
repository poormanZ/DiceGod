class_name ProgressionStateManager
extends Node

const SAVE_PATH := "user://dicegod_progression.json"
const CURRENT_VERSION := 4

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
var persistent_dice_faces: Array[Array] = []

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

func unlock_dice(dice_id: String) -> bool:
	if unlocked_dice.has(dice_id):
		return false
	unlocked_dice.append(dice_id)
	if dice_id == "power_dice":
		unlock_ability("critical_force")
		unlock_equipment("war_amulet")
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

func is_dice_unlocked(dice_id: String) -> bool:
	return unlocked_dice.has(dice_id)

func is_ability_unlocked(ability_id: String) -> bool:
	return unlocked_abilities.has(ability_id)

func is_equipment_unlocked(equipment_id: String) -> bool:
	return unlocked_equipment.has(equipment_id)

func get_persistent_dice_faces() -> Array[Array]:
	var result: Array[Array] = []
	for die_faces: Array in persistent_dice_faces:
		result.append(die_faces.duplicate(true))
	return result

func save_persistent_dice_faces(dice_faces: Array) -> void:
	persistent_dice_faces.clear()
	for die_faces: Variant in dice_faces:
		if die_faces is Array and die_faces.size() > 0:
			persistent_dice_faces.append(die_faces.duplicate(true))
	save_progression()

func get_unlock_summary() -> String:
	return "영구 해금: 주사위 %d | 스킬 %d | 장비 %d | 신성 %d | 보스 %d" % [unlocked_dice.size(), unlocked_abilities.size(), unlocked_equipment.size(), unlocked_divine_symbols.size(), unlocked_bosses.size()]

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
		"persistent_dice_faces": persistent_dice_faces,
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
	persistent_dice_faces = _load_dice_faces(data.get("persistent_dice_faces", []))
	save_progression()

func _load_string_array(value: Variant, fallback: Array[String]) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	if result.is_empty():
		return fallback.duplicate()
	return result

func _load_dice_faces(value: Variant) -> Array[Array]:
	var result: Array[Array] = []
	if value is Array:
		for die_value: Variant in value:
			if die_value is Array and die_value.size() == 6:
				var faces: Array = []
				for face: Variant in die_value:
					faces.append(int(face))
				result.append(faces)
	return result
