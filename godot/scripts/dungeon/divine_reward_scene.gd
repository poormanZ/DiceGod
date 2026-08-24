class_name DungeonDivineRewardScene
extends DivineRewardUI

func _ready() -> void:
	RunStatusOverlay.attach(self)
	var boss_id: String = RunState.current_boss_id
	if boss_id.is_empty():
		boss_id = "battle_god"
	setup(RunState, boss_id)
	completed.connect(_finish_reward)

func _finish_reward() -> void:
	var reward: Dictionary = BossRewardSystem.grant(RunState, boss_id)
	RunState.boss_reward_claimed = bool(reward.get("success", false))
	RunState.boss_cleared = true

	# 보스 보상 확정 전에 다음 런에서도 유지해야 할 진행 상태를 보존한다.
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

	# 새 런을 생성하되, 런 간 유지 대상은 복원한다.
	# 주사위는 ProgressionState의 영구 저장본을 start_new_run()에서 자동 복원한다.
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
