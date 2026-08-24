class_name DungeonDivineRewardScene
extends DivineRewardUI

func _ready() -> void:
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
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
