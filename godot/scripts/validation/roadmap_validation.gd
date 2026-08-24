extends SceneTree

func _initialize() -> void:
	var run_state: RunStateManager = RunStateManager.new()
	var flow: RunFlow = RunFlow.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345

	# Phase 3: six dice / six faces.
	run_state.start_new_run()
	run_state.initialize_run_dice(PackedInt32Array([1, 2, 3, 4, 5, 6]))
	_assert(run_state.run_dice_faces.size() == 6, "run starts with six dice")
	for faces: Array in run_state.run_dice_faces:
		_assert(faces.size() == 6, "every die has six faces")

	# Phase 5/9: forge and economy.
	var starting_gold: int = run_state.gold
	_assert(RoguelikeEventSystem.forge(run_state, 0, 0, 2), "forge changes one face")
	_assert(run_state.run_dice_faces[0][0] == 2, "forged face uses requested symbol")
	_assert(run_state.gold < starting_gold, "forge consumes gold")
	_assert(not RoguelikeEventSystem.forge(run_state, 0, 1, 3), "forge is limited to one use per run")

	# Phase 6/7: symbol skills and equipment data are loadable.
	var skill_result: Dictionary = SymbolSkillSystem.resolve([1, 1, 2, 5, 6, 6])
	_assert(not skill_result.is_empty(), "symbol skill system resolves a roll")
	var inventory: Array[Dictionary] = RoguelikeShopSystem.get_inventory()
	_assert(inventory.size() >= 4, "shop inventory is available")

	# Phase 9: full run state machine.
	flow.start(run_state)
	_assert(flow.state == RunFlow.NORMAL_BATTLE, "run starts in normal battle")
	flow.on_normal_battle_won(run_state, rng)
	_assert(flow.state == RunFlow.GOLD_REWARD, "normal battle leads to gold reward")
	flow.continue_after_reward(run_state)
	_assert(flow.state == RunFlow.EVENT_1, "gold reward leads to first event")
	run_state.choose_event("camp")
	run_state.resolve_event("camp_complete")
	flow.complete_event(run_state)
	_assert(flow.state == RunFlow.ELITE, "first event leads to elite")
	flow.on_elite_won(run_state, rng)
	_assert(flow.state == RunFlow.EVENT_2, "elite leads to second event")
	run_state.choose_event("shop")
	run_state.resolve_event("shop_complete")
	flow.complete_event(run_state)
	_assert(flow.state == RunFlow.BOSS, "second event leads to boss")

	# Phase 10: divine reward and two-face limit.
	flow.on_boss_won(run_state, "battle_god")
	_assert(flow.state == RunFlow.DIVINE_REWARD, "boss leads to divine reward")
	_assert(DivineRewardSystem.unlock_boss_symbol(run_state, "battle_god"), "boss unlocks divine symbol")
	var imprint_a: Dictionary = DivineRewardSystem.imprint(run_state, 0, 1, "battle_god")
	var imprint_b: Dictionary = DivineRewardSystem.imprint(run_state, 0, 2, "battle_god")
	_assert(bool(imprint_a.get("success", false)), "first divine imprint succeeds")
	_assert(bool(imprint_b.get("success", false)), "second divine imprint succeeds")
	_assert(not run_state.record_divine_imprint(0, 3, "critical"), "third divine face is rejected")

	# Phase 11: inheritance preserves six faces and metadata.
	run_state.prepare_inheritance(run_state.get_die_faces(0), "검증 주사위", 0)
	run_state.confirm_inheritance()
	_assert(run_state.inheritance_confirmed, "inheritance can be confirmed")
	_assert(run_state.inherited_die.get("faces", []).size() == 6, "inherited die preserves six faces")

	# Phase 12: balance model is callable.
	var balance: Dictionary = BalanceModel.simulate_rolls(1000, 6, 12345)
	_assert(not balance.is_empty(), "balance model returns simulation data")

	print("DiceGod roadmap validation: PASS")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("Roadmap validation failed: " + message)
		quit(1)
