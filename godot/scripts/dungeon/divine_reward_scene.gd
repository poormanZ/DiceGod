class_name DungeonDivineRewardScene
extends DivineRewardUI

func _ready() -> void:
	RunStatusOverlay.attach(self)
	# 이전 버전에서 생성된 런이 주사위 목록을 잃은 경우에도
	# 보스 각인 화면에 진입하기 전에 기본 주사위 6개를 복구합니다.
	if RunState.active_run and RunState.run_dice_faces.is_empty():
		RunState.initialize_run_dice(PackedInt32Array([1, 2, 3, 4, 5, 6]))
	boss_id = BossRewardSystem.normalize_boss_id(str(RunState.current_boss_id))
	if boss_id.is_empty():
		# 구버전 세이브에서 ID가 없거나 잘못 저장된 경우에도
		# 현재 보스 목록의 첫 번째 유효 보상으로 안전하게 복구합니다.
		boss_id = "flame_god"
	RunState.current_boss_id = boss_id
	setup(RunState, boss_id)
	completed.connect(_finish_reward)

func _finish_reward() -> void:
	var reward: Dictionary = BossRewardSystem.grant(RunState, boss_id)
	RunState.boss_reward_claimed = bool(reward.get("success", false))
	RunState.boss_cleared = true

	if not bool(reward.get("success", false)):
		return

	# 보스 보상 확정 전에 다음 런에서도 유지해야 할 진행 상태를 보존합니다.
	var saved_gold: int = RunState.gold
	var saved_hp: int = RunState.current_hp
	var saved_max_hp: int = RunState.max_hp
	var saved_attack_bonus: int = RunState.attack_bonus
	var saved_equipment: Array[String] = RunState.equipped_items.duplicate()
	var saved_purchased_items: Array[String] = RunState.purchased_items.duplicate()
	var saved_dice_bonus: int = RunState.unlocked_dice_bonus
	var saved_special_dice: Array[Dictionary] = RunState.special_dice_collection.duplicate(true)

	RunState.complete_run()
	await get_tree().create_timer(0.6).timeout

	# 새 런을 생성하되 런 간 영구 성장 데이터는 복원합니다.
	RunState.start_new_run()
	RunState.gold = saved_gold
	RunState.current_hp = clampi(saved_hp, 0, saved_max_hp)
	RunState.max_hp = saved_max_hp
	RunState.attack_bonus = saved_attack_bonus
	RunState.equipped_items = saved_equipment
	RunState.purchased_items = saved_purchased_items
	RunState.unlocked_dice_bonus = saved_dice_bonus
	RunState.special_dice_collection = saved_special_dice
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
