class_name DungeonShop
extends Control

@onready var gold_label: Label = $MarginContainer/Content/GoldLabel
@onready var status_label: Label = $MarginContainer/Content/StatusLabel
@onready var attack_button: Button = $MarginContainer/Content/ShopChoices/AttackButton
@onready var dice_button: Button = $MarginContainer/Content/ShopChoices/DiceButton
@onready var charm_button: Button = $MarginContainer/Content/ShopChoices/CharmButton

var resolved: bool = false
const STARTING_GOLD: int = 100

func _ready() -> void:
	if not get_tree().has_meta("dungeon_gold"):
		get_tree().set_meta("dungeon_gold", STARTING_GOLD)
	_update_ui()

func _update_ui() -> void:
	var gold: int = int(get_tree().get_meta("dungeon_gold", STARTING_GOLD))
	gold_label.text = "보유 골드: %d" % gold
	attack_button.disabled = resolved or gold < 50
	dice_button.disabled = resolved or gold < 75
	charm_button.disabled = resolved or gold < 40

func _buy(item_id: String, cost: int, item_text: String, attack_bonus: int) -> void:
	if resolved:
		return
	var gold: int = int(get_tree().get_meta("dungeon_gold", STARTING_GOLD))
	if gold < cost:
		status_label.text = "골드가 부족합니다."
		return
	gold -= cost
	get_tree().set_meta("dungeon_gold", gold)
	get_tree().set_meta("dungeon_shop_attack_bonus", attack_bonus)
	get_tree().set_meta("dungeon_shop_resolved", true)
	get_tree().set_meta("dungeon_shop_item_id", item_id)
	resolved = true
	attack_button.disabled = true
	dice_button.disabled = true
	charm_button.disabled = true
	status_label.text = "%s 구매 완료!" % item_text
	_update_ui()
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_attack_button_pressed() -> void:
	_buy("attack", 50, "공격력 강화", 3)

func _on_dice_button_pressed() -> void:
	_buy("dice", 75, "주사위 강화", 5)

func _on_charm_button_pressed() -> void:
	_buy("charm", 40, "행운의 부적", 2)
