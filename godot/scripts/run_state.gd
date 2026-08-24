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
var inherited_die: Dictionary = {}
var pending_inheritance_die: Dictionary = {}
var forge_used_this_run: bool = false
var forge_history: Array[Dictionary] = []
var divine_symbol_history: Array[Dictionary] = []
var unlocked_divine_symbols: Array[String] = []
var current_boss_id: String = ""
var boss_reward_claimed: bool = false
var death_pending: bool = false
var inheritance_confirmed: bool = false
var purchased_items: Array[String] = []
var equipped_items: Array[String] = []
var gamble_result: String = ""
var gamble_streak: int = 0
var permanent_runs: int = 0
var permanent_wins: int = 0
var permanent_deaths: int = 0
var unlocked_gods: Array[String] = []

func start_new_run() -> void:
	active_run = true
	run_number += 1
	gold = STARTING_GOLD
	current_hp = MAX_HP
	max_hp = MAX_HP
	attack_bonus = 0
	battle_cleared = false
	reward_claimed = false
	event_resolved = false
	elite_cleared = false
	boss_cleared = false
	reward_id = ""
	event_id = ""
	event_stage = 0
	event_skipped = false
	current_event_type = ""
	event_options.clear()
	run_dice_faces.clear()
	forge_used_this_run = false
	forge_history.clear()
	divine_symbol_history.clear()
	pending_inheritance_die = inherited_die.duplicate(true)
	current_boss_id = ""
	boss_reward_claimed = false
	death_pending = false
	inheritance_confirmed = false
	purchased_items.clear()
	equipped_items.clear()
	gamble_result = ""
	gamble_streak = 0
	permanent_runs += 1
	ProgressionState.record_run_start()

func initialize_run_dice(default_faces: PackedInt32Array) -> void:
	if run_dice_faces.size() == STARTING_DICE_COUNT:
		return
	var base_faces: Array[int] = []
	for face in default_faces:
		base_faces.append(int(face))
	while base_faces.size() < DICE_FACE_COUNT:
		base_faces.append(1)
	if base_faces.size() > DICE_FACE_COUNT:
		base_faces = base_faces.slice(0, DICE_FACE_COUNT)
	for die_index in STARTING_DICE_COUNT:
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

func get_die_faces(die_index: int) -> Array:
	if die_index < 0 or die_index >= run_dice_faces.size():
		return []
	return run_dice_faces[die_index].duplicate(true)

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
	forge_history.append({"die_index": die_index, "face_index": face_index, "upgrade": true, "cost": cost})
	return true

func unlock_divine_symbol(symbol_id: String) -> void:
	if symbol_id.is_empty():
		return
	if not unlocked_divine_symbols.has(symbol_id):
		unlocked_divine_symbols.append(symbol_id)
	if not unlocked_gods.has(symbol_id):
		unlocked_gods.append(symbol_id)

func record_divine_imprint(die_index: int, face_index: int, symbol_id: String) -> bool:
	if not unlocked_divine_symbols.has(symbol_id):
		return false
	if die_index < 0 or die_index >= run_dice_faces.size() or face_index < 0 or face_index >= DICE_FACE_COUNT:
		return false
	for imprint in divine_symbol_history:
		if int(imprint.get("die_index", -1)) == die_index and int(imprint.get("face_index", -1)) == face_index:
			return false
	var current_count: int = 0
	for imprint in divine_symbol_history:
		if int(imprint.get("die_index", -1)) == die_index:
			current_count += 1
	if current_count >= MAX_DIVINE_FACES:
		return false
	run_dice_faces[die_index][face_index] = 100 + unlocked_divine_symbols.find(symbol_id) + 1
	divine_symbol_history.append({"die_index": die_index, "face_index": face_index, "symbol_id": symbol_id})
	return true

func prepare_inheritance(die_faces: Array, die_name: String = "환생 주사위") -> void:
	if die_faces.size() != DICE_FACE_COUNT:
		return
	pending_inheritance_die = {"name": die_name, "faces": die_faces.duplicate(true), "forge_history": forge_history.duplicate(true), "divine_symbols": divine_symbol_history.duplicate(true), "source_run": run_number}

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

func heal(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + maxi(0, amount))

func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - maxi(0, amount))
	if current_hp <= 0:
		die()

func die() -> void:
	current_hp = 0
	death_pending = true
	active_run = false
	permanent_deaths += 1
	ProgressionState.record_run_loss()

func complete_run() -> void:
	if not active_run:
		return
	active_run = false
	permanent_wins += 1
	ProgressionState.record_run_win()

func get_inherited_die_summary() -> String:
	if inherited_die.is_empty():
		return "환생 계승 주사위: 없음"
	return "%s | 6면 보존" % str(inherited_die.get("name", "환생 주사위"))

func get_run_summary() -> String:
	return "런 #%d | 골드 %d | HP %d/%d | 주사위 %d\n%s" % [run_number, gold, current_hp, max_hp, run_dice_faces.size(), get_inherited_die_summary()]
