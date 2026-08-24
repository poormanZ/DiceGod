class_name BossRunBattle
extends RunBattle

func _handle_victory() -> void:
	is_battle_over = true
	RunState.current_hp = player.current_hp
	var boss_id: String = BossRewardSystem.boss_id_from_display_name(enemy.enemy_data.display_name)
	if boss_id.is_empty():
		boss_id = "battle_god"
	RunState.current_boss_id = boss_id
	DivineRewardSystem.unlock_boss_symbol(RunState, boss_id)
	RunState.boss_cleared = false
	_show_combat_feedback("👑 %s 처치! 신성 심볼과 특수 보상을 선택하세요." % enemy.enemy_data.display_name)
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/divine_reward.tscn")

func _handle_defeat() -> void:
	is_battle_over = true
	RunState.current_hp = 0
	RunState.die()
	_show_combat_feedback("💀 보스에게 패배했습니다. 주사위 하나를 계승하세요.")
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reincarnation.tscn")
