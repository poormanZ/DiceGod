class_name RunStateManager
extends Node

const STARTING_GOLD: int = 100
const STARTING_HP: int = 100
const MAX_HP: int = 100

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

func start_new_run() -> void:
	active_run = true
	run_number += 1
	gold = STARTING_GOLD
	current_hp = STARTING_HP
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
	ProgressionState.record_run_start()

func end_run() -> void:
	active_run = false
	ProgressionState.record_run_loss()

func complete_run() -> void:
	ProgressionState.record_run_win()

func heal(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + maxi(0, amount))

func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - maxi(0, amount))

func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)

func get_run_summary() -> String:
	return "런 #%d | 골드 %d | HP %d/%d | 주사위 +%d | 공격력 +%d" % [run_number, gold, current_hp, max_hp, unlocked_dice_bonus, attack_bonus]
