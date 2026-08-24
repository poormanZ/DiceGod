class_name DungeonShop
extends Control

@onready var gold_label: Label = $MarginContainer/Content/GoldLabel
@onready var status_label: Label = $MarginContainer/Content/StatusLabel
@onready var attack_button: Button = $MarginContainer/Content/ShopChoices/AttackButton
@onready var dice_button: Button = $MarginContainer/Content/ShopChoices/DiceButton
@onready var charm_button: Button = $MarginContainer/Content/ShopChoices/CharmButton

var resolved: bool = false

func _ready() -> void:
	_update_ui()
	status_label.text = "상점에서 런을 강화할 상품 하나를 선택하세요."

func _update_ui() -> void:
	gold_label.text = "보유 골드: %dG" % RunState.gold
	attack_button.text = "⚔ 전투 장갑\n공격력 +3 / 120G"
	dice_button.text = "🎲 주사위 교체\n새 주사위로 1개 교체 / 80G"
	charm_button.text = "🍀 행운의 동전\n전투 골드 보상 강화 / 140G"
	attack_button.disabled = resolved or RunState.gold < 120
	dice_button.disabled = resolved or RunState.gold < 80
	charm_button.disabled = resolved or RunState.gold < 140

func _buy(item_id: String) -> void:
	if resolved:
		return
	var result: Dictionary = RoguelikeShopSystem.purchase(RunState, item_id)
	if not bool(result.get("success", false)):
		status_label.text = str(result.get("message", "구매할 수 없습니다."))
		return
	resolved = true
	RunState.shop_resolved = true
	RunState.shop_item_id = item_id
	_update_ui()
	status_label.text = "%s 구매 완료!\n%s" % [str(result.get("item", {}).get("name", "상품")), RunState.get_run_summary()]
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")

func _on_attack_button_pressed() -> void:
	_buy("war_glove")

func _on_dice_button_pressed() -> void:
	_buy("dice_reroll")

func _on_charm_button_pressed() -> void:
	_buy("lucky_coin")
