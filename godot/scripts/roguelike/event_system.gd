class_name RoguelikeEventSystem
extends RefCounted

## 던전 이벤트 풀. 각 이벤트는 서로 다른 리스크/보상 프로필을 가진다.
const EVENT_TYPES: Array[String] = ["camp", "shop", "forge", "gamble", "shrine", "mystery"]
const EVENT_COUNT: int = 2
const FORGE_COST: int = 35
const SHOP_DICE_COST: int = 80
const SHOP_GEAR_COST: int = 100
const SHRINE_HP_COST: int = 10
const SHRINE_GOLD_REWARD: int = 120
const MYSTERY_TRAP_DAMAGE: int = 10
const MYSTERY_SAFE_GOLD: int = 50
const MYSTERY_JACKPOT: int = 150

static func roll_event_options(rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array[String] = EVENT_TYPES.duplicate()
	pool.shuffle()
	var result: Array[String] = []
	for event_type: String in pool:
		if result.size() >= EVENT_COUNT: break
		result.append(event_type)
	return result

static func get_event_title(event_type: String) -> String:
	match event_type:
		"camp": return "캠프"
		"shop": return "상점"
		"forge": return "대장간"
		"gamble": return "도박장"
		"shrine": return "신전"
		"mystery": return "수수께끼"
	return "이벤트"

static func get_event_description(event_type: String) -> String:
	match event_type:
		"camp": return "안전하게 HP를 회복하지만 직접적인 빌드 성장은 없습니다."
		"shop": return "골드를 소비해 주사위 또는 장비를 얻습니다."
		"forge": return "35G를 소비해 원하는 주사위 면을 한 번 변경합니다."
		"gamble": return "골드를 걸어 성공 시 2~3배로 돌려받지만 실패하면 전액 잃습니다."
		"shrine": return "HP 10을 지불하고 120G를 얻습니다. HP가 낮다면 선택할 수 없습니다."
		"mystery": return "함정, 소액 보상, 대박 중 하나가 무작위로 결정됩니다."
	return "특수 이벤트"

static func get_event_risk(event_type: String) -> String:
	match event_type:
		"camp": return "위험 낮음 · 성장 보통"
		"shop": return "위험 낮음 · 골드 소비"
		"forge": return "위험 낮음 · 골드 소비"
		"gamble": return "위험 높음 · 골드 변동"
		"shrine": return "위험 중간 · HP 소비"
		"mystery": return "위험 높음 · 결과 불확실"
	return "위험도 미정"

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

static func shrine(run_state: RunStateManager) -> Dictionary:
	if run_state.current_hp <= SHRINE_HP_COST:
		return {"success": false, "gold": 0, "result": "HP가 부족합니다."}
	run_state.take_damage(SHRINE_HP_COST)
	run_state.add_gold(SHRINE_GOLD_REWARD)
	return {"success": true, "gold": SHRINE_GOLD_REWARD, "result": "HP 10을 바쳐 120G를 획득했습니다."}

static func mystery(run_state: RunStateManager, rng: RandomNumberGenerator) -> Dictionary:
	var roll: int = rng.randi_range(1, 6)
	if roll <= 2:
		run_state.take_damage(MYSTERY_TRAP_DAMAGE)
		return {"success": true, "gold": 0, "result": "함정! HP %d 손실" % MYSTERY_TRAP_DAMAGE, "roll": roll}
	if roll <= 4:
		run_state.add_gold(MYSTERY_SAFE_GOLD)
		return {"success": true, "gold": MYSTERY_SAFE_GOLD, "result": "평범한 보상: 50G", "roll": roll}
	run_state.add_gold(MYSTERY_JACKPOT)
	return {"success": true, "gold": MYSTERY_JACKPOT, "result": "대박! 150G 획득", "roll": roll}

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
