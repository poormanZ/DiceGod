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
	RunState.complete_run()
	await get_tree().create_timer(0.6).timeout
	# 보스 처치로 현재 런이 끝났으므로 즉시 새로운 런을 생성한다.
	# ProgressionState에 저장된 주사위 각인은 start_new_run()에서 복원된다.
	RunState.start_new_run()
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
