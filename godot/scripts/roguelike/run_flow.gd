class_name RunFlow
extends RefCounted

signal state_changed(state: String)

const NORMAL_BATTLE := "normal_battle"
const GOLD_REWARD := "gold_reward"
const EVENT_1 := "event_1"
const ELITE := "elite"
const EVENT_2 := "event_2"
const BOSS := "boss"
const DIVINE_REWARD := "divine_reward"
const RUN_COMPLETE := "run_complete"
const DEATH := "death"
const REINCARNATION := "reincarnation"

var state: String = NORMAL_BATTLE
var gold_reward: int = 0

func start(run_state: RunStateManager) -> void:
	run_state.start_new_run()
	state = NORMAL_BATTLE
	state_changed.emit(state)

func on_normal_battle_won(run_state: RunStateManager, rng: RandomNumberGenerator) -> void:
	if state != NORMAL_BATTLE:
		return
	gold_reward = RoguelikeEventSystem.roll_gold_reward(rng)
	run_state.add_gold(gold_reward)
	run_state.battle_cleared = true
	run_state.reward_claimed = true
	state = GOLD_REWARD
	state_changed.emit(state)

func continue_after_reward(run_state: RunStateManager) -> void:
	if state != GOLD_REWARD or not run_state.battle_cleared:
		return
	state = EVENT_1
	run_state.begin_event(1)
	state_changed.emit(state)

func complete_event(run_state: RunStateManager) -> void:
	if state == EVENT_1:
		state = ELITE
	elif state == EVENT_2:
		state = BOSS
	else:
		return
	state_changed.emit(state)

func on_elite_won(run_state: RunStateManager, rng: RandomNumberGenerator) -> void:
	if state != ELITE:
		return
	var reward: int = 70 + rng.randi_range(0, 30)
	run_state.add_gold(reward)
	run_state.elite_cleared = true
	state = EVENT_2
	run_state.begin_event(2)
	state_changed.emit(state)

func enter_boss(run_state: RunStateManager) -> void:
	if state != EVENT_2 or not run_state.event_resolved:
		return
	state = BOSS
	state_changed.emit(state)

func on_boss_won(run_state: RunStateManager, boss_id: String) -> void:
	if state != BOSS:
		return
	run_state.boss_cleared = true
	run_state.current_boss_id = boss_id
	run_state.boss_reward_claimed = false
	state = DIVINE_REWARD
	state_changed.emit(state)

func on_divine_reward_done(run_state: RunStateManager) -> void:
	if state != DIVINE_REWARD:
		return
	run_state.boss_reward_claimed = true
	state = RUN_COMPLETE
	run_state.complete_run()
	state_changed.emit(state)

func on_player_died(run_state: RunStateManager) -> void:
	if run_state.current_hp > 0:
		return
	run_state.die()
	state = DEATH
	state_changed.emit(state)

func open_reincarnation(run_state: RunStateManager) -> void:
	if state != DEATH:
		return
	state = REINCARNATION
	state_changed.emit(state)

func finish_reincarnation(run_state: RunStateManager) -> void:
	if state != REINCARNATION or not run_state.inheritance_confirmed:
		return
	state = NORMAL_BATTLE
	run_state.start_new_run()
	state_changed.emit(state)
