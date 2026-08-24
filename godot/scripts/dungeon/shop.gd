class_name DungeonShop
extends Control

@onready var gold_label: Label = $MarginContainer/Content/GoldLabel
@onready var status_label: Label = $MarginContainer/Content/StatusLabel
@onready var attack_button: Button = $MarginContainer/Content/ShopChoices/AttackButton
@onready var dice_button: Button = $MarginContainer/Content/ShopChoices/DiceButton
@onready var charm_button: Button = $MarginContainer/Content/ShopChoices/CharmButton

var resolved: bool = false
const ATTACK_COST: int = 50
const DICE_COST: int = 75
const CHARM_COST: int = 40

func _ready() -> void:
	_update_ui()
	status_label.text = "상점에서 런을 강화할 아이템 하나를 선택하세요."

func _update_ui() -> void:
	gold_label.text = "보유 골드: %d" % RunState.gold
	attack_button.text = "⚔ 공격력 강화\n+3 공격력 / %dG" % ATTACK_COST
	dice_button.text = "🎲 주사위 강화\n+1 주사위 보너스 / %dG" % DICE_COST
	charm_button.text = "🍀 행운의 부적\n+2 공격력 / %dG" % CHARM_COST
	attack_button.disabled = resolved or RunState.gold < ATTACK_COST
	dice_button.disabled = resolved or RunState.gold < DICE_COST
	charm_button.disabled = resolved or RunState.gold < CHARM_COST

func _buy(item_id: String, cost: int, item_text: String, attack_bonus: int, dice_bonus: int) -> void:
	if resolved or RunState.gold < cost:
		status_label.text = "골드가 부족합니다." if RunState.gold < cost else "이미 구매했습니다."
		return
	RunState.add_gold(-cost)
	RunState.attack_bonus += attack_bonus
	RunState.unlocked_dice_bonus += dice_bonus
	RunState.shop_resolved = true
	RunState.shop_item_id = item_id
	resolved = true
	_update_ui()
	status_label.text = "%s 구매 완료!\n%s" % [item_text, RunState.get_run_summary()]
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_attack_button_pressed() -> void:
	_buy("attack", ATTACK_COST, "공격력 강화", 3, 0)

func _on_dice_button_pressed() -> void:
	_buy("dice", DICE_COST, "주사위 강화", 0, 1)

func _on_charm_button_pressed() -> void:
	_buy("charm", CHARM_COST, "행운의 부적", 2, 0)
