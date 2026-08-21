class_name BuildData
extends Resource

## 전투 시작 시 선택하는 작은 빌드 조합입니다.
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var dice_data: DiceData
@export var ability_data: AbilityData
@export var equipment_data: EquipmentData
@export var healing_dice_data: HealingDiceData
