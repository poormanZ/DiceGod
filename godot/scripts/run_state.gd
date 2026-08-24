class_name RunStateManager
extends Node

const STARTING_GOLD: int = 100
const STARTING_HP: int = 10
const MAX_HP: int = 10
const STARTING_DICE_COUNT: int = 6
const DICE_FACE_COUNT: int = 6
const MAX_DIVINE_FACES: int = 2

var active_run: bool = false
var run_number: int = 0
var gold: int = STARTING_GOLD
var current_hp: int = STARTING_HP
var max_hp: int = MAX_HP
var attack_bonus: int = 0
var selected_build_id: String = ""
var battle_cleared: bool = false
var reward_claimed: bool = false
var event_resolved: bool = false
var elite_cleared: bool = false
var boss_cleared: bool = false
var reward_id: String = ""
var event_id: String = ""
var event_stage: int = 0
var event_skipped: bool = false
var current_event_type: String = ""
var event_options: Array[String] = []
var run_dice_faces: Array[Array] = []
var special_dice_collection: Array[Dictionary] = []
var inherited_die: Dictionary = {}
var pending_inheritance_die: Dictionary = {}
var forge_used_this_run: bool = false
var forge_history: Array[Dictionary] = []
var face_upgrade_levels: Dictionary = {}
var divine_symbol_history: Array[Dictionary] = []
var unlocked_divine_symbols: Array[String] = []
var current_boss_id: String = ""
var boss_reward_claimed: bool = false
var death_pending: bool = false
var inheritance_confirmed: bool = false
var purchased_items: Array[String] = []
var equipped_items: Array[String] = []
var shop_resolved: bool = false
var shop_item_id: String = ""
var unlocked_dice_bonus: int = 0
var gamble_result: String = ""
var gamble_streak: int = 0
var permanent_runs: int = 0
var permanent_wins: int = 0
var permanent_deaths: int = 0
var unlocked_gods: Array[String] = []
var run_completed: bool = false

func start_new_run() -> void:
	active_run = true
	run_number += 1
	gold = STARTING_GOLD
	current_hp = MAX_HP
	max_hp = MAX_HP
	attack_bonus = 0
	selected_build_id = ""
	battle_cleared = false
	reward_claimed = false
	event_resolved = false
	elite_cleared = false
	boss_cleared = false
	run_completed = false
	reward_id = ""
	event_id = ""
	event_stage = 0
	event_skipped = false
	current_event_type = ""
	event_options.clear()
	run_dice_faces.clear()
	forge_used_this_run = false
	forge_history.clear()
	face_upgrade_levels.clear()
	divine_symbol_history.clear()
	pending_inheritance_die = inherited_die.duplicate(true)
	current_boss_id = ""
	boss_reward_claimed = false
	death_pending = false
	inheritance_confirmed = false
	purchased_items.clear()
	equipped_items.clear()
	shop_resolved = false
	shop_item_id = ""
	unlocked_dice_bonus = 0
	gamble_result = ""
	gamble_streak = 0
	permanent_runs += 1
	ProgressionState.record_run_start()

func initialize_run_dice(default_faces: PackedInt32Array) -> void:
	if run_dice_faces.size() == STARTING_DICE_COUNT:
		return
	var base_faces: Array[int] = []
	for face: int in default_faces:
		base_faces.append(face)
	while base_faces.size() < DICE_FACE_COUNT:
		base_faces.append(1)
	if base_faces.size() > DICE_FACE_COUNT:
		base_faces = base_faces.slice(0, DICE_FACE_COUNT)
	for _die_index: int in STARTING_DICE_COUNT:
		run_dice_faces.append(base_faces.duplicate())
	if not inherited_die.is_empty():
		var inherited_faces: Array = inherited_die.get("faces", [])
		if inherited_faces.size() == DICE_FACE_COUNT:
			run_dice_faces[0] = inherited_faces.duplicate(true)

