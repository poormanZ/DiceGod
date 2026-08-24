class_name RoguelikeEventSystem
extends RefCounted

const EVENT_TYPES: Array[String] = ["camp", "shop", "forge", "gamble"]
const EVENT_COUNT: int = 2
const FORGE_COST: int = 35
const SHOP_DICE_COST: int = 80
const SHOP_GEAR_COST: int = 100

static func roll_event_options(rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array[String] = EVENT_TYPES.duplicate()
	pool.shuffle()
	return [pool[0], pool[1]]

static func roll_gold_reward(rng: RandomNumberGenerator) -> int:
	return [40, 60, 80][rng.randi_range(0, 2)]

static func camp_heal(run_state: RunStateManager) -> int:
	var before: int = run_state.current_hp
	run_state.heal(30)
	return run_state.current_hp - before

static func forge(run_state: RunStateManager, die_index: int, face_index: int, symbol_id: int) -> bool:
	return run_state.forge_change_face(die_index, face_index, symbol_id, FORGE_COST)

static func buy_dice(run_state: RunStateManager) -> bool:
	return run_state.spend_gold(SHOP_DICE_COST)

static func buy_gear(run_state: RunStateManager) -> bool:
	return run_state.spend_gold(SHOP_GEAR_COST)

static func gamble(run_state: RunStateManager, rng: RandomNumberGenerator, wager: int) -> Dictionary:
	if wager <= 0 or not run_state.spend_gold(wager):
		return {"success": false, "gold": 0, "result": "베팅 실패"}
	var roll: int = rng.randi_range(1, 6)
	if roll >= 5:
		var reward: int = wager * 3
		run_state.add_gold(reward)
		run_state.gamble_streak += 1
		return {"success": true, "gold": reward, "result": "대성공", "roll": roll}
	if roll >= 3:
		var reward_half: int = wager * 2
		run_state.add_gold(reward_half)
		run_state.gamble_streak = 0
		return {"success": true, "gold": reward_half, "result": "성공", "roll": roll}
	run_state.gamble_streak = 0
	return {"success": true, "gold": 0, "result": "실패", "roll": roll}
