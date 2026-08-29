extends SceneTree

## 현재 DiceGod 기준의 최소 실행 검증입니다.
## 구형 빌드/장비/특수 주사위 시스템을 직접 참조하지 않습니다.

func _init() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var root: Node = get_root()
	var run_state: RunStateManager = root.get_node_or_null("RunState") as RunStateManager
	if run_state == null:
		_fail("RunState autoload is missing")
		return

	_assert(RunStateManager.STARTING_DICE_COUNT == 6, "run uses six dice")
	_assert(RunStateManager.DICE_FACE_COUNT == 6, "dice has six faces")

	run_state.start_new_run()
	var dice_data_script: GDScript = load("res://scripts/dice/dice_data.gd") as GDScript
	_assert(dice_data_script != null, "DiceData script loads")
	var dice_data: Resource = dice_data_script.new() as Resource
	_assert(dice_data != null, "DiceData resource can be instantiated")

	run_state.initialize_run_dice(PackedInt32Array([1, 2, 3, 4, 5, 6]))
	_assert(run_state.run_dice_faces.size() == RunStateManager.STARTING_DICE_COUNT, "run starts with six dice")
	for faces: Array in run_state.run_dice_faces:
		_assert(faces.size() == RunStateManager.DICE_FACE_COUNT, "every die has six faces")

	_assert(not run_state.is_alive() or run_state.current_hp > 0, "run state is valid")
	_validate_symbol_synergies()
	_validate_balance_profiles()
	_validate_boss_patterns()
	print("DiceGod roadmap validation: PASS")
	quit(0)

func _validate_symbol_synergies() -> void:
	var base: Dictionary = SymbolSkillSystem.evaluate_counts({1:2, 5:2}, [])
	_assert(base.get("synergies", []).is_empty(), "synergy requires matching gear")
	_assert(int(base.get("attack", 0)) == 2, "base attack is preserved without gear")

	var sword: Dictionary = SymbolSkillSystem.evaluate_counts({1:2}, ["sword"])
	_assert(int(sword.get("attack", 0)) == 4, "sword pair adds +2 attack")
	_assert(sword.get("synergies", []).size() == 1, "sword pair activates once")

	var mixed: Dictionary = SymbolSkillSystem.evaluate_counts({1:2, 5:1}, ["sword"])
	_assert(int(mixed.get("attack", 0)) == 6, "mixed sword synergy adds attack")
	_assert(int(mixed.get("block", 0)) == 1, "base shield block is preserved")

	var trinity: Dictionary = SymbolSkillSystem.evaluate_counts({1:3}, ["sword"])
	_assert(int(trinity.get("attack", 0)) == 8, "sword trinity stacks with sword pair")
	_assert(int(trinity.get("hits", 0)) == 1, "sword trinity adds one hit")

	var capped: Dictionary = SymbolSkillSystem.evaluate_counts({1:3, 2:3}, ["sword", "bow"])
	var synergies: Array = capped.get("synergies", [])
	var triple_count: int = 0
	for synergy: Dictionary in synergies:
		if int(synergy.get("tier", 0)) == 3: triple_count += 1
	_assert(triple_count == 2, "triple synergies are capped at two")

func _validate_balance_profiles() -> void:
	var profiles: Dictionary = DiceGodBalanceModel.evaluate_synergy_profiles()
	_assert(profiles.size() >= 6, "balance profiles are available")
	for profile_name: String in profiles.keys():
		var profile: Dictionary = profiles[profile_name]
		_assert(int(profile.get("attack", -1)) >= 0, "%s attack metric is valid" % profile_name)
		_assert(int(profile.get("block", -1)) >= 0, "%s block metric is valid" % profile_name)
		_assert(int(profile.get("heal", -1)) >= 0, "%s heal metric is valid" % profile_name)

func _validate_boss_patterns() -> void:
	var boss_ids: Array = CombatContentSystem.BOSSES.keys()
	_assert(boss_ids.size() == 8, "all eight bosses are registered")
	for boss_id_variant: Variant in boss_ids:
		var boss_id: String = str(boss_id_variant)
		var patterns: Array = BossPatternSystem.get_patterns(boss_id)
		_assert(patterns.size() >= 2, "%s has at least two behavior patterns" % boss_id)
		var first: Dictionary = BossPatternSystem.preview(boss_id, 0)
		var second: Dictionary = BossPatternSystem.preview(boss_id, 1)
		_assert(not str(first.get("id", "")).is_empty(), "%s first pattern has id" % boss_id)
		_assert(not str(second.get("id", "")).is_empty(), "%s second pattern has id" % boss_id)
		_assert(not str(first.get("telegraph", "")).is_empty(), "%s first pattern has telegraph" % boss_id)
		_assert(not str(second.get("telegraph", "")).is_empty(), "%s second pattern has telegraph" % boss_id)
		var result: Dictionary = BossPatternSystem.execute(boss_id, 0, 50, 10)
		_assert(int(result.get("damage", -1)) >= 0, "%s pattern damage is valid" % boss_id)
		_assert(int(result.get("hp_damage", -1)) >= 0, "%s pattern HP damage is valid" % boss_id)
	_assert(BossPatternSystem.preview("flame_god", 0).get("status", "") == "burn", "flame applies burn")
	_assert(BossPatternSystem.preview("blood_god", 0).get("type", "") == "drain", "blood uses drain pattern")
	_assert(BossPatternSystem.preview("storm_god", 0).get("type", "") == "multi", "storm uses multi-hit pattern")
	_assert(BossPatternSystem.preview("void_god", 0).get("type", "") == "pierce", "void uses shield-piercing pattern")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	push_error("Roadmap validation failed: " + message)
	quit(1)
