class_name EnemyData
extends Resource

## 적의 변하지 않는 기본 정보입니다.
@export var display_name: String = "슬라임"
@export var max_hp: int = 10
@export var attack_dice: DiceData
@export var attack_bonus: int = 0

# 심볼 전투에서 사용하는 적 방어력과 상태이상 저항입니다.
@export var armor: int = 0
@export var status_resistance: int = 0

# 보스 전용 심볼. 일반/엘리트 적은 0을 사용합니다.
@export var boss_symbol_id: int = 0
@export var boss_symbol_effect: String = ""
@export var boss_symbol_power: int = 0
