class_name EnemyIntentDisplay
extends Label

@export var battle_path: NodePath = NodePath("../..")
var battle: Battle

func _ready() -> void:
	battle = get_node_or_null(battle_path) as Battle
	if battle == null:
		battle = get_tree().get_first_node_in_group("battle") as Battle
	update_intent()

func _process(_delta: float) -> void:
	update_intent()

func update_intent() -> void:
	if battle == null or battle.enemy == null:
		text = "다음 공격: 준비 중"
		return
	var damage := battle.enemy.get_attack_intent()
	if damage <= 0:
		text = "다음 공격: ⚔️ 0 피해"
	else:
		text = "⚠️ 다음 공격: ⚔️ %d 피해" % damage