func add_die(faces: Array) -> bool:
	if faces.size() != DICE_FACE_COUNT or run_dice_faces.size() >= STARTING_DICE_COUNT:
		return false
	run_dice_faces.append(faces.duplicate(true))
	return true

func replace_die(die_index: int, faces: Array) -> bool:
	if die_index < 0 or die_index >= run_dice_faces.size() or faces.size() != DICE_FACE_COUNT:
		return false
	run_dice_faces[die_index] = faces.duplicate(true)
	return true

func get_die_faces(die_index: int) -> Array:
	if die_index < 0 or die_index >= run_dice_faces.size():
		return []
	return run_dice_faces[die_index].duplicate(true)

func heal(amount: int) -> int:
	var requested: int = maxi(0, amount)
	var before: int = current_hp
	current_hp = mini(max_hp, current_hp + requested)
	return current_hp - before

func take_damage(amount: int) -> int:
	var damage: int = maxi(0, amount)
	var before: int = current_hp
	current_hp = maxi(0, current_hp - damage)
	if current_hp == 0:
		die()
	return before - current_hp

func is_alive() -> bool:
	return current_hp > 0

func forge_change_face(die_index: int, face_index: int, symbol_id: int, cost: int) -> bool:
	if forge_used_this_run or not can_forge():
		return false
	if die_index < 0 or die_index >= run_dice_faces.size() or face_index < 0 or face_index >= DICE_FACE_COUNT:
		return false
	if symbol_id < 1 or symbol_id > 6 or not spend_gold(cost):
		return false
	run_dice_faces[die_index][face_index] = symbol_id
	forge_used_this_run = true
	forge_history.append({"die_index": die_index, "face_index": face_index, "symbol_id": symbol_id, "cost": cost})
	return true

func can_forge() -> bool:
	return not forge_used_this_run and not run_dice_faces.is_empty()

func upgrade_die_face(die_index: int, face_index: int, cost: int) -> bool:
	if die_index < 0 or die_index >= run_dice_faces.size() or face_index < 0 or face_index >= DICE_FACE_COUNT:
		return false
	if not spend_gold(cost):
		return false
	var key: String = "%d:%d" % [die_index, face_index]
	face_upgrade_levels[key] = int(face_upgrade_levels.get(key, 0)) + 1
	forge_history.append({"die_index": die_index, "face_index": face_index, "upgrade": true, "level": face_upgrade_levels[key], "cost": cost})
	return true

func get_face_upgrade_level(die_index: int, face_index: int) -> int:
	return int(face_upgrade_levels.get("%d:%d" % [die_index, face_index], 0))

func unlock_divine_symbol(symbol_id: String) -> void:
	if symbol_id.is_empty():
		return
	if not unlocked_divine_symbols.has(symbol_id):
		unlocked_divine_symbols.append(symbol_id)
	if not unlocked_gods.has(symbol_id):
		unlocked_gods.append(symbol_id)

func _divine_face_value(symbol_id: String) -> int:
	match symbol_id:
		"gold": return 101
		"critical": return 102
		"foresight": return 103
		"life": return 104
		"berserk": return 105
		"sanctuary": return 106
		"fate": return 107
		"death": return 108
	return 0

func record_divine_imprint(die_index: int, face_index: int, symbol_id: String) -> bool:
	if not unlocked_divine_symbols.has(symbol_id):
		return false
	if die_index < 0 or die_index >= run_dice_faces.size() or face_index < 0 or face_index >= DICE_FACE_COUNT:
		return false
	for imprint: Dictionary in divine_symbol_history:
		if int(imprint.get("die_index", -1)) == die_index and int(imprint.get("face_index", -1)) == face_index:
			return false
	var current_count: int = 0
	for imprint: Dictionary in divine_symbol_history:
		if int(imprint.get("die_index", -1)) == die_index:
			current_count += 1
	if current_count >= MAX_DIVINE_FACES:
		return false
	var face_value: int = _divine_face_value(symbol_id)
	if face_value == 0:
		return false
	run_dice_faces[die_index][face_index] = face_value
	divine_symbol_history.append({"die_index": die_index, "face_index": face_index, "symbol_id": symbol_id})
	return true

