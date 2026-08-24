class_name RunBattle
extends Battle

func _handle_victory() -> void:
	is_battle_over = true
	RunState.current_hp = player.current_hp
	RunState.battle_cleared = true
	RunState.reward_claimed = false
	_show_combat_feedback("🏆 일반 전투 승리! 골드 보상을 선택하세요.")
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reward.tscn")

func _handle_defeat() -> void:
	is_battle_over = true
	RunState.current_hp = 0
	RunState.die()
	_show_combat_feedback("💀 사망 — 주사위 하나를 계승할 수 있습니다.")
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/reincarnation.tscn")
