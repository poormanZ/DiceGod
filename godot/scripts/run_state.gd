class_name RunStateManager
extends Node

const STARTING_GOLD: int = 100
const STARTING_HP: int = 100
const MAX_HP: int = 100
const STARTING_DICE_COUNT: int = 6

var active_run: bool = false
var run_number: int = 0
var gold: int = STARTING_GOLD
var current_hp: int = STARTING_HP
var max_hp: int = MAX_HP
var selected_build_id: String = ""
var unlocked_dice_bonus: int = 0
var attack_bonus: int = 0
var battle_cleared: bool = false
var reward_claimed: bool = false
var event_resolved: bool = false
var shop_resolved: bool = false
var elite_cleared: bool = false
var boss_cleared: bool = false
var reward_id: String = ""
var event_id: String = ""
var shop_item_id: String = ""

# 로그라이크 진행 단계: 일반 전투 → 보상 → 이벤트 → 엘리트 → 이벤트 → 보스
var event_stage: int = 0
var event_skipped: bool = false
var inherited_die: Dictionary = {}
var pending_inheritance_die: Dictionary = {}

var forge_used_this_run: bool = false
var forge_history: Array[Dictionary] = []
var unlocked_divine_symbols: Array[String] = []
var divine_symbol_history: Array[Dictionary] = []

func start_new_run() -> void:
	active_run = true
	run_number += 1
	gold = STARTING_GOLD
	current_hp = MAX_HP
	max_hp = MAX_HP
	selected_build_id = ""
	unlocked_dice_bonus = 0
	attack_bonus = 0
	battle_cleared = false
	reward_claimed = false
	event_resolved = false
	shop_resolved = false
	elite_cleared = false
	boss_cleared = false
	reward_id = ""
	event_id = ""
	shop_item_id = ""
	event_stage = 0
	event_skipped = false
	forge_used_this_run = false
	forge_history.clear()
	pending_inheritance_die = inherited_die.duplicate(true)
	ProgressionState.record_run_start()

func end_run() -> void:
	if not active_run:
		return
	active_run = false
	ProgressionState.record_run_loss()

func complete_run() -> void:
	if not active_run:
		return
	active_run = false
	ProgressionState.record_run_win()

func heal(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + maxi(0, amount))

func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - maxi(0, amount))

func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)

func spend_gold(amount: int) -> bool:
	var cost: int = maxi(0, amount)
	if gold < cost:
		return false
	gold -= cost
	return true

func begin_event(stage: int) -> void:
	event_stage = clampi(stage, 1, 2)
	event_resolved = false
	event_skipped = false
	event_id = ""

func resolve_event(result_id: String) -> void:
	event_resolved = true
	event_skipped = false
	event_id = result_id

func skip_event() -> void:
	event_resolved = true
	event_skipped = true
	event_id = "skip"

func advance_after_event() -> void:
	if event_stage == 1:
		# 첫 이벤트 뒤에는 엘리트로 진행한다.
		return
	if event_stage == 2:
		# 두 번째 이벤트 뒤에는 보스로 진행한다.
		return

func record_forge_change(die_index: int, face_index: int, symbol_id: String, cost: int) -> bool:
	if forge_used_this_run:
		return false
	if die_index < 0 or die_index >= STARTING_DICE_COUNT:
		return false
	if face_index < 0 or face_index >= 6:
		return false
	if symbol_id.is_empty():
		return false
	if not spend_gold(cost):
		return false
	forge_used_this_run = true
	forge_history.append({
		"die_index": die_index,
		"face_index": face_index,
		"symbol_id": symbol_id,
		"cost": cost,
	})
	return true

func unlock_divine_symbol(symbol_id: String) -> void:
	if symbol_id.is_empty() or unlocked_divine_symbols.has(symbol_id):
		return
	unlocked_divine_symbols.append(symbol_id)

func record_divine_imprint(die_index: int, face_index: int, symbol_id: String) -> bool:
	if not unlocked_divine_symbols.has(symbol_id):
		return false
	if die_index < 0 or die_index >= STARTING_DICE_COUNT:
		return false
	if face_index < 0 or face_index >= 6:
		return false
	divine_symbol_history.append({
		"die_index": die_index,
		"face_index": face_index,
		"symbol_id": symbol_id,
	})
	return true

func prepare_inheritance(die_faces: Array, die_name: String = "환생 주사위") -> void:
	pending_inheritance_die = {
		"name": die_name,
		"faces": die_faces.duplicate(true),
		"source_run": run_number,
	}

func confirm_inheritance() -> void:
	inherited_die = pending_inheritance_die.duplicate(true)
	pending_inheritance_die.clear()

func clear_pending_inheritance() -> void:
	pending_inheritance_die.clear()

func get_inherited_die_summary() -> String:
	if inherited_die.is_empty():
		return "환생 계승 주사위: 없음"
	var name: String = str(inherited_die.get("name", "환생 주사위"))
	var faces: Array = inherited_die.get("faces", [])
	return "%s | 면 %d개" % [name, faces.size()]

func get_run_summary() -> String:
	return "런 #%d | 골드 %d | HP %d/%d | 주사위 +%d | 공격력 +%d\n%s" % [run_number, gold, current_hp, max_hp, unlocked_dice_bonus, attack_bonus, get_inherited_die_summary()]