func prepare_inheritance(die_faces: Array, die_name: String = "환생 주사위", selected_die_index: int = -1) -> void:
	if die_faces.size() != DICE_FACE_COUNT:
		return
	var selected_forge: Array[Dictionary] = []
	var selected_divine: Array[Dictionary] = []
	var selected_upgrades: Dictionary = {}
	for entry: Dictionary in forge_history:
		if selected_die_index < 0 or int(entry.get("die_index", -1)) == selected_die_index:
			selected_forge.append(entry.duplicate(true))
	for entry: Dictionary in divine_symbol_history:
		if selected_die_index < 0 or int(entry.get("die_index", -1)) == selected_die_index:
			selected_divine.append(entry.duplicate(true))
	if selected_die_index >= 0:
		var prefix: String = "%d:" % selected_die_index
		for key: Variant in face_upgrade_levels.keys():
			if str(key).begins_with(prefix):
				selected_upgrades[key] = face_upgrade_levels[key]
	else:
		selected_upgrades = face_upgrade_levels.duplicate(true)
	pending_inheritance_die = {"name": die_name, "faces": die_faces.duplicate(true), "forge_history": selected_forge, "divine_symbols": selected_divine, "face_upgrade_levels": selected_upgrades, "source_run": run_number}

func confirm_inheritance() -> void:
	if pending_inheritance_die.is_empty():
		return
	inherited_die = pending_inheritance_die.duplicate(true)
	pending_inheritance_die.clear()
	inheritance_confirmed = true

func clear_pending_inheritance() -> void:
	pending_inheritance_die.clear()
	inheritance_confirmed = false

func begin_event(stage: int) -> void:
	event_stage = clampi(stage, 1, 2)
	event_resolved = false
	event_skipped = false
	current_event_type = ""
	event_options.clear()

func set_event_options(options: Array[String]) -> void:
	event_options = options.duplicate()

func choose_event(event_type: String) -> void:
	if not event_options.is_empty() and not event_options.has(event_type):
		return
	current_event_type = event_type
	event_id = event_type
	event_resolved = false
	event_skipped = false

func resolve_event(result_id: String) -> void:
	event_resolved = true
	event_skipped = false
	event_id = result_id

func skip_event() -> void:
	event_resolved = true
	event_skipped = true
	event_id = "skip"
	current_event_type = "skip"

func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)

func spend_gold(amount: int) -> bool:
	var cost: int = maxi(0, amount)
	if gold < cost:
		return false
	gold -= cost
	return true

func record_victory() -> void:
	permanent_wins += 1

func record_death() -> void:
	permanent_deaths += 1
	death_pending = true

func die() -> void:
	if not active_run and death_pending:
		return
	record_death()
	active_run = false
	run_completed = false

func finish_run() -> void:
	active_run = false

func complete_run() -> bool:
	if run_completed:
		return false
	if not boss_cleared:
		return false
	run_completed = true
	active_run = false
	record_victory()
	return true

func get_run_summary() -> Dictionary:
	var dice_count: int = run_dice_faces.size()
	var divine_count: int = divine_symbol_history.size()
	return {
		"run_number": run_number,
		"gold": gold,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"selected_build_id": selected_build_id,
		"dice_count": dice_count,
		"divine_symbol_count": divine_count,
		"battle_cleared": battle_cleared,
		"elite_cleared": elite_cleared,
		"boss_cleared": boss_cleared,
		"current_boss_id": current_boss_id,
		"permanent_runs": permanent_runs,
		"permanent_wins": permanent_wins,
		"permanent_deaths": permanent_deaths,
		"inherited_die": inherited_die.duplicate(true)
	}
